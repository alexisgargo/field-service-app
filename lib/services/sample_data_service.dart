import '../models/work_order.dart';
import 'ditto_service.dart';

/// Service to generate and populate sample work order data for demo purposes
class SampleDataService {
  static final SampleDataService _instance = SampleDataService._internal();
  factory SampleDataService() => _instance;
  SampleDataService._internal();

  final DittoService _dittoService = DittoService();

  /// Generate sample work orders for demo purposes with variety of customers, equipment, and scenarios
  List<WorkOrder> generateSampleWorkOrders() {
    final now = DateTime.now();

    return [
      // Pending work orders - variety of equipment types and urgency levels
      WorkOrder(
        id: 'wo_001',
        customerName: 'Acme Manufacturing',
        customerAddress: '123 Industrial Blvd, Manufacturing District',
        equipmentModel: 'CompressorMax 3000',
        equipmentSerial: 'CM3000-2023-001',
        problemDescription:
            'Air compressor making unusual noise and losing pressure. Requires immediate inspection and potential part replacement.',
        status: WorkOrderStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        technicianId: 'tech_001',
      ),
      WorkOrder(
        id: 'wo_004',
        customerName: 'Riverside Shopping Mall',
        customerAddress: '321 Commerce St, Riverside',
        equipmentModel: 'EscalatorPro X1',
        equipmentSerial: 'EPX1-2021-078',
        problemDescription:
            'Escalator intermittently stopping. Safety sensors may need calibration.',
        status: WorkOrderStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        technicianId: 'tech_001',
      ),
      WorkOrder(
        id: 'wo_005',
        customerName: 'Tech Startup Hub',
        customerAddress: '555 Innovation Way, Tech District',
        equipmentModel: 'ServerCool 4000',
        equipmentSerial: 'SC4000-2023-089',
        problemDescription:
            'Server room cooling system showing error codes. Temperature rising above safe levels.',
        status: WorkOrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        technicianId: 'tech_002',
      ),
      WorkOrder(
        id: 'wo_007',
        customerName: 'Metro Transit Authority',
        customerAddress: '100 Transit Plaza, Metro Center',
        equipmentModel: 'TurnstileMax Pro',
        equipmentSerial: 'TMP-2023-045',
        problemDescription:
            'Multiple turnstiles not accepting payment cards. Card readers need replacement.',
        status: WorkOrderStatus.pending,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        technicianId: 'tech_003',
      ),
      WorkOrder(
        id: 'wo_008',
        customerName: 'Oceanview Resort',
        customerAddress: '777 Coastal Highway, Oceanview',
        equipmentModel: 'PoolPump Elite 2000',
        equipmentSerial: 'PPE2000-2022-234',
        problemDescription:
            'Pool filtration system not circulating water properly. Guests complaining about water clarity.',
        status: WorkOrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 45)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
        technicianId: 'tech_004',
      ),

      // In Progress work order - currently being worked on
      WorkOrder(
        id: 'wo_002',
        customerName: 'Downtown Office Complex',
        customerAddress: '456 Business Ave, Downtown',
        equipmentModel: 'HVAC Pro 5000',
        equipmentSerial: 'HP5000-2022-045',
        problemDescription:
            'HVAC system not maintaining temperature. Building temperature fluctuating between floors.',
        status: WorkOrderStatus.inProgress,
        startTime: now.add(const Duration(minutes: 45)),
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
        technicianId: 'tech_001',
      ),

      // Completed work orders - variety of completion times and equipment types
      WorkOrder(
        id: 'wo_003',
        customerName: 'Green Valley Hospital',
        customerAddress: '789 Medical Center Dr, Green Valley',
        equipmentModel: 'MedGen 2000',
        equipmentSerial: 'MG2000-2023-012',
        problemDescription:
            'Backup generator failed during routine test. Critical system requires immediate attention.',
        status: WorkOrderStatus.completed,
        startTime: now.subtract(const Duration(days: 3)),
        completionTime: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        technicianId: 'tech_001',
      ),
      WorkOrder(
        id: 'wo_006',
        customerName: 'City Water Treatment',
        customerAddress: '888 Utility Rd, Industrial Zone',
        equipmentModel: 'PumpMaster 8000',
        equipmentSerial: 'PM8000-2022-156',
        problemDescription:
            'Main water pump vibrating excessively. Potential bearing failure detected.',
        status: WorkOrderStatus.completed,
        startTime: now.subtract(const Duration(days: 1, hours: 2)),
        completionTime: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
        technicianId: 'tech_002',
      ),
      WorkOrder(
        id: 'wo_009',
        customerName: 'University Science Building',
        customerAddress: '200 Campus Drive, University District',
        equipmentModel: 'LabVent 3000',
        equipmentSerial: 'LV3000-2023-067',
        problemDescription:
            'Laboratory fume hood ventilation system not maintaining proper airflow. Safety concern for researchers.',
        status: WorkOrderStatus.completed,
        startTime: now.subtract(const Duration(days: 2, hours: 3)),
        completionTime: now.subtract(const Duration(days: 2, hours: 1)),
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
        updatedAt: now.subtract(const Duration(days: 2, hours: 1)),
        technicianId: 'tech_003',
      ),
      WorkOrder(
        id: 'wo_010',
        customerName: 'Northside Grocery Chain',
        customerAddress: '333 Market Street, Northside',
        equipmentModel: 'CoolFreeze 5000',
        equipmentSerial: 'CF5000-2021-189',
        problemDescription:
            'Walk-in freezer temperature fluctuating. Risk of food spoilage if not addressed quickly.',
        status: WorkOrderStatus.completed,
        startTime: now.subtract(const Duration(hours: 26)),
        completionTime: now.subtract(const Duration(hours: 24)),
        createdAt: now.subtract(const Duration(hours: 28)),
        updatedAt: now.subtract(const Duration(hours: 24)),
        technicianId: 'tech_004',
      ),

      // Additional variety for demo scenarios
      WorkOrder(
        id: 'wo_011',
        customerName: 'Airport Terminal B',
        customerAddress: '1000 Airport Blvd, Terminal B',
        equipmentModel: 'BaggageSort 7000',
        equipmentSerial: 'BS7000-2022-301',
        problemDescription:
            'Baggage sorting conveyor belt jamming frequently. Causing flight delays.',
        status: WorkOrderStatus.pending,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
        technicianId: 'tech_003',
      ),
      WorkOrder(
        id: 'wo_012',
        customerName: 'Central Library',
        customerAddress: '500 Library Square, Downtown',
        equipmentModel: 'BookLift 1500',
        equipmentSerial: 'BL1500-2020-445',
        problemDescription:
            'Automated book retrieval system stuck on level 3. Staff unable to access archived materials.',
        status: WorkOrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
        technicianId: 'tech_002',
      ),
    ];
  }

  /// Initialize sample data in Ditto service
  Future<void> initializeSampleData() async {
    try {
      // Check if data already exists
      final existingWorkOrders = await _dittoService.queryWorkOrders();

      if (existingWorkOrders.isNotEmpty) {
        print(
          'SampleDataService: Sample data already exists, skipping initialization',
        );
        return;
      }

      // Generate and insert sample data
      // final sampleWorkOrders = generateSampleWorkOrders();
      // await _dittoService.insertWorkOrders(sampleWorkOrders);

      // print(
      //   'SampleDataService: Initialized ${sampleWorkOrders.length} sample work orders',
      // );
    } catch (e) {
      print('SampleDataService: Failed to initialize sample data - $e');
      rethrow;
    }
  }

  /// Reset sample data (clear existing and add fresh sample data)
  Future<void> resetSampleData() async {
    try {
      // Get all existing work orders and delete them
      final existingWorkOrders = await _dittoService.queryWorkOrders();

      for (final workOrder in existingWorkOrders) {
        await _dittoService.deleteWorkOrder(workOrder.id);
      }

      // Add fresh sample data
      final sampleWorkOrders = generateSampleWorkOrders();
      await _dittoService.insertWorkOrders(sampleWorkOrders);

      // print(
      //   'SampleDataService: Reset with ${sampleWorkOrders.length} fresh sample work orders',
      // );
    } catch (e) {
      print('SampleDataService: Failed to reset sample data - $e');
      rethrow;
    }
  }
}
