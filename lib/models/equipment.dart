class Equipment {
  final String id;
  final String model;
  final String serialNumber;
  final String type;

  const Equipment({
    required this.id,
    required this.model,
    required this.serialNumber,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'serial_number': serialNumber,
      'type': type,
    };
  }

  static Equipment fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      model: json['model'] as String,
      serialNumber: json['serial_number'] as String,
      type: json['type'] as String,
    );
  }

  Equipment copyWith({
    String? id,
    String? model,
    String? serialNumber,
    String? type,
  }) {
    return Equipment(
      id: id ?? this.id,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Equipment &&
        other.id == id &&
        other.model == model &&
        other.serialNumber == serialNumber &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, model, serialNumber, type);
  }

  @override
  String toString() {
    return 'Equipment(id: $id, model: $model, serialNumber: $serialNumber, type: $type)';
  }
}
