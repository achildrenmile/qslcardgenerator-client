import 'package:flutter/material.dart';
import 'services/services.dart';
import 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  runApp(QslCardGeneratorApp(storageService: storageService));
}

class QslCardGeneratorApp extends StatefulWidget {
  final StorageService storageService;

  const QslCardGeneratorApp({super.key, required this.storageService});

  @override
  State<QslCardGeneratorApp> createState() => _QslCardGeneratorAppState();
}

class _QslCardGeneratorAppState extends State<QslCardGeneratorApp> {
  late bool _setupComplete;

  @override
  void initState() {
    super.initState();
    _setupComplete = widget.storageService.isSetupComplete();
  }

  void _onSetupComplete() {
    setState(() {
      _setupComplete = true;
    });
  }

  void _onResetSetup() {
    setState(() {
      _setupComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QSL Card Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3b82f6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _setupComplete
          ? GeneratorScreen(
              storageService: widget.storageService,
              onResetSetup: _onResetSetup,
            )
          : SetupScreen(
              storageService: widget.storageService,
              onSetupComplete: _onSetupComplete,
            ),
    );
  }
}
