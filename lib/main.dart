import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'services/services.dart';
import 'screens/screens.dart';

Future<String?> _extractIcon() async {
  try {
    final byteData = await rootBundle.load('assets/icon/app_icon.png');
    final appDir = await getApplicationSupportDirectory();
    final iconFile = File('${appDir.path}/app_icon.png');
    await iconFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return iconFile.path;
  } catch (e) {
    debugPrint('Failed to extract icon: $e');
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop platforms
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // Extract icon before showing window
    final iconPath = await _extractIcon();

    const windowOptions = WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(800, 600),
      center: true,
      title: 'QSL Card Generator',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (iconPath != null) {
        await windowManager.setIcon(iconPath);
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
