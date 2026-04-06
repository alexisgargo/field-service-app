import 'dart:async';
import '../models/work_order.dart';
import 'ditto_service.dart';

/// Business logic service for work order management
/// This service wraps Ditto operations and provides higher-level business logic
/// for work order operations including status transitions and validation
class WorkOrderService {
  static final WorkOrderService _instance = WorkOrderService._internal();
  factory WorkOrderService() => _instance;
  WorkOrderService._internal();

  final DittoService _dittoService = DittoService();

  /// Initialize the work order service
  Future<void> initialize() async {
    await _dittoService.initialize();
  }

  /// Get all work orders (works offline)
  /// Returns a list of all work orders sorted by creation date (newest first)
  Future<List<WorkOrder>> getWorkOrders() async {
    try {
      return await _dittoService.queryWorkOrders();
    } catch (e) {
      print('WorkOrderService: Failed to get work orders - $e');
      if (e is OfflineOperationException) {
        // Re-throw offline exceptions with additional context
        throw OfflineOperationException(
          'Unable to retrieve work orders: ${e.message}',
          e.originalError,
        );
      }
      rethrow;
    }
  }

  /// Get a specific work order by ID (works offline)
  /// Returns the work order if found, null otherwise
  Future<WorkOrder?> getWorkOrderById(String id) async {
    try {
      return await _dittoService.queryWorkOrderById(id);
    } catch (e) {
      print('WorkOrderService: Failed to get work order by ID - $e');
      if (e is OfflineOperationException) {
        // Re-throw offline exceptions with additional context
        throw OfflineOperationException(
          'Unable to retrieve work order $id: ${e.message}',
          e.originalError,
        );
      }
      rethrow;
    }
  }

  /// Update work order status with proper validation and timestamps (works offline)
  /// Validates status transitions and updates appropriate timestamp fields
  Future<void> updateWorkOrderStatus(
    String id,
    WorkOrderStatus newStatus,
  ) async {
    try {
      // Get current work order to validate transition
      final currentWorkOrder = await _dittoService.queryWorkOrderById(id);
      if (currentWorkOrder == null) {
        throw OfflineOperationException(
          'Work order with ID $id not found locally',
        );
      }

      // Validate status transition
      _validateStatusTransition(currentWorkOrder.status, newStatus);

      // Validate timestamp logic before updating
      _validateTimestampLogic(currentWorkOrder, newStatus);

      // Update status through Ditto service (which handles timestamps)
      await _dittoService.updateWorkOrderStatus(id, newStatus);

      print(
        'WorkOrderService: Updated work order $id status to ${newStatus.toJson()} (offline: ${_dittoService.isOffline})',
      );
    } catch (e) {
      print('WorkOrderService: Failed to update work order status - $e');
      if (e is OfflineOperationException) {
        // Re-throw offline exceptions with additional context
        throw OfflineOperationException(
          'Unable to update work order status: ${e.message}',
          e.originalError,
        );
      }
      rethrow;
    }
  }

  /// Start work on a work order
  /// Updates status to inProgress and sets start time
  Future<void> startWork(String id) async {
    try {
      await updateWorkOrderStatus(id, WorkOrderStatus.inProgress);
      print('WorkOrderService: Started work on work order $id');
    } catch (e) {
      print('WorkOrderService: Failed to start work - $e');
      rethrow;
    }
  }

  /// Complete work on a work order
  /// Updates status to completed and sets completion time
  Future<void> completeWork(String id) async {
    try {
      await updateWorkOrderStatus(id, WorkOrderStatus.completed);
      print('WorkOrderService: Completed work on work order $id');
    } catch (e) {
      print('WorkOrderService: Failed to complete work - $e');
      rethrow;
    }
  }

  /// Reset work order to pending status
  /// Clears start time and completion time
  Future<void> resetWorkOrder(String id) async {
    try {
      await updateWorkOrderStatus(id, WorkOrderStatus.pending);
      print('WorkOrderService: Reset work order $id to pending');
    } catch (e) {
      print('WorkOrderService: Failed to reset work order - $e');
      rethrow;
    }
  }

