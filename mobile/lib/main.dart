import 'package:flutter/material.dart';
import 'screens/work_order_list_screen.dart';
import 'services/ditto_service.dart';
import 'services/sample_data_service.dart';
import 'services/demo_utilities.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Ditto service and sample data on app startup
  await _initializeApp();

  runApp(const FieldServiceApp());
}

/// Initialize the app with Ditto service and sample data
Future<void> _initializeApp() async {
  final demoUtils = DemoUtilities();

  try {
    demoUtils.logDemoEvent(
      'App Startup',
      'Initializing Field Service Demo App...',
    );

    // Initialize Ditto service
    final dittoService = DittoService();
    await dittoService.initialize();
    await dittoService.startSync();

    demoUtils.logDemoEvent(
      'App Startup',
      'Ditto service initialized and sync started',
    );

    // Initialize sample data (only if no data exists)
    final sampleDataService = SampleDataService();
    await sampleDataService.initializeSampleData();

    demoUtils.logDemoEvent(
      'App Startup',
      'Sample data initialization completed',
    );
    demoUtils.logDemoEvent(
      'App Startup',
      'App initialization completed successfully',
    );
  } catch (e) {
    demoUtils.logDemoEvent(
      'App Startup',
      'Failed to initialize app: $e',
      isError: true,
    );
    // App will still start but may not have sample data
  }
}

class FieldServiceApp extends StatelessWidget {
  const FieldServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field Service Work Orders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WorkOrderListScreen(),
    );
  }
}
