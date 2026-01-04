import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/bounding_box_painter.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vista Cámara')),
      body: Center(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  'http://192.168.100.37/stream?t=${mqtt.cameraFrameId}',
                  fit: BoxFit.cover,
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
          )
        ),
      ),
    );
  }
}