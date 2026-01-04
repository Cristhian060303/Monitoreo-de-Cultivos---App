class SystemState {
  final String modo;   // AUTO / MANUAL
  final String bomba;  // ON / OFF

  const SystemState({
    required this.modo,
    required this.bomba,
  });

  SystemState copyWith({
    String? modo,
    String? bomba,
  }) {
    return SystemState(
      modo: modo ?? this.modo,
      bomba: bomba ?? this.bomba,
    );
  }
}
