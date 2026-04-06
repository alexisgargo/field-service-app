import 'package:flutter/material.dart';
import '../services/demo_utilities.dart';

/// Widget that displays visual indicators for sync events during demos
class SyncEventIndicator extends StatefulWidget {
  const SyncEventIndicator({super.key});

  @override
  State<SyncEventIndicator> createState() => _SyncEventIndicatorState();
}

class _SyncEventIndicatorState extends State<SyncEventIndicator>
    with TickerProviderStateMixin {
  final DemoUtilities _demoUtils = DemoUtilities();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  SyncEvent? _currentEvent;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Listen to sync events
    _demoUtils.syncEventsStream.listen(_handleSyncEvent);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleSyncEvent(SyncEvent event) {
    if (!_demoUtils.isDemoModeEnabled || !_demoUtils.showSyncIndicators) {
      return;
    }

    setState(() {
      _currentEvent = event;
      _isVisible = true;
    });

    // Reset animations
    _slideController.reset();
    _fadeController.reset();

    // Start slide in animation
    _slideController.forward();

    // Start fade out after a delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isVisible) {
        _fadeController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentEvent == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _SyncEventCard(event: _currentEvent!),
        ),
      ),
    );
  }
}

class _SyncEventCard extends StatelessWidget {
  final SyncEvent event;

  const _SyncEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _getEventColor(event.type);
    final icon = _getEventIcon(event.type);

    return Card(
      elevation: 8,
      shadowColor: color.withValues(alpha: 0.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.type.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.message,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTime(event.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor(SyncEventType type) {
    switch (type) {
      case SyncEventType.syncStarted:
        return Colors.blue;
      case SyncEventType.syncCompleted:
        return Colors.green;
      case SyncEventType.syncError:
        return Colors.red;
      case SyncEventType.wentOffline:
        return Colors.orange;
      case SyncEventType.wentOnline:
        return Colors.green;
      case SyncEventType.dataChanged:
        return Colors.purple;
    }
  }

  IconData _getEventIcon(SyncEventType type) {
    switch (type) {
      case SyncEventType.syncStarted:
        return Icons.sync;
      case SyncEventType.syncCompleted:
        return Icons.check_circle;
      case SyncEventType.syncError:
        return Icons.error;
      case SyncEventType.wentOffline:
        return Icons.cloud_off;
      case SyncEventType.wentOnline:
        return Icons.cloud_done;
      case SyncEventType.dataChanged:
        return Icons.update;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
