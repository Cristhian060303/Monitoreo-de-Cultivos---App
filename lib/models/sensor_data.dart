class SensorData {
  final int temperatura;
  final int humedad;
  final int humedadSuelo;

  SensorData({
    required this.temperatura,
    required this.humedad,
    required this.humedadSuelo,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperatura: json['temperatura'],
      humedad: json['humedad'],
      humedadSuelo: json['humedad_suelo'],
    );
  }
}
