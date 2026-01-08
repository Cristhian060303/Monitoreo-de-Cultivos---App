import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sensor_data.dart';
import '../models/ia_result.dart';
import '../models/detection.dart';
import '../models/system_state.dart';

class MqttService with ChangeNotifier {
  MqttServerClient? client;

  // ---------------- CONFIG MQTT ----------------
  String mqttHost = '0.0.0.0';
  int mqttPort = 0000;

  // ---------------- CAMERA CONFIG ----------------
  String cameraHost = '';

  // ---------------- CONNECTION STATE ----------------
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;

  // ---------------- DATA ----------------
  int cameraFrameId = 0;

  SystemState systemState = const SystemState(
    modo: '--',
    bomba: '--',
  );

  SensorData? sensorData;
  IAResult? iaResult;

  List<Detection> detections = [];
  int frameWidth = 320;
  int frameHeight = 240;

  // ---------------- LOAD CONFIG ----------------
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    mqttHost = prefs.getString('mqtt_host') ?? mqttHost;
    mqttPort = prefs.getInt('mqtt_port') ?? mqttPort;
  }

  // ---------------- SAVE CONFIG ----------------
  Future<void> saveConfig(String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_host', host);
    await prefs.setInt('mqtt_port', port);

    mqttHost = host;
    mqttPort = port;
  }

  Future<void> saveCameraHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('camera_host', host);
    cameraHost = host;
    notifyListeners();
  }

  // ---------------- CONNECT ----------------
  Future<void> connect() async {
    await loadConfig();

    // Limpia cualquier listener viejo
    await _updatesSub?.cancel();
    _updatesSub = null;

    // Si había un cliente previo, lo desconecta
    try {
      client?.disconnect();
    } catch (_) {}

    // Estado inicial: desconectado
    _setConnected(false);

    // Crear cliente nuevo
    final newClient = MqttServerClient(mqttHost, 'flutter_cultivo');
    newClient.port = mqttPort;
    newClient.keepAlivePeriod = 20;
    newClient.logging(on: true);

    newClient.onConnected = _onConnected;
    newClient.onDisconnected = _onDisconnected;

    newClient.connectionMessage =
        MqttConnectMessage().withClientIdentifier('flutter_cultivo').startClean();

    client = newClient;

    try {
      await newClient.connect();
    } catch (e) {
      debugPrint('❌ MQTT connect failed: $e');

      try {
        newClient.disconnect();
      } catch (_) {}
      client = null;

      _setConnected(false);
      return;
    }

    // Si conectó, suscribirse y escuchar mensajes
    _subscribeTopics();
    _listenUpdates();

    // Notifica UI
    notifyListeners();
  }

  void _subscribeTopics() {
    final c = client;
    if (c == null) return;

    c.subscribe('cultivo/sensores', MqttQos.atMostOnce);
    c.subscribe('cultivo/ia/resultado', MqttQos.atMostOnce);
    c.subscribe('cultivo/ia/confianza', MqttQos.atMostOnce);
    c.subscribe('cultivo/ia/detecciones', MqttQos.atMostOnce);
    c.subscribe('cultivo/estado/modo', MqttQos.atMostOnce);
    c.subscribe('cultivo/estado/bomba', MqttQos.atMostOnce);
  }

  void _listenUpdates() {
    final c = client;
    if (c == null) return;

    final updates = c.updates;
    if (updates == null) return;

    _updatesSub = updates.listen((events) {
      final rec = events.first;
      final topic = rec.topic;

      final pubMsg = rec.payload as MqttPublishMessage;
      final payloadRaw =
      MqttPublishPayload.bytesToStringAsString(pubMsg.payload.message);
      final payload = payloadRaw.trim();

      debugPrint('MQTT [$topic]: $payload');

      bool shouldNotify = false;

      if (topic == 'cultivo/sensores') {
        final json = jsonDecode(payload);
        sensorData = SensorData.fromJson(json);
        shouldNotify = true;
      }

      if (topic == 'cultivo/ia/resultado') {
        iaResult = IAResult(
          label: payload,
          confidence: iaResult?.confidence ?? 0,
        );
        shouldNotify = true;
      }

      if (topic == 'cultivo/ia/confianza') {
        iaResult = IAResult(
          label: iaResult?.label ?? '---',
          confidence: int.tryParse(payload) ?? 0,
        );
        shouldNotify = true;
      }

      if (topic == 'cultivo/ia/detecciones') {
        final json = jsonDecode(payload);

        frameWidth = json['frame_w'];
        frameHeight = json['frame_h'];

        detections = (json['boxes'] as List)
            .map((e) => Detection.fromJson(e))
            .toList();

        cameraFrameId++;
        shouldNotify = true;
      }

      if (topic == 'cultivo/estado/modo') {
        systemState = systemState.copyWith(modo: payload);
        shouldNotify = true;
      }

      if (topic == 'cultivo/estado/bomba') {
        systemState = systemState.copyWith(bomba: payload);
        shouldNotify = true;
      }

      if (shouldNotify) {
        notifyListeners();
      }
    });
  }

  // ---------------- RECONNECT WITH NEW CONFIG ----------------
  Future<void> reconnectWithNewConfig(String host, int port) async {
    // Guarda config
    await saveConfig(host, port);

    // Desconecta todo de forma segura
    await _updatesSub?.cancel();
    _updatesSub = null;

    try {
      client?.disconnect();
    } catch (_) {}

    client = null;
    _setConnected(false);

    // Reconecta
    await connect();
  }

  // ---------------- COMMANDS ----------------
  void toggleModo() {
    final c = client;
    if (c == null || !_isConnected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString('TOGGLE');

    c.publishMessage(
      'cultivo/control/modo',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void toggleBomba() {
    final c = client;
    if (c == null || !_isConnected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString('TOGGLE');

    c.publishMessage(
      'cultivo/control/bomba',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  // ---------------- CONNECTION CALLBACKS ----------------
  void _onConnected() {
    debugPrint('✅ MQTT conectado');
    _setConnected(true);
  }

  void _onDisconnected() {
    debugPrint('🔴 MQTT desconectado');
    _setConnected(false);
  }

  void _setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    notifyListeners();
  }
}