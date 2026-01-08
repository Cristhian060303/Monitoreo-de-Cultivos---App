import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';

import '../services/mqtt_service.dart';
import 'camera_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _cameraIpController;

  @override
  void initState() {
    super.initState();
    final mqtt = context.read<MqttService>();

    _ipController = TextEditingController(text: mqtt.mqttHost);
    _portController =
        TextEditingController(text: mqtt.mqttPort.toString());
    _cameraIpController =
        TextEditingController(text: mqtt.cameraHost);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _cameraIpController.dispose();
    super.dispose();
  }

  Color _statusColor(String value, {bool invert = false}) {
    if (value == '--') return Colors.grey;
    if (invert) {
      return value == 'OFF' ? Colors.green : Colors.red;
    }
    return (value == 'ON' || value == 'AUTO')
        ? Colors.green
        : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttService>();

    final bool mqttConnected = mqtt.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo de Cultivos'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: mqttConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  mqttConnected ? 'MQTT' : 'Sin conexión',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
            _row(
              '💧 Humedad Aire',
              '${mqtt.sensorData?.humedad ?? '--'} %',
            ),
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
            _row(
              '📊 Confianza',
              '${mqtt.iaResult?.confidence ?? '--'} %',
            ),
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
              _statusColor(
                mqtt.systemState.bomba,
                invert: true,
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ================= CONTROLES =================
          _section('Controles'),
          _card([
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: mqttConnected ? mqtt.toggleModo : null,
                icon: const Icon(Icons.sync),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Alternar Modo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: mqttConnected ? mqtt.toggleBomba : null,
                icon: const Icon(Icons.water_drop),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Alternar Bomba'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.shade700,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ================= CONFIG MQTT =================
          _section('Configuración MQTT'),
          _card([
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP del broker',
                prefixIcon: Icon(Icons.router),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Puerto',
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Guardar y reconectar'),
                ),
                onPressed: () async {
                  final host = _ipController.text.trim();
                  final port =
                      int.tryParse(_portController.text) ?? 1883;

                  if (host.isEmpty) return;

                  await mqtt.reconnectWithNewConfig(host, port);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                        Text('Configuración MQTT actualizada'),
                      ),
                    );
                  }
                },
              ),
            ),
          ]),

          const SizedBox(height: 16),

          _section('Configuración Cámara'),
          _card([
            TextField(
              controller: _cameraIpController,
              decoration: const InputDecoration(
                labelText: 'IP de la ESP32-CAM',
                prefixIcon: Icon(Icons.camera_alt),
                hintText: 'Ej: 192.168.1.50',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Guardar IP de Cámara'),
                ),
                onPressed: () async {
                  final host = _cameraIpController.text.trim();
                  if (host.isEmpty) return;

                  await mqtt.saveCameraHost(host);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('IP de la cámara guardada'),
                      ),
                    );
                  }
                },
              ),
            ),
          ]),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CameraScreen(),
                ),
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
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
            label: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: color,
          ),
        ],
      ),
    );
  }
}