  /// Watch all work orders with real-time updates
  /// Returns a stream that emits the latest list of work orders whenever changes occur
  Stream<List<WorkOrder>> watchWorkOrders() {
    try {
      return _dittoService.subscribeToWorkOrders();
    } catch (e) {
      print('WorkOrderService: Failed to watch work orders - $e');
      rethrow;
    }
  }

  /// Watch a specific work order by ID with real-time updates
  /// Returns a stream that emits the work order whenever it changes
  Stream<WorkOrder?> watchWorkOrderById(String id) {
    try {
      return _dittoService.subscribeToWorkOrder(id);
    } catch (e) {
      print('WorkOrderService: Failed to watch work order by ID - $e');
      rethrow;
    }
  }

  /// Watch work orders by status with real-time updates
  /// Returns a stream that emits work orders with the specified status
  Stream<List<WorkOrder>> watchWorkOrdersByStatus(WorkOrderStatus status) {
    try {
      return _dittoService.subscribeToWorkOrdersByStatus(status);
    } catch (e) {
      print('WorkOrderService: Failed to watch work orders by status - $e');
      rethrow;
    }
  }

  /// Watch work orders by technician with real-time updates
  /// Returns a stream that emits work orders assigned to the specified technician
  Stream<List<WorkOrder>> watchWorkOrdersByTechnician(String technicianId) {
    try {
      return _dittoService.subscribeToWorkOrdersByTechnician(technicianId);
    } catch (e) {
      print('WorkOrderService: Failed to watch work orders by technician - $e');
      rethrow;
    }
  }

  /// Get work orders by status (works offline)
  /// Returns a list of work orders with the specified status
  Future<List<WorkOrder>> getWorkOrdersByStatus(WorkOrderStatus status) async {
    try {
      return await _dittoService.queryWorkOrdersByStatus(status);
    } catch (e) {
      print('WorkOrderService: Failed to get work orders by status - $e');
      if (e is OfflineOperationException) {
        // Re-throw offline exceptions with additional context
        throw OfflineOperationException(
          'Unable to retrieve work orders by status: ${e.message}',
          e.originalError,
        );
      }
      rethrow;
    }
  }

  /// Get work orders by technician (works offline)
  /// Returns a list of work orders assigned to the specified technician
  Future<List<WorkOrder>> getWorkOrdersByTechnician(String technicianId) async {
    try {
      return await _dittoService.queryWorkOrdersByTechnician(technicianId);
    } catch (e) {
      print('WorkOrderService: Failed to get work orders by technician - $e');
      if (e is OfflineOperationException) {
        // Re-throw offline exceptions with additional context
        throw OfflineOperationException(
          'Unable to retrieve work orders by technician: ${e.message}',
          e.originalError,
        );
      }
      rethrow;
    }
  }

  /// Validate status transition to ensure proper workflow
  /// Throws ArgumentError if the transition is invalid
  void _validateStatusTransition(
    WorkOrderStatus currentStatus,
    WorkOrderStatus newStatus,
  ) {
    // Define valid transitions
    const validTransitions = {
      WorkOrderStatus.pending: [WorkOrderStatus.inProgress],
      WorkOrderStatus.inProgress: [
        WorkOrderStatus.completed,
        WorkOrderStatus.pending,
      ],
      WorkOrderStatus.completed: [
        WorkOrderStatus.pending,
      ], // Allow reopening if needed
    };

    final allowedTransitions = validTransitions[currentStatus] ?? [];

    if (!allowedTransitions.contains(newStatus)) {
      throw ArgumentError(
        'Invalid status transition from ${currentStatus.toJson()} to ${newStatus.toJson()}. '
        'Allowed transitions: ${allowedTransitions.map((s) => s.toJson()).join(', ')}',
      );
    }
  }

