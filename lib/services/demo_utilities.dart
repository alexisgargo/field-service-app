import 'dart:async';
import 'dart:math';
import 'ditto_service.dart';
import 'sample_data_service.dart';

/// Utility class for demo-specific functionality including network simulation,
/// data reset, and enhanced logging for demo visibility
class DemoUtilities {
  static final DemoUtilities _instance = DemoUtilities._internal();
  factory DemoUtilities() => _instance;
  DemoUtilities._internal();

  final DittoService _dittoService = DittoService();
  final SampleDataService _sampleDataService = SampleDataService();

  // Demo mode state
  bool _demoModeEnabled = false;
  bool _showSyncIndicators = true;
  bool _autoLogEvents = true;

  // Network simulation state
  bool _networkSimulationEnabled = false;
  bool _simulatedNetworkStatus = true;
  Timer? _networkSimulationTimer;

  // Demo logging
  final List<DemoLogEntry> _demoLogs = [];
  final StreamController<List<DemoLogEntry>> _demoLogsController =
      StreamController<List<DemoLogEntry>>.broadcast();

  // Sync event indicators
  final StreamController<SyncEvent> _syncEventsController =
      StreamController<SyncEvent>.broadcast();

  // Getters
  bool get isDemoModeEnabled => _demoModeEnabled;
  bool get showSyncIndicators => _showSyncIndicators;
  bool get autoLogEvents => _autoLogEvents;
  bool get isNetworkSimulationEnabled => _networkSimulationEnabled;
  bool get simulatedNetworkStatus => _simulatedNetworkStatus;
  List<DemoLogEntry> get demoLogs => List.unmodifiable(_demoLogs);
  Stream<List<DemoLogEntry>> get demoLogsStream => _demoLogsController.stream;
  Stream<SyncEvent> get syncEventsStream => _syncEventsController.stream;

  /// Enable demo mode for presentations
  void enableDemoMode({
    bool showSyncIndicators = true,
    bool autoLogEvents = true,
    bool enableNetworkSimulation = false,
  }) {
    _demoModeEnabled = true;
    _showSyncIndicators = showSyncIndicators;
    _autoLogEvents = autoLogEvents;

    logDemoEvent(
      'Demo Mode',
      'Demo mode enabled (sync indicators: $showSyncIndicators, auto logging: $autoLogEvents)',
    );

    if (enableNetworkSimulation) {
      this.enableNetworkSimulation();
    }

    // Start monitoring sync events for visual indicators
    _startSyncEventMonitoring();
  }

  /// Disable demo mode
  void disableDemoMode() {
    _demoModeEnabled = false;
    _showSyncIndicators = false;
    _autoLogEvents = false;

    logDemoEvent('Demo Mode', 'Demo mode disabled');

    disableNetworkSimulation();
    _stopSyncEventMonitoring();
  }

  /// Toggle demo mode
  void toggleDemoMode() {
    if (_demoModeEnabled) {
      disableDemoMode();
    } else {
      enableDemoMode();
    }
  }

  /// Configure demo mode settings
  void configureDemoMode({bool? showSyncIndicators, bool? autoLogEvents}) {
    if (showSyncIndicators != null) {
      _showSyncIndicators = showSyncIndicators;
    }
    if (autoLogEvents != null) {
      _autoLogEvents = autoLogEvents;
    }

    logDemoEvent(
      'Demo Mode',
      'Demo mode configured (sync indicators: $_showSyncIndicators, auto logging: $_autoLogEvents)',
    );
  }

  /// Start monitoring sync events for visual indicators
  void _startSyncEventMonitoring() {
    if (!_demoModeEnabled || !_showSyncIndicators) return;

    // Listen to Ditto sync status changes and emit visual events
    _dittoService.syncStatus.listen((syncStatus) {
      final event = SyncEvent(
        type: _mapSyncStatusToEventType(syncStatus),
        timestamp: DateTime.now(),
        message: _getSyncStatusMessage(syncStatus),
      );

      _syncEventsController.add(event);

      if (_autoLogEvents) {
        logDemoEvent('Sync Event', event.message);
      }
    });
  }

