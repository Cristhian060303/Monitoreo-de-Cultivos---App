import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/mqtt_service.dart';
import 'camera_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Color _statusColor(String value, {bool invert = false}) {
    if (value == '--') return Colors.grey;
    if (invert) {
      return value == 'OFF' ? Colors.green : Colors.red;
    }
    return (value == 'ON' || value == 'AUTO') ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo de Cultivos'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= SENSORES =================
          _section('Sensores'),
          _card([
            _row(
              '🌡️ Temperatura',
              '${mqtt.sensorData?.temperatura ?? '--'} °C',
            ),
            _row('💧 Humedad Aire', '${mqtt.sensorData?.humedad ?? '--'} %'),
            _row(
              '🌱 Humedad Suelo',
              '${mqtt.sensorData?.humedadSuelo ?? '--'} %',
            ),
          ]),

          const SizedBox(height: 16),

          // ================= IA =================
          _section('Estado IA'),
          _card([
            _row('🧠 Resultado', mqtt.iaResult?.label ?? '--'),
            _row('📊 Confianza', '${mqtt.iaResult?.confidence ?? '--'} %'),
          ]),

          const SizedBox(height: 16),

          // ================= SISTEMA =================
          _section('Estado del Sistema'),
          _card([
            _statusRow(
              '⚙️ Modo',
              mqtt.systemState.modo,
              _statusColor(mqtt.systemState.modo),
            ),
            _statusRow(
              '🚰 Bomba',
              mqtt.systemState.bomba,
              _statusColor(mqtt.systemState.bomba, invert: true),
            ),
          ]),

          const SizedBox(height: 16),

          // ================= CONTROLES =================
          _section('Controles'),
          _card([
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: mqtt.toggleModo,
                icon: const Icon(Icons.sync, size: 22),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Alternar Modo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: mqtt.toggleBomba,
                icon: const Icon(Icons.water_drop, size: 22),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Alternar Bomba',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Ver Cámara'),
          ),
        ],
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Chip(
            label: Text(value, style: const TextStyle(color: Colors.white)),
            backgroundColor: color,
          ),
        ],
      ),
    );
  }
}
