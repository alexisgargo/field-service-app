class Customer {
  final String id;
  final String name;
  final String address;
  final String phone;

  const Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'address': address, 'phone': phone};
  }

  static Customer fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.phone == phone;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, address, phone);
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, address: $address, phone: $phone)';
  }
}
