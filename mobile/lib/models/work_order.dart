enum WorkOrderStatus {
  pending,
  inProgress,
  completed;

  String toJson() {
    switch (this) {
      case WorkOrderStatus.pending:
        return 'pending';
      case WorkOrderStatus.inProgress:
        return 'in_progress';
      case WorkOrderStatus.completed:
        return 'completed';
    }
  }

  static WorkOrderStatus fromJson(String status) {
    switch (status) {
      case 'pending':
        return WorkOrderStatus.pending;
      case 'in_progress':
        return WorkOrderStatus.inProgress;
      case 'completed':
        return WorkOrderStatus.completed;
      default:
        throw ArgumentError('Invalid work order status: $status');
    }
  }
}

class WorkOrder {
  final String id;
  final String customerName;
  final String customerAddress;
  final String equipmentModel;
  final String equipmentSerial;
  final String problemDescription;
  final WorkOrderStatus status;
  final DateTime? startTime;
  final DateTime? completionTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String technicianId;

  const WorkOrder({
    required this.id,
    required this.customerName,
    required this.customerAddress,
    required this.equipmentModel,
    required this.equipmentSerial,
    required this.problemDescription,
    required this.status,
    this.startTime,
    this.completionTime,
    required this.createdAt,
    required this.updatedAt,
    required this.technicianId,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'equipment_model': equipmentModel,
      'equipment_serial': equipmentSerial,
      'problem_description': problemDescription,
      'status': status.toJson(),
      'start_time': startTime?.toIso8601String(),
      'completion_time': completionTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'technician_id': technicianId,
    };
  }

  static WorkOrder fromJson(Map<String, dynamic> json) {
    print(json);
    return WorkOrder(
      id: json['_id'] as String,
      customerName: json['customer_name'] as String,
      customerAddress: json['customer_address'] as String,
      equipmentModel: json['equipment_model'] as String,
      equipmentSerial: json['equipment_serial'] as String,
      problemDescription: json['problem_description'] as String,
      status: WorkOrderStatus.fromJson(json['status'] as String),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      completionTime: json['completion_time'] != null
          ? DateTime.parse(json['completion_time'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      technicianId: json['technician_id'] as String,
    );
  }

  WorkOrder copyWith({
    String? id,
    String? customerName,
    String? customerAddress,
    String? equipmentModel,
    String? equipmentSerial,
    String? problemDescription,
    WorkOrderStatus? status,
    DateTime? startTime,
    DateTime? completionTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? technicianId,
  }) {
    return WorkOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      equipmentModel: equipmentModel ?? this.equipmentModel,
      equipmentSerial: equipmentSerial ?? this.equipmentSerial,
      problemDescription: problemDescription ?? this.problemDescription,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      technicianId: technicianId ?? this.technicianId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkOrder &&
        other.id == id &&
        other.customerName == customerName &&
        other.customerAddress == customerAddress &&
        other.equipmentModel == equipmentModel &&
        other.equipmentSerial == equipmentSerial &&
        other.problemDescription == problemDescription &&
        other.status == status &&
        other.startTime == startTime &&
        other.completionTime == completionTime &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.technicianId == technicianId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerName,
      customerAddress,
      equipmentModel,
      equipmentSerial,
      problemDescription,
      status,
      startTime,
      completionTime,
      createdAt,
      updatedAt,
      technicianId,
    );
  }

  @override
  String toString() {
    return 'WorkOrder(id: $id, customerName: $customerName, status: $status)';
  }
}
