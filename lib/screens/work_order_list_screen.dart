import 'package:flutter/material.dart';
import '../models/work_order.dart';
import '../services/work_order_service.dart';
import '../services/ditto_service.dart';
import '../services/sample_data_service.dart';
import '../widgets/demo_control_panel.dart';
import '../widgets/sync_event_indicator.dart';
import 'work_order_detail_screen.dart';

class WorkOrderListScreen extends StatefulWidget {
  const WorkOrderListScreen({super.key});

  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  final WorkOrderService _workOrderService = WorkOrderService();
  final SampleDataService _sampleDataService = SampleDataService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _workOrderService.initialize();
      await _sampleDataService.initializeSampleData();
      await _workOrderService.startSync();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshWorkOrders() async {
    try {
      await _workOrderService.forceSync();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Demo controls button
          IconButton(
            onPressed: () => _showDemoControls(context),
            icon: const Icon(Icons.settings),
            tooltip: 'Demo Controls',
          ),
          // Connection status indicator
          StreamBuilder<bool>(
            stream: _workOrderService.connectionStatus,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? false;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _ConnectionStatusIndicator(isConnected: isConnected),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Sync status indicator
              StreamBuilder<SyncStatus>(
                stream: _workOrderService.syncStatus,
                builder: (context, snapshot) {
                  final syncStatus = snapshot.data ?? SyncStatus.offline;
                  return _SyncStatusBanner(syncStatus: syncStatus);
                },
              ),
              // Work orders list
              Expanded(
                child: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshWorkOrders,
                  child: StreamBuilder<List<WorkOrder>>(
                    stream: _workOrderService.watchWorkOrders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading work orders',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshWorkOrders,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final workOrders = snapshot.data ?? [];

                      if (workOrders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No work orders found',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pull down to refresh',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: workOrders.length,
                        itemBuilder: (context, index) {
                          final workOrder = workOrders[index];
                          return _WorkOrderCard(
                            workOrder: workOrder,
                            onTap: () => _navigateToWorkOrderDetail(workOrder),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          // Sync event indicator overlay
          const SyncEventIndicator(),
        ],
      ),
    );
  }

  void _navigateToWorkOrderDetail(WorkOrder workOrder) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WorkOrderDetailScreen(workOrderId: workOrder.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showDemoControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: DemoControlPanel(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _workOrderService.dispose();
    super.dispose();
  }
}

class _WorkOrderCard extends StatefulWidget {
  final WorkOrder workOrder;
  final VoidCallback onTap;

  const _WorkOrderCard({required this.workOrder, required this.onTap});

  @override
  State<_WorkOrderCard> createState() => _WorkOrderCardState();
}

class _WorkOrderCardState extends State<_WorkOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Card(
              margin: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 8.0,
              ),
              elevation: _isPressed ? 8.0 : 2.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _isPressed ? Colors.grey[50] : Colors.white,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: _StatusBadge(status: widget.workOrder.status),
                  title: Text(
                    widget.workOrder.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        widget.workOrder.customerAddress,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.workOrder.problemDescription,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.build, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          // Text(
                          //   '${widget.workOrder.equipmentModel} (${widget.workOrder.equipmentSerial})',
                          //   style: TextStyle(
                          //     color: Colors.grey[600],
                          //     fontSize: 12,
                          //   ),
                          // ),
                          Expanded(
                            child: Text(
                              '${widget.workOrder.equipmentModel} (${widget.workOrder.equipmentSerial})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // Add this to show "..." when text is too long
                              maxLines:
                                  1, // Optional: ensure it stays on one line
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: AnimatedRotation(
                    turns: _isPressed ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WorkOrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case WorkOrderStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'Pending...';
        icon = Icons.schedule;
        break;
      case WorkOrderStatus.inProgress:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        text = 'In Progress';
        icon = Icons.play_circle_filled;
        break;
      case WorkOrderStatus.completed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Completed';
        icon = Icons.check_circle;
        break;
    }

    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatusIndicator extends StatefulWidget {
  final bool isConnected;

  const _ConnectionStatusIndicator({required this.isConnected});

  @override
  State<_ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<_ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ConnectionStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !oldWidget.isConnected) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isConnected && oldWidget.isConnected) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showConnectionDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isConnected
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isConnected ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.isConnected
                ? ScaleTransition(
                    scale: _pulseAnimation,
                    child: Icon(
                      Icons.cloud_done,
                      color: Colors.green,
                      size: 16,
                    ),
                  )
                : Icon(Icons.cloud_off, color: Colors.red, size: 16),
            const SizedBox(width: 4),
            Text(
              widget.isConnected ? 'Online' : 'Offline',
              style: TextStyle(
                color: widget.isConnected ? Colors.green : Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionDetails(BuildContext context) {
    final workOrderService = WorkOrderService();
    final connectionInfo = workOrderService.getConnectionInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: widget.isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(widget.isConnected ? 'Online' : 'Offline'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Network Status',
              widget.isConnected ? 'Connected' : 'Disconnected',
            ),
            _buildInfoRow(
              'Connectivity',
              connectionInfo['hasNetworkConnectivity'] == true
                  ? 'Available'
                  : 'Unavailable',
            ),
            _buildInfoRow(
              'Sync Status',
              connectionInfo['syncStatus'] ?? 'Unknown',
            ),
            _buildInfoRow(
              'Work Orders',
              '${connectionInfo['totalWorkOrders'] ?? 0}',
            ),
            _buildInfoRow(
              'Pending Sync',
              '${connectionInfo['pendingSyncOperations'] ?? 0} operations',
            ),
            if (connectionInfo['lastSyncTime'] != null)
              _buildInfoRow(
                'Last Sync',
                _formatDateTime(connectionInfo['lastSyncTime']),
              ),
          ],
        ),
        actions: [
          if (!widget.isConnected)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await workOrderService.forceSync();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sync completed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sync failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Force Sync'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _SyncStatusBanner extends StatefulWidget {
  final SyncStatus syncStatus;

  const _SyncStatusBanner({required this.syncStatus});

  @override
  State<_SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<_SyncStatusBanner>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.syncStatus == SyncStatus.syncing) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(_SyncStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.syncStatus == SyncStatus.syncing) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }

    if (widget.syncStatus == SyncStatus.synced &&
        oldWidget.syncStatus != SyncStatus.synced) {
      _lastSyncTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (widget.syncStatus) {
      case SyncStatus.syncing:
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[800]!;
        text = 'Syncing data...';
        icon = Icons.sync;
        break;
      case SyncStatus.synced:
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        final syncTime = _lastSyncTime ?? DateTime.now();
        text = 'Last synced: ${_formatTime(syncTime)}';
        icon = Icons.check_circle_outline;
        break;
      case SyncStatus.offline:
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        text = 'Working offline - Changes will sync when connected';
        icon = Icons.cloud_off;
        break;
      case SyncStatus.error:
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
        text = 'Sync error - Pull to retry';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          widget.syncStatus == SyncStatus.syncing
              ? RotationTransition(
                  turns: _animationController,
                  child: Icon(icon, color: textColor, size: 16),
                )
              : Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.syncStatus == SyncStatus.offline ||
              widget.syncStatus == SyncStatus.error)
            Icon(Icons.info_outline, color: textColor, size: 14),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
