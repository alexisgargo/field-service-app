import 'package:flutter/material.dart';
import '../models/work_order.dart';
import '../services/work_order_service.dart';

class WorkOrderDetailScreen extends StatefulWidget {
  final String workOrderId;

  const WorkOrderDetailScreen({super.key, required this.workOrderId});

  @override
  State<WorkOrderDetailScreen> createState() => _WorkOrderDetailScreenState();
}

class _WorkOrderDetailScreenState extends State<WorkOrderDetailScreen> {
  final WorkOrderService _workOrderService = WorkOrderService();
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<WorkOrder?>(
        stream: _workOrderService.watchWorkOrderById(widget.workOrderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading work order',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final workOrder = snapshot.data;
          if (workOrder == null) {
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
                    'Work order not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    _StatusCard(workOrder: workOrder),
                    const SizedBox(height: 16),

                    // Customer Information
                    _CustomerInfoCard(workOrder: workOrder),
                    const SizedBox(height: 16),

                    // Equipment Details
                    _EquipmentDetailsCard(workOrder: workOrder),
                    const SizedBox(height: 16),

                    // Problem Description
                    _ProblemDescriptionCard(workOrder: workOrder),
                    const SizedBox(height: 16),

                    // Timestamps
                    _TimestampsCard(workOrder: workOrder),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _ActionButtons(
                      workOrder: workOrder,
                      isUpdating: _isUpdating,
                      onStartWork: () => _startWork(workOrder),
                      onCompleteWork: () => _completeWork(workOrder),
                    ),
                  ],
                ),
              ),
              if (_isUpdating) _LoadingOverlay(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startWork(WorkOrder workOrder) async {
    print("starting work");

    if (_isUpdating) return;
    print("starting work2");

    setState(() {
      _isUpdating = true;
    });

    try {
      await _workOrderService.startWork(workOrder.id);
      if (mounted) {
        _showSuccessSnackBar('Work started successfully', Icons.play_arrow);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to start work: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _completeWork(WorkOrder workOrder) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _workOrderService.completeWork(workOrder.id);
      if (mounted) {
        _showSuccessSnackBar('Work completed successfully', Icons.check_circle);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to complete work: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final WorkOrder workOrder;

  const _StatusCard({required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _StatusBadge(status: workOrder.status),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDisplayText(workOrder.status),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayText(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.pending:
        return 'Pending';
      case WorkOrderStatus.inProgress:
        return 'In Progress';
      case WorkOrderStatus.completed:
        return 'Completed';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final WorkOrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case WorkOrderStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.schedule;
        break;
      case WorkOrderStatus.inProgress:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.play_circle_filled;
        break;
      case WorkOrderStatus.completed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: textColor, size: 32),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final WorkOrder workOrder;

  const _CustomerInfoCard({required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Name',
              value: workOrder.customerName,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Address',
              value: workOrder.customerAddress,
              icon: Icons.location_on_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentDetailsCard extends StatelessWidget {
  final WorkOrder workOrder;

  const _EquipmentDetailsCard({required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Equipment Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Model',
              value: workOrder.equipmentModel,
              icon: Icons.precision_manufacturing,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Serial Number',
              value: workOrder.equipmentSerial,
              icon: Icons.qr_code,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemDescriptionCard extends StatelessWidget {
  final WorkOrder workOrder;

  const _ProblemDescriptionCard({required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Problem Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                workOrder.problemDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimestampsCard extends StatelessWidget {
  final WorkOrder workOrder;

  const _TimestampsCard({required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Timestamps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Created',
              value: _formatDateTime(workOrder.createdAt),
              icon: Icons.add_circle_outline,
            ),
            if (workOrder.startTime != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Started',
                value: _formatDateTime(workOrder.startTime!),
                icon: Icons.play_circle_outline,
              ),
            ],
            if (workOrder.completionTime != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Completed',
                value: _formatDateTime(workOrder.completionTime!),
                icon: Icons.check_circle_outline,
              ),
            ],
            if (workOrder.startTime != null &&
                workOrder.completionTime != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Duration',
                value: _formatDuration(
                  workOrder.completionTime!.difference(workOrder.startTime!),
                ),
                icon: Icons.timer_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatefulWidget {
  final WorkOrder workOrder;
  final bool isUpdating;
  final VoidCallback onStartWork;
  final VoidCallback onCompleteWork;

  const _ActionButtons({
    required this.workOrder,
    required this.isUpdating,
    required this.onStartWork,
    required this.onCompleteWork,
  });

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isUpdating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUpdating && !oldWidget.isUpdating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isUpdating && oldWidget.isUpdating) {
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
    final workOrderService = WorkOrderService();
    final canStart = workOrderService.canStartWork(widget.workOrder);
    final canComplete = workOrderService.canCompleteWork(widget.workOrder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canStart)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isUpdating ? _pulseAnimation.value : 1.0,
                child: _AnimatedButton(
                  onPressed: widget.isUpdating ? null : widget.onStartWork,
                  icon: widget.isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(widget.isUpdating ? 'Starting...' : 'Start Work'),
                  backgroundColor: Colors.blue,
                  isLoading: widget.isUpdating,
                ),
              );
            },
          ),
        if (canComplete) ...[
          if (canStart) const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isUpdating ? _pulseAnimation.value : 1.0,
                child: _AnimatedButton(
                  onPressed: widget.isUpdating ? null : widget.onCompleteWork,
                  icon: widget.isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    widget.isUpdating ? 'Completing...' : 'Complete Work',
                  ),
                  backgroundColor: Colors.green,
                  isLoading: widget.isUpdating,
                ),
              );
            },
          ),
        ],
        if (!canStart && !canComplete)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.workOrder.status == WorkOrderStatus.completed
                        ? 'This work order has been completed'
                        : 'No actions available for current status',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final Color backgroundColor;
  final bool isLoading;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.isLoading = false,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton.icon(
            onPressed: widget.onPressed,
            onLongPress: widget.onPressed != null
                ? () {
                    _controller.forward().then((_) {
                      _controller.reverse();
                    });
                    widget.onPressed?.call();
                  }
                : null,
            icon: widget.icon,
            label: widget.label,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: widget.isLoading ? 8.0 : 2.0,
              shadowColor: widget.backgroundColor.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingOverlay extends StatefulWidget {
  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Updating work order...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
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
