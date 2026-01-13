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

class QslCardGeneratorApp extends StatelessWidget {
  final StorageService storageService;

  const QslCardGeneratorApp({super.key, required this.storageService});

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
      home: GeneratorScreen(storageService: storageService),
    );
  }
}
