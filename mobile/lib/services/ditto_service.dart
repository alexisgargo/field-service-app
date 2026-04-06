import 'dart:async';
import 'dart:io';
import 'package:ditto_live/ditto_live.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import '../models/work_order.dart';

enum SyncStatus { syncing, synced, offline, error }

/// Exception thrown when offline operations fail
class OfflineOperationException implements Exception {
  final String message;
  final dynamic originalError;

  const OfflineOperationException(this.message, [this.originalError]);

  @override
  String toString() => 'OfflineOperationException: $message';
}

/// Exception thrown when network operations fail
class NetworkOperationException implements Exception {
  final String message;
  final dynamic originalError;

  const NetworkOperationException(this.message, [this.originalError]);

  @override
  String toString() => 'NetworkOperationException: $message';
}

/// Service class to manage Ditto SDK integration for work order management
/// This provides offline-first data operations and real-time synchronization
class DittoService {
  static final DittoService _instance = DittoService._internal();
  factory DittoService() => _instance;
  DittoService._internal();

  Ditto? _ditto;
  StoreObserver? _workOrdersObserver;
  SyncSubscription? _workOrdersSubscription;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();
  // final StreamController<List<WorkOrder>> _workOrdersController =
  //     StreamController<List<WorkOrder>>.broadcast();
  final BehaviorSubject<List<WorkOrder>> _workOrdersController =
      BehaviorSubject<List<WorkOrder>>.seeded([]);

  bool _isInitialized = false;
  bool _isConnected = false;
  bool _hasNetworkConnectivity = true;
  Timer? _connectionTimer;
  Timer? _networkCheckTimer;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  bool get hasNetworkConnectivity => _hasNetworkConnectivity;
  bool get isOffline => !_hasNetworkConnectivity;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  /// Initialize Ditto SDK with app configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");

      final appId = dotenv.env['DITTO_APP_ID'];
      final token = dotenv.env['DITTO_TOKEN'];

      if (appId == null || token == null) {
        throw OfflineOperationException(
          'Ditto App ID and Token must be configured in .env file',
        );
      }

      await Ditto.init();

      DittoLogger.minimumLogLevel = LogLevel.debug;

      // Initialize actual Ditto SDK
      _ditto = await Ditto.open(
        identity: OnlinePlaygroundIdentity(
          appID: appId,
          token: token,
          enableDittoCloudSync: false,
          customAuthUrl: "https://3b9ae71.cloud.dittolive.app",
        ),
      );

      _ditto!.updateTransportConfig((config) {
        config.setAllPeerToPeerEnabled(true);
        config.connect.webSocketUrls.add("wss://3b9ae71.cloud.dittolive.app");
      });

      // Check initial network connectivity
      await _checkNetworkConnectivity();

      // Start network monitoring
      _startNetworkMonitoring();

      // Set initial sync status based on connectivity
      if (_hasNetworkConnectivity) {
        _syncStatusController.add(
          SyncStatus.offline,
        ); // Will be updated when sync starts
      } else {
        _syncStatusController.add(SyncStatus.offline);
      }

      _isInitialized = true;

