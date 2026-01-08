import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/bounding_box_painter.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttService>();

    if (mqtt.cameraHost.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vista Cámara')),
        body: const Center(
          child: Text(
            '⚠️ IP de la cámara no configurada',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final streamUrl =
        'http://${mqtt.cameraHost}/stream?t=${mqtt.cameraFrameId}';

    return Scaffold(
      appBar: AppBar(title: const Text('Vista Cámara')),
      body: Center(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  streamUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'No se pudo cargar el stream',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: BoundingBoxPainter(
                    detections: mqtt.detections,
                    frameW: mqtt.frameWidth,
                    frameH: mqtt.frameHeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}