  /// Stop monitoring sync events
  void _stopSyncEventMonitoring() {
    // In a real implementation, we would cancel the subscription
    // For now, we just stop emitting events by checking the flags
  }

  /// Map sync status to event type
  SyncEventType _mapSyncStatusToEventType(SyncStatus syncStatus) {
    switch (syncStatus) {
      case SyncStatus.syncing:
        return SyncEventType.syncStarted;
      case SyncStatus.synced:
        return SyncEventType.syncCompleted;
      case SyncStatus.offline:
        return SyncEventType.wentOffline;
      case SyncStatus.error:
        return SyncEventType.syncError;
    }
  }

  /// Get user-friendly message for sync status
  String _getSyncStatusMessage(SyncStatus syncStatus) {
    switch (syncStatus) {
      case SyncStatus.syncing:
        return 'Synchronizing data with backend...';
      case SyncStatus.synced:
        return 'Data synchronized successfully';
      case SyncStatus.offline:
        return 'Working offline - changes will sync when connected';
      case SyncStatus.error:
        return 'Sync error occurred - will retry automatically';
    }
  }

  /// Emit a custom sync event for demo purposes
  void emitSyncEvent(SyncEventType type, String message) {
    if (!_demoModeEnabled || !_showSyncIndicators) return;

    final event = SyncEvent(
      type: type,
      timestamp: DateTime.now(),
      message: message,
    );

    _syncEventsController.add(event);

    if (_autoLogEvents) {
      logDemoEvent('Custom Sync Event', message);
    }
  }

  /// Reset all demo data to fresh sample data
  Future<void> resetDemoData() async {
    try {
      logDemoEvent('Demo Reset', 'Starting demo data reset...');

      await _sampleDataService.resetSampleData();

      logDemoEvent('Demo Reset', 'Demo data reset completed successfully');
    } catch (e) {
      logDemoEvent(
        'Demo Reset',
        'Failed to reset demo data: $e',
        isError: true,
      );
      rethrow;
    }
  }

  /// Enable network simulation for demo purposes
  void enableNetworkSimulation({
    Duration? intervalDuration,
    double offlineProbability = 0.3,
  }) {
    if (_networkSimulationEnabled) {
      disableNetworkSimulation();
    }

    _networkSimulationEnabled = true;
    final interval =
        intervalDuration ?? const Duration(seconds: 100000000000000);

    // logDemoEvent(
    //   'Network Simulation',
    //   'Enabled network simulation (${interval.inSeconds}s intervals, ${(offlineProbability * 100).toInt()}% offline probability)',
    // );

    // _networkSimulationTimer = Timer.periodic(interval, (timer) {
    //   final random = Random();
    //   final shouldGoOffline = random.nextDouble() < offlineProbability;

    //   if (shouldGoOffline != !_simulatedNetworkStatus) {
    //     _simulatedNetworkStatus = !shouldGoOffline;
    //     _simulateNetworkChange(_simulatedNetworkStatus);
    //   }
    // });
  }

  /// Disable network simulation
  void disableNetworkSimulation() {
    if (!_networkSimulationEnabled) return;

    _networkSimulationEnabled = false;
    _networkSimulationTimer?.cancel();
    _networkSimulationTimer = null;

    // Restore normal network status
    _simulatedNetworkStatus = true;

    logDemoEvent(
      'Network Simulation',
      'Disabled network simulation - restored normal connectivity',
    );
  }

  /// Manually toggle network status for demo
  void toggleNetworkStatus() {
    if (!_networkSimulationEnabled) {
      enableNetworkSimulation();
    }

    // _simulatedNetworkStatus = !_simulatedNetworkStatus;
    // _simulateNetworkChange(_simulatedNetworkStatus);

    logDemoEvent(
      'Network Simulation',
      'Manually toggled network to ${_simulatedNetworkStatus ? "ONLINE" : "OFFLINE"}',
    );
  }

