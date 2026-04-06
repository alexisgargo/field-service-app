import 'package:flutter/material.dart';
import '../services/demo_utilities.dart';

/// Demo control panel widget for accessing demo utilities during presentations
class DemoControlPanel extends StatefulWidget {
  const DemoControlPanel({super.key});

  @override
  State<DemoControlPanel> createState() => _DemoControlPanelState();
}

class _DemoControlPanelState extends State<DemoControlPanel> {
  final DemoUtilities _demoUtils = DemoUtilities();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: const Text(
          'Demo Controls',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _demoUtils.isNetworkSimulationEnabled
              ? 'Network Simulation: ${_demoUtils.simulatedNetworkStatus ? "ONLINE" : "OFFLINE"}'
              : 'Network Simulation: Disabled',
        ),
        leading: const Icon(Icons.settings),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Demo Mode Toggle
                Card(
                  color: _demoUtils.isDemoModeEnabled
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          _demoUtils.isDemoModeEnabled
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _demoUtils.isDemoModeEnabled
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Demo Mode',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _demoUtils.isDemoModeEnabled
                                    ? 'Enhanced logging and visual indicators active'
                                    : 'Standard mode - tap to enable demo features',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _demoUtils.isDemoModeEnabled,
                          onChanged: (value) {
                            _demoUtils.toggleDemoMode();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Network Simulation Controls
                const Text(
                  'Network Simulation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _demoUtils.forceNetworkOffline();
                          setState(() {});
                        },
                        icon: const Icon(Icons.wifi_off),
                        label: const Text('Go Offline'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _demoUtils.forceNetworkOnline();
                          setState(() {});
                        },
                        icon: const Icon(Icons.wifi),
                        label: const Text('Go Online'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_demoUtils.isNetworkSimulationEnabled) {
                      _demoUtils.disableNetworkSimulation();
                    } else {
                      _demoUtils.enableNetworkSimulation();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    _demoUtils.isNetworkSimulationEnabled
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    _demoUtils.isNetworkSimulationEnabled
                        ? 'Disable Auto Simulation'
                        : 'Enable Auto Simulation',
                  ),
                ),

                const Divider(height: 24),

                // Data Controls
                const Text(
                  'Data Controls',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          try {
                            await _demoUtils.resetDemoData();
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Demo data reset successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to reset data: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          try {
                            // Quick demo setup
                            _demoUtils.enableDemoMode(
                              showSyncIndicators: true,
                              autoLogEvents: true,
                              enableNetworkSimulation: true,
                            );
                            await _demoUtils.resetDemoData();

                            // Emit a demo event to show the indicator
                            _demoUtils.emitSyncEvent(
                              SyncEventType.syncCompleted,
                              'Demo setup completed - ready for presentation!',
                            );

                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Demo setup completed!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {});
                            }
                          } catch (e) {
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Demo setup failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.play_circle_filled),
                        label: const Text('Quick Setup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Demo Scenarios
                const Text(
                  'Demo Scenarios',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DemoScenario.values.map((scenario) {
                    return ElevatedButton(
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        try {
                          await _demoUtils.startDemoScenario(scenario);
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('${scenario.name} completed'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('${scenario.name} failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(scenario.name),
                    );
                  }).toList(),
                ),

                const Divider(height: 24),

                // Demo Logs
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Demo Logs',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showDemoLogs(context);
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Logs'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _demoUtils.clearDemoLogs();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Demo logs cleared')),
                        );
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoLogs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DemoLogsDialog(demoUtils: _demoUtils),
    );
  }
}

/// Dialog for displaying demo logs
class DemoLogsDialog extends StatelessWidget {
  final DemoUtilities demoUtils;

  const DemoLogsDialog({super.key, required this.demoUtils});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Demo Logs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<DemoLogEntry>>(
                stream: demoUtils.demoLogsStream,
                initialData: demoUtils.demoLogs,
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? [];

                  if (logs.isEmpty) {
                    return const Center(child: Text('No demo logs available'));
                  }

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log =
                          logs[logs.length - 1 - index]; // Reverse order
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: log.isError ? Colors.red.shade50 : null,
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            log.isError ? Icons.error : Icons.info,
                            color: log.isError ? Colors.red : Colors.blue,
                            size: 16,
                          ),
                          title: Text(
                            log.message,
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            '${log.category} • ${_formatTimestamp(log.timestamp)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final logs = demoUtils.exportDemoLogs();
                      _showExportDialog(context, logs);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export Logs'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    demoUtils.clearDemoLogs();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  void _showExportDialog(BuildContext context, String logs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported Demo Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              logs,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
