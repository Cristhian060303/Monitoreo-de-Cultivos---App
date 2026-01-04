import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';
import '../models/ia_result.dart';
import '../models/detection.dart';
import '../models/system_state.dart';


class MqttService with ChangeNotifier {
  late MqttServerClient client;
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

  void connect() async {
    client = MqttServerClient('192.168.100.19', 'flutter_cultivo');
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.logging(on: true);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_cultivo')
        .startClean();

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('MQTT error: $e');
      return;
    }

    client.subscribe('cultivo/sensores', MqttQos.atMostOnce);
    client.subscribe('cultivo/ia/resultado', MqttQos.atMostOnce);
    client.subscribe('cultivo/ia/confianza', MqttQos.atMostOnce);
    client.subscribe('cultivo/ia/detecciones', MqttQos.atMostOnce);
    client.subscribe('cultivo/estado/modo', MqttQos.atMostOnce);
    client.subscribe('cultivo/estado/bomba', MqttQos.atMostOnce);

    client.updates!.listen((events) {
      final message = events.first.payload as MqttPublishMessage;
      final payload =
      MqttPublishPayload.bytesToStringAsString(message.payload.message).trim();
      final topic = events.first.topic;

      print('MQTT [$topic]: $payload');

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

  void toggleModo() {
    final builder = MqttClientPayloadBuilder();
    builder.addString('TOGGLE');

    client.publishMessage(
      'cultivo/control/modo',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void toggleBomba() {
    final builder = MqttClientPayloadBuilder();
    builder.addString('TOGGLE');

    client.publishMessage(
      'cultivo/control/bomba',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }
}