  /// Force network offline for demo
  void forceNetworkOffline() {
    if (!_networkSimulationEnabled) {
      enableNetworkSimulation();
    }

    _simulatedNetworkStatus = false;
    _simulateNetworkChange(false);

    logDemoEvent('Network Simulation', 'Forced network OFFLINE for demo');
  }

  /// Force network online for demo
  void forceNetworkOnline() {
    if (!_networkSimulationEnabled) {
      enableNetworkSimulation();
    }

    _simulatedNetworkStatus = true;
    _simulateNetworkChange(true);

    logDemoEvent('Network Simulation', 'Forced network ONLINE for demo');
  }

  /// Simulate network connectivity change
  void _simulateNetworkChange(bool isOnline) async {
    // In a real implementation, this would interact with the Ditto service
    // to simulate network connectivity changes

    if (!isOnline) {
      await _dittoService.stopSync();
    } else {
      await _dittoService.startSync();
    }

    logDemoEvent(
      'Network Status',
      'Network status changed to ${isOnline ? "ONLINE" : "OFFLINE"}',
    );

    // Trigger sync operations if coming back online
    if (isOnline && _dittoService.isInitialized) {
      _dittoService.forceSync().catchError((e) {
        logDemoEvent(
          'Sync Operation',
          'Sync failed after network restore: $e',
          isError: true,
        );
      });
    }
  }

  /// Log a demo event for visibility during presentations
  void logDemoEvent(String category, String message, {bool isError = false}) {
    final logEntry = DemoLogEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
      isError: isError,
    );

    _demoLogs.add(logEntry);

    // Keep only the last 100 log entries to prevent memory issues
    if (_demoLogs.length > 100) {
      _demoLogs.removeAt(0);
    }

    // Notify listeners
    _demoLogsController.add(List.unmodifiable(_demoLogs));

