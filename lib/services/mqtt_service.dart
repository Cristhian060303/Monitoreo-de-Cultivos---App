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

  // ---------------- CONNECT ----------------
  Future<void> connect() async {
    await loadConfig();

    client = MqttServerClient(mqttHost, 'flutter_cultivo');
    client?.port = mqttPort;
    client?.keepAlivePeriod = 20;
    client?.logging(on: true);

    client?.onConnected = _onConnected;
    client?.onDisconnected = _onDisconnected;

    client?.connectionMessage =
        MqttConnectMessage().withClientIdentifier('flutter_cultivo');

    try {
      await client?.connect();
    } catch (e) {
      debugPrint('MQTT error: $e');
      return;
    }

    _subscribeTopics();
    _listenUpdates();
  }

  // ---------------- SUBSCRIPTIONS ----------------
  void _subscribeTopics() {
    client?.subscribe('cultivo/sensores', MqttQos.atMostOnce);
    client?.subscribe('cultivo/ia/resultado', MqttQos.atMostOnce);
    client?.subscribe('cultivo/ia/confianza', MqttQos.atMostOnce);
    client?.subscribe('cultivo/ia/detecciones', MqttQos.atMostOnce);
    client?.subscribe('cultivo/estado/modo', MqttQos.atMostOnce);
    client?.subscribe('cultivo/estado/bomba', MqttQos.atMostOnce);
  }

  // ---------------- LISTENER ----------------
  void _listenUpdates() {
    client?.updates!.listen((events) {
      final message = events.first.payload as MqttPublishMessage;
      final topic = events.first.topic;

      final payloadRaw =
      MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );
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
    if (client?.connectionStatus?.state ==
        MqttConnectionState.connected) {
      client?.disconnect();
    }

    await saveConfig(host, port);
    await connect();
  }


  // ---------------- COMMANDS ----------------
  void toggleModo() {
    final builder = MqttClientPayloadBuilder();
    builder.addString('TOGGLE');

    client?.publishMessage(
      'cultivo/control/modo',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void toggleBomba() {
    final builder = MqttClientPayloadBuilder();
    builder.addString('TOGGLE');

    client?.publishMessage(
      'cultivo/control/bomba',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  //---------------- STATES ----------------

  void _onConnected() {
    debugPrint('MQTT conectado');
    notifyListeners();
  }

  void _onDisconnected() {
    debugPrint('MQTT desconectado');
    notifyListeners();
  }

}