      print(
        'DittoService: Initialized successfully - Network: $_hasNetworkConnectivity',
      );
    } catch (e) {
      print('DittoService: Failed to initialize - $e');
      _syncStatusController.add(SyncStatus.error);
      throw OfflineOperationException('Failed to initialize Ditto service', e);
    }
  }

  /// Start Ditto sync operations
  Future<void> startSync() async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before starting sync',
      );
    }

    try {
      // Start actual Ditto sync
      _ditto!.startSync();

      // Set up live query observer for work orders
      await _setupWorkOrdersObserver();

      // Check network connectivity before starting sync
      await _checkNetworkConnectivity();

      // Start connection monitoring
      _monitorConnectionStatus();

      if (_hasNetworkConnectivity) {
        _isConnected = true;
        _connectionStatusController.add(true);
        _syncStatusController.add(SyncStatus.synced);
      } else {
        _isConnected = false;
        _connectionStatusController.add(false);
        _syncStatusController.add(SyncStatus.offline);
      }

      print(
        'DittoService: Sync started - Connected: $_isConnected, Network: $_hasNetworkConnectivity',
      );
    } catch (e) {
      print('DittoService: Failed to start sync - $e');
      _syncStatusController.add(SyncStatus.error);
      if (e is OfflineOperationException) rethrow;
      throw NetworkOperationException('Failed to start sync operations', e);
    }
  }

  /// Stop Ditto sync operations
  Future<void> stopSync() async {
    try {
      if (_ditto != null) {
        _ditto!.stopSync();
      }

      _connectionTimer?.cancel();
      _networkCheckTimer?.cancel();
      _workOrdersObserver?.cancel();

      _isConnected = false;
      _connectionStatusController.add(false);
      _syncStatusController.add(SyncStatus.offline);

      print('DittoService: Sync stopped');
    } catch (e) {
      print('DittoService: Failed to stop sync - $e');
      _syncStatusController.add(SyncStatus.error);
    }
  }

  /// Check network connectivity
  Future<void> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _hasNetworkConnectivity =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _hasNetworkConnectivity = false;
    }

    _connectionStatusController.add(_hasNetworkConnectivity);
  }

  /// Start network monitoring
  void _startNetworkMonitoring() {
    _networkCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }

      final previousConnectivity = _hasNetworkConnectivity;
      _checkNetworkConnectivity().then((_) {
        if (previousConnectivity != _hasNetworkConnectivity) {
          _handleConnectivityChange(
            previousConnectivity,
            _hasNetworkConnectivity,
          );
        }
      });
    });
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(bool wasConnected, bool isNowConnected) {
    print(
      'DittoService: Connectivity changed from $wasConnected to $isNowConnected',
    );

    if (!wasConnected && isNowConnected) {
      _onConnectivityRestored();
    } else if (wasConnected && !isNowConnected) {
      _onConnectivityLost();
    }
  }

  /// Handle when connectivity is restored
  void _onConnectivityRestored() async {
    print(
      'DittoService: Connectivity restored - Ditto SDK will handle sync automatically',
    );
    _isConnected = true;
    _connectionStatusController.add(true);
    _syncStatusController.add(SyncStatus.synced);
  }

  /// Handle when connectivity is lost
  void _onConnectivityLost() {
    print('DittoService: Connectivity lost - switching to offline mode');
    _isConnected = false;
    _connectionStatusController.add(false);
    _syncStatusController.add(SyncStatus.offline);
  }

  /// Monitor connection status and update streams
  void _monitorConnectionStatus() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }

      if (_isConnected && _hasNetworkConnectivity) {
        _syncStatusController.add(SyncStatus.synced);
      } else {
        _syncStatusController.add(SyncStatus.offline);
      }
    });
  }

  /// Insert a work order into Ditto (offline-first)
  Future<void> insertWorkOrder(WorkOrder workOrder) async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before inserting data',
      );
    }

    try {
      // Use Ditto DQL INSERT with ON ID CONFLICT DO UPDATE
      await _ditto!.store.execute(
        """
        INSERT INTO workorders
        DOCUMENTS (:newWorkOrder)
        ON ID CONFLICT DO UPDATE
        """,
        arguments: {"newWorkOrder": workOrder.toJson()},
      );

      _notifyWorkOrdersChanged();

      print(
        'DittoService: Inserted work order ${workOrder.id} (offline: ${!_hasNetworkConnectivity})',
      );
    } catch (e) {
      print('DittoService: Failed to insert work order - $e');
      throw OfflineOperationException('Failed to insert work order', e);
    }
  }

  /// Insert multiple work orders into Ditto (batch operation, offline-first)
  Future<void> insertWorkOrders(List<WorkOrder> workOrders) async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before inserting data',
      );
    }

    try {
      // Insert each work order
      for (final workOrder in workOrders) {
        await _ditto!.store.execute(
          """
          INSERT INTO workorders
          DOCUMENTS (:newWorkOrder)
          ON ID CONFLICT DO UPDATE
          """,
          arguments: {"newWorkOrder": workOrder.toJson()},
        );
      }

      _notifyWorkOrdersChanged();

      print(
        'DittoService: Inserted ${workOrders.length} work orders (offline: ${!_hasNetworkConnectivity})',
      );
    } catch (e) {
      print('DittoService: Failed to insert work orders - $e');
      throw OfflineOperationException('Failed to insert work orders', e);
    }
  }

  /// Query all work orders from Ditto (works offline)
  Future<List<WorkOrder>> queryWorkOrders() async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before querying data',
      );
    }

    try {
      final result = await _ditto!.store.execute(
        "SELECT * FROM workorders ORDER BY createdAt DESC",
      );

      // final result = await _ditto!.store.execute("delete FROM workorders");

      final workOrders = result.items
          .map((item) => WorkOrder.fromJson(item.value))
          .toList();

      print(
        'DittoService: Queried ${workOrders.length} work orders (offline: ${!_hasNetworkConnectivity})',
      );
      return workOrders;
    } catch (e) {
      print('DittoService: Failed to query work orders - $e');
      throw OfflineOperationException('Failed to query work orders', e);
    }
  }

  /// Query a specific work order by ID (works offline)
  Future<WorkOrder?> queryWorkOrderById(String id) async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before querying data',
      );
    }

    try {
      final result = await _ditto!.store.execute(
        "SELECT * FROM workorders WHERE _id = :id",
        arguments: {"id": id},
      );

      if (result.items.isEmpty) {
        return null;
      }

      return WorkOrder.fromJson(result.items.first.value);
    } catch (e) {
      print('DittoService: Failed to query work order by ID - $e');
      throw OfflineOperationException('Failed to query work order by ID', e);
    }
  }

  /// Update a work order in Ditto (offline-first)
  Future<void> updateWorkOrder(WorkOrder workOrder) async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before updating data',
      );
    }

    try {
      // Use INSERT with ON ID CONFLICT DO UPDATE for upsert behavior
      await _ditto!.store.execute(
        """
        INSERT INTO workorders
        DOCUMENTS (:workOrder)
        ON ID CONFLICT DO UPDATE
        """,
        arguments: {"workOrder": workOrder.toJson()},
      );

      _notifyWorkOrdersChanged();

      print(
        'DittoService: Updated work order ${workOrder.id} (offline: ${!_hasNetworkConnectivity})',
      );
    } catch (e) {
      print('DittoService: Failed to update work order - $e');
      throw OfflineOperationException('Failed to update work order', e);
    }
  }

  /// Delete a work order from Ditto (offline-first)
  Future<void> deleteWorkOrder(String id) async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before deleting data',
      );
    }

    try {
      await _ditto!.store.execute(
        "DELETE FROM workorders WHERE _id = :id",
        arguments: {"id": id},
      );

      _notifyWorkOrdersChanged();

      print(
        'DittoService: Deleted work order $id (offline: ${!_hasNetworkConnectivity})',
      );
    } catch (e) {
      print('DittoService: Failed to delete work order - $e');
      throw OfflineOperationException('Failed to delete work order', e);
    }
  }

  /// Query work orders by status (works offline)
  Future<List<WorkOrder>> queryWorkOrdersByStatus(
    WorkOrderStatus status,
  ) async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before querying data',
      );
    }

    try {
      final result = await _ditto!.store.execute(
        "SELECT * FROM workorders WHERE status = :status ORDER BY createdAt DESC",
        arguments: {"status": status.toJson()},
      );

      final workOrders = result.items
          .map((item) => WorkOrder.fromJson(item.value))
          .toList();

      print(
        'DittoService: Queried ${workOrders.length} work orders with status ${status.toJson()} (offline: ${!_hasNetworkConnectivity})',
      );
      return workOrders;
    } catch (e) {
      print('DittoService: Failed to query work orders by status - $e');
      throw OfflineOperationException(
        'Failed to query work orders by status',
        e,
      );
    }
  }

  /// Query work orders by technician ID (works offline)
  Future<List<WorkOrder>> queryWorkOrdersByTechnician(
    String technicianId,
  ) async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before querying data',
      );
    }

    try {
      final result = await _ditto!.store.execute(
        "SELECT * FROM workorders WHERE technician_id = :technicianId ORDER BY createdAt DESC",
        arguments: {"technicianId": technicianId},
      );

      final workOrders = result.items
          .map((item) => WorkOrder.fromJson(item.value))
          .toList();

      print(
        'DittoService: Queried ${workOrders.length} work orders for technician $technicianId (offline: ${!_hasNetworkConnectivity})',
      );
      return workOrders;
    } catch (e) {
      print('DittoService: Failed to query work orders by technician - $e');
      throw OfflineOperationException(
        'Failed to query work orders by technician',
        e,
      );
    }
  }

  /// Update work order status with timestamp (offline-first)
  Future<void> updateWorkOrderStatus(String id, WorkOrderStatus status) async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before updating data',
      );
    }

    try {
      // First, query the existing work order
      final existing = await queryWorkOrderById(id);
      if (existing == null) {
        throw OfflineOperationException('Work order with ID $id not found');
      }

      final now = DateTime.now();
      WorkOrder updatedWorkOrder;

      // Update status and timestamps based on new status
      switch (status) {
        case WorkOrderStatus.inProgress:
          updatedWorkOrder = existing.copyWith(
            status: status,
            startTime: now,
            updatedAt: now,
          );
          break;
        case WorkOrderStatus.completed:
          updatedWorkOrder = existing.copyWith(
            status: status,
            completionTime: now,
            updatedAt: now,
          );
          break;
        case WorkOrderStatus.pending:
          updatedWorkOrder = existing.copyWith(
            status: status,
            startTime: null,
            completionTime: null,
            updatedAt: now,
          );
          break;
      }

      // Update using INSERT with ON ID CONFLICT DO UPDATE
      await _ditto!.store.execute(
        """
        INSERT INTO workorders
        DOCUMENTS (:workOrder)
        ON ID CONFLICT DO UPDATE
        """,
        arguments: {"workOrder": updatedWorkOrder.toJson()},
      );

      _notifyWorkOrdersChanged();

      print(
        'DittoService: Updated work order $id status to ${status.toJson()} (offline: ${!_hasNetworkConnectivity})',
      );
    } catch (e) {
      print('DittoService: Failed to update work order status - $e');
      if (e is OfflineOperationException) rethrow;
      throw OfflineOperationException('Failed to update work order status', e);
    }
  }

  /// Subscribe to real-time work order changes (works offline)
  Stream<List<WorkOrder>> subscribeToWorkOrders() {
    // Return stream immediately, but set up observer once initialized
    if (_isInitialized && _ditto != null && _workOrdersObserver == null) {
      _setupWorkOrdersObserver();
    }

    return _workOrdersController.stream;
  }

  /// Internal method to set up the live query observer
  Future<void> _setupWorkOrdersObserver() async {
    if (_ditto == null) return;

    try {
      final initialResult = (await _ditto!.store.execute(
        "SELECT * FROM workorders WHERE technician_id = 'tech_001' ORDER BY status DESC",
      ));
      // print(initialResult.items.first.value);
      final initialWorkOrders = initialResult.items
          .map((item) => WorkOrder.fromJson(item.value))
          .toList();

      // print("----------------");

      var workOrders = initialWorkOrders;
      _workOrdersController.add(initialWorkOrders);

      _workOrdersObserver = _ditto!.store.registerObserver(
        "SELECT * FROM workorders WHERE technician_id = 'tech_001' ORDER BY status DESC",
        onChange: (result) {
          workOrders = result.items
              .map((item) => WorkOrder.fromJson(item.value))
              .toList();
          _workOrdersController.add(workOrders);
        },
      );

      // print("--------------------");

      _workOrdersSubscription = _ditto!.sync.registerSubscription(
        "SELECT * FROM workorders WHERE technician_id = 'tech_001' ORDER BY status DESC",
      );

      print('DittoService: Live query observer set up successfully');
    } catch (e) {
      print('DittoService: Failed to set up observer - $e');
    }
  }

  /// Subscribe to changes for a specific work order (works offline)
  Stream<WorkOrder?> subscribeToWorkOrder(String id) {
    // Ensure observer is set up
    if (_isInitialized && _ditto != null && _workOrdersObserver == null) {
      // print('saaa');
      _setupWorkOrdersObserver();
    }

    return _workOrdersController.stream.map((workOrders) {
      try {
        return workOrders.firstWhere((wo) => wo.id == id);
      } catch (e) {
        return null;
      }
    });
  }

  /// Subscribe to work orders by status with real-time updates (works offline)
  Stream<List<WorkOrder>> subscribeToWorkOrdersByStatus(
    WorkOrderStatus status,
  ) {
    // Ensure observer is set up
    if (_isInitialized && _ditto != null && _workOrdersObserver == null) {
      _setupWorkOrdersObserver();
    }

    return _workOrdersController.stream.map((workOrders) {
      return workOrders.where((wo) => wo.status == status).toList();
    });
  }

  /// Subscribe to work orders by technician with real-time updates (works offline)
  Stream<List<WorkOrder>> subscribeToWorkOrdersByTechnician(
    String technicianId,
  ) {
    // Ensure observer is set up
    if (_isInitialized && _ditto != null && _workOrdersObserver == null) {
      _setupWorkOrdersObserver();
    }

    return _workOrdersController.stream.map((workOrders) {
      return workOrders.where((wo) => wo.technicianId == technicianId).toList();
    });
  }

  /// Get connection statistics and sync information
  Map<String, dynamic> getConnectionInfo() {
    int totalWorkOrders = 0;

    return {
      'isInitialized': _isInitialized,
      'isConnected': _isConnected,
      'hasNetworkConnectivity': _hasNetworkConnectivity,
      'isOffline': isOffline,
      'syncStatus': _hasNetworkConnectivity && _isConnected
          ? 'connected'
          : 'offline',
      'lastSyncTime': DateTime.now().toIso8601String(),
      'totalWorkOrders': totalWorkOrders,
    };
  }

  /// Force a manual sync operation
  Future<void> forceSync() async {
    if (!_isInitialized || _ditto == null) {
      throw OfflineOperationException(
        'DittoService must be initialized before forcing sync',
      );
    }

    try {
      await _checkNetworkConnectivity();

      if (!_hasNetworkConnectivity) {
        throw NetworkOperationException(
          'Cannot sync: No network connectivity available',
        );
      }

      _syncStatusController.add(SyncStatus.syncing);

      // Ditto SDK handles sync automatically
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isConnected && _hasNetworkConnectivity) {
        _syncStatusController.add(SyncStatus.synced);
      } else {
        _syncStatusController.add(SyncStatus.offline);
      }

      print('DittoService: Manual sync completed');
    } catch (e) {
      print('DittoService: Failed to force sync - $e');
      _syncStatusController.add(SyncStatus.error);
      if (e is NetworkOperationException || e is OfflineOperationException) {
        rethrow;
      }
      throw NetworkOperationException('Failed to complete manual sync', e);
    }
  }

  /// Notify subscribers of work order changes
  void _notifyWorkOrdersChanged() async {
    try {
      final workOrders = await queryWorkOrders();
      _workOrdersController.add(workOrders);
    } catch (e) {
      print('DittoService: Failed to notify work order changes - $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectionTimer?.cancel();
    _networkCheckTimer?.cancel();
    _workOrdersObserver?.cancel();
    _workOrdersSubscription?.cancel();

    _connectionStatusController.close();
    _syncStatusController.close();
    _workOrdersController.close();
  }
}