    // Also print to console for development (demo purposes)
    final prefix = isError ? '[ERROR]' : '[DEMO]';
    // ignore: avoid_print
    print('$prefix [$category] $message');
  }

  /// Get demo statistics for display
  Map<String, dynamic> getDemoStatistics() {
    final connectionInfo = _dittoService.getConnectionInfo();

    return {
      'networkSimulationEnabled': _networkSimulationEnabled,
      'simulatedNetworkStatus': _simulatedNetworkStatus ? 'ONLINE' : 'OFFLINE',
      'totalLogEntries': _demoLogs.length,
      'errorLogEntries': _demoLogs.where((log) => log.isError).length,
      'lastLogTime': _demoLogs.isNotEmpty
          ? _demoLogs.last.timestamp.toIso8601String()
          : null,
      'dittoConnectionInfo': connectionInfo,
    };
  }

  /// Clear demo logs
  void clearDemoLogs() {
    _demoLogs.clear();
    _demoLogsController.add([]);
    logDemoEvent('Demo Logs', 'Demo logs cleared');
  }

  /// Export demo logs as a formatted string
  String exportDemoLogs() {
    if (_demoLogs.isEmpty) {
      return 'No demo logs available';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== DEMO LOGS EXPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Entries: ${_demoLogs.length}');
    buffer.writeln('');

    for (final log in _demoLogs) {
      final timestamp = log.timestamp.toIso8601String();
      final prefix = log.isError ? '[ERROR]' : '[INFO]';
      buffer.writeln('$timestamp $prefix [${log.category}] ${log.message}');
    }

    return buffer.toString();
  }

  /// Start a demo scenario with predefined actions
  Future<void> startDemoScenario(DemoScenario scenario) async {
    logDemoEvent('Demo Scenario', 'Starting scenario: ${scenario.name}');

    try {
      switch (scenario) {
        case DemoScenario.offlineWorkflow:
          await _runOfflineWorkflowScenario();
          break;
        case DemoScenario.syncDemo:
          await _runSyncDemoScenario();
          break;
        case DemoScenario.multiDeviceSync:
          await _runMultiDeviceSyncScenario();
          break;
        case DemoScenario.dataReset:
          await _runDataResetScenario();
          break;
      }

      logDemoEvent('Demo Scenario', 'Completed scenario: ${scenario.name}');
    } catch (e) {
      logDemoEvent(
        'Demo Scenario',
        'Failed scenario ${scenario.name}: $e',
        isError: true,
      );
      rethrow;
    }
  }

  /// Run offline workflow demo scenario
  Future<void> _runOfflineWorkflowScenario() async {
    logDemoEvent('Offline Demo', 'Demonstrating offline functionality...');

    // Force offline
    forceNetworkOffline();
    await Future.delayed(const Duration(seconds: 2));

    // Simulate some work order updates while offline
    logDemoEvent('Offline Demo', 'Simulating work order updates while offline');

    // Force back online after demo
    await Future.delayed(const Duration(seconds: 5));
    forceNetworkOnline();

    logDemoEvent('Offline Demo', 'Offline workflow demonstration completed');
  }

  /// Run sync demonstration scenario
  Future<void> _runSyncDemoScenario() async {
    logDemoEvent('Sync Demo', 'Demonstrating data synchronization...');

    // Start offline
    forceNetworkOffline();
    await Future.delayed(const Duration(seconds: 2));

    logDemoEvent('Sync Demo', 'Making changes while offline...');
    await Future.delayed(const Duration(seconds: 3));

    // Come back online and trigger sync
    forceNetworkOnline();
    logDemoEvent('Sync Demo', 'Network restored - triggering sync...');

    await Future.delayed(const Duration(seconds: 2));
    logDemoEvent('Sync Demo', 'Sync demonstration completed');
  }

  /// Run multi-device sync scenario
  Future<void> _runMultiDeviceSyncScenario() async {
    logDemoEvent(
      'Multi-Device Demo',
      'Simulating multi-device synchronization...',
    );

    // Simulate changes from another device
    logDemoEvent('Multi-Device Demo', 'Simulating changes from Device B...');
    await Future.delayed(const Duration(seconds: 2));

    logDemoEvent('Multi-Device Demo', 'Changes synchronized to this device');
    await Future.delayed(const Duration(seconds: 1));

    logDemoEvent(
      'Multi-Device Demo',
      'Multi-device sync demonstration completed',
    );
  }

  /// Run data reset scenario
  Future<void> _runDataResetScenario() async {
    logDemoEvent(
      'Data Reset Demo',
      'Demonstrating data reset functionality...',
    );

    await resetDemoData();
    await Future.delayed(const Duration(seconds: 1));

    logDemoEvent('Data Reset Demo', 'Data reset demonstration completed');
  }

  /// Dispose resources
  void dispose() {
    _networkSimulationTimer?.cancel();
    _demoLogsController.close();
    _syncEventsController.close();
  }
}

/// Demo log entry for tracking demo events
class DemoLogEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final bool isError;

  const DemoLogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.isError = false,
  });

  @override
  String toString() {
    final prefix = isError ? '[ERROR]' : '[INFO]';
    return '${timestamp.toIso8601String()} $prefix [$category] $message';
  }
}

/// Predefined demo scenarios
enum DemoScenario {
  offlineWorkflow('Offline Workflow'),
  syncDemo('Sync Demonstration'),
  multiDeviceSync('Multi-Device Sync'),
  dataReset('Data Reset');

  const DemoScenario(this.name);
  final String name;
}

/// Sync event for visual indicators during demos
class SyncEvent {
  final SyncEventType type;
  final DateTime timestamp;
  final String message;

  const SyncEvent({
    required this.type,
    required this.timestamp,
    required this.message,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} [${type.name}] $message';
  }
}

/// Types of sync events for visual indicators
enum SyncEventType {
  syncStarted('Sync Started'),
  syncCompleted('Sync Completed'),
  syncError('Sync Error'),
  wentOffline('Went Offline'),
  wentOnline('Went Online'),
  dataChanged('Data Changed');

  const SyncEventType(this.displayName);
  final String displayName;
}