  /// Validate timestamp logic for status transitions
  /// Ensures proper timestamp handling based on status changes
  void _validateTimestampLogic(
    WorkOrder currentWorkOrder,
    WorkOrderStatus newStatus,
  ) {
    final now = DateTime.now();

    switch (newStatus) {
      case WorkOrderStatus.inProgress:
        // When starting work, ensure we don't already have a start time
        // unless we're resuming from a previous start
        if (currentWorkOrder.status == WorkOrderStatus.pending &&
            currentWorkOrder.startTime != null) {
          throw StateError(
            'Work order ${currentWorkOrder.id} already has a start time but is in pending status',
          );
        }
        break;

      case WorkOrderStatus.completed:
        // When completing work, ensure we have a start time
        // if (currentWorkOrder.startTime == null) {
        //   throw StateError(
        //     'Cannot complete work order ${currentWorkOrder.id} without a start time. '
        //     'Work must be started before it can be completed.',
        //   );
        // }

        // Ensure completion time would be after start time
        // if (currentWorkOrder.startTime!.isAfter(now)) {
        //   throw StateError(
        //     'Cannot complete work order ${currentWorkOrder.id} before it was started',
        //   );
        // }
        break;

      case WorkOrderStatus.pending:
        // When resetting to pending, we'll clear timestamps
        // No specific validation needed here
        break;
    }
  }

  /// Get connection status from Ditto service
  Stream<bool> get connectionStatus => _dittoService.connectionStatus;

  /// Get sync status from Ditto service
  Stream<SyncStatus> get syncStatus => _dittoService.syncStatus;

  /// Force a manual sync operation
  Future<void> forceSync() async {
    try {
      await _dittoService.forceSync();
    } catch (e) {
      print('WorkOrderService: Failed to force sync - $e');
      if (e is NetworkOperationException) {
        // Re-throw network exceptions with additional context
        throw NetworkOperationException(
          'Unable to sync data: ${e.message}',
          e.originalError,
        );
      }
      if (e is OfflineOperationException) {
        // Re-throw offline exceptions with additional context
        throw OfflineOperationException(
          'Unable to sync data: ${e.message}',
          e.originalError,
        );
      }
      rethrow;
    }
  }

  /// Start sync operations
  Future<void> startSync() async {
    try {
      await _dittoService.startSync();
    } catch (e) {
      print('WorkOrderService: Failed to start sync - $e');
      rethrow;
    }
  }

  /// Stop sync operations
  Future<void> stopSync() async {
    try {
      await _dittoService.stopSync();
    } catch (e) {
      print('WorkOrderService: Failed to stop sync - $e');
      rethrow;
    }
  }

  /// Get work duration for a work order
  /// Returns the duration between start and completion times
  /// Returns null if work hasn't been started or completed
  Duration? getWorkDuration(WorkOrder workOrder) {
    if (workOrder.startTime == null || workOrder.completionTime == null) {
      return null;
    }
    return workOrder.completionTime!.difference(workOrder.startTime!);
  }

  /// Get elapsed time since work started
  /// Returns null if work hasn't been started
  Duration? getElapsedTime(WorkOrder workOrder) {
    if (workOrder.startTime == null) {
      return null;
    }

    final endTime = workOrder.completionTime ?? DateTime.now();
    return endTime.difference(workOrder.startTime!);
  }

  /// Check if a work order can be started
  /// Returns true if the work order is in pending status
  bool canStartWork(WorkOrder workOrder) {
    return workOrder.status == WorkOrderStatus.pending;
  }

  /// Check if a work order can be completed
  /// Returns true if the work order is in progress
  bool canCompleteWork(WorkOrder workOrder) {
    return workOrder.status == WorkOrderStatus.inProgress;
  }

  /// Check if a work order can be reset
  /// Returns true if the work order is not already pending
  bool canResetWork(WorkOrder workOrder) {
    return workOrder.status != WorkOrderStatus.pending;
  }

  /// Get connection information and statistics
  Map<String, dynamic> getConnectionInfo() {
    return _dittoService.getConnectionInfo();
  }

  /// Check if the service is currently offline
  bool get isOffline => _dittoService.isOffline;

  /// Check if the service has network connectivity
  bool get hasNetworkConnectivity => _dittoService.hasNetworkConnectivity;

  /// Get the number of pending sync operations
  // int get pendingSyncOperationsCount =>
  //     _dittoService.pendingSyncOperationsCount;

  /// Check if there are pending sync operations
  // bool get hasPendingSyncOperations => pendingSyncOperationsCount > 0;

  /// Dispose resources
  void dispose() {
    _dittoService.dispose();
  }
}
