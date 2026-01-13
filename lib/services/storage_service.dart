import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _configKey = 'card_configs';
  static const String _activeConfigKey = 'active_config_id';
  static const String _setupCompleteKey = 'setup_complete';

  late SharedPreferences _prefs;
  late Directory _appDir;
  late Directory _backgroundsDir;
  late Directory _templatesDir;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _appDir = await getApplicationDocumentsDirectory();

    _backgroundsDir = Directory('${_appDir.path}/qsl_backgrounds');
    _templatesDir = Directory('${_appDir.path}/qsl_templates');

    if (!await _backgroundsDir.exists()) {
      await _backgroundsDir.create(recursive: true);
    }
    if (!await _templatesDir.exists()) {
      await _templatesDir.create(recursive: true);
    }
  }

  // Card Config Management
  Future<List<CardConfig>> getConfigs() async {
    final jsonString = _prefs.getString(_configKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => CardConfig.fromJson(json)).toList();
  }

  Future<void> saveConfigs(List<CardConfig> configs) async {
    final jsonString = jsonEncode(configs.map((c) => c.toJson()).toList());
    await _prefs.setString(_configKey, jsonString);
  }

  Future<CardConfig?> getActiveConfig() async {
    final configs = await getConfigs();
    final activeId = _prefs.getInt(_activeConfigKey);

    if (activeId == null && configs.isNotEmpty) {
      return configs.first;
    }

    return configs.where((c) => c.id == activeId).firstOrNull;
  }

  Future<void> setActiveConfig(int configId) async {
    await _prefs.setInt(_activeConfigKey, configId);
  }

  Future<CardConfig> createConfig(CardConfig config) async {
    final configs = await getConfigs();
    final newId = configs.isEmpty
        ? 1
        : configs.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;

    final newConfig = config.copyWith(id: newId);
    configs.add(newConfig);
    await saveConfigs(configs);
    return newConfig;
  }

  Future<void> updateConfig(CardConfig config) async {
    final configs = await getConfigs();
    final index = configs.indexWhere((c) => c.id == config.id);

    if (index != -1) {
      configs[index] = config.copyWith(updatedAt: DateTime.now());
      await saveConfigs(configs);
    }
  }

  Future<void> deleteConfig(int configId) async {
    final configs = await getConfigs();
    configs.removeWhere((c) => c.id == configId);
    await saveConfigs(configs);
  }

  // Background Image Management
  Directory get backgroundsDirectory => _backgroundsDir;
  Directory get templatesDirectory => _templatesDir;

  Future<List<File>> getBackgrounds() async {
    final files = await _backgroundsDir.list().toList();
    return files
        .whereType<File>()
        .where((f) => _isImageFile(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  Future<File> saveBackground(File sourceFile) async {
    final fileName = sourceFile.path.split('/').last;
    final destPath = '${_backgroundsDir.path}/$fileName';
    return sourceFile.copy(destPath);
  }

  Future<void> deleteBackground(String fileName) async {
    final file = File('${_backgroundsDir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Template Image Management
  Future<List<File>> getTemplates() async {
    final files = await _templatesDir.list().toList();
    return files
        .whereType<File>()
        .where((f) => _isImageFile(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  Future<File> saveTemplate(File sourceFile, String callsign) async {
    final ext = sourceFile.path.split('.').last;
    final destPath = '${_templatesDir.path}/${callsign.toLowerCase()}.$ext';
    return sourceFile.copy(destPath);
  }

  bool _isImageFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  // Setup Management
  bool isSetupComplete() {
    return _prefs.getBool(_setupCompleteKey) ?? false;
  }

  Future<void> setSetupComplete(bool complete) async {
    await _prefs.setBool(_setupCompleteKey, complete);
  }

  Future<void> resetSetup() async {
    await _prefs.remove(_setupCompleteKey);
    await _prefs.remove(_configKey);
    await _prefs.remove(_activeConfigKey);
  }

  // Get template for a specific callsign
  Future<File?> getTemplate(String callsign) async {
    final templates = await getTemplates();
    final lowerCallsign = callsign.toLowerCase();

    for (final template in templates) {
      final fileName = template.path.split('/').last;
      final baseName = fileName.split('.').first;
      if (baseName == lowerCallsign) {
        return template;
      }
    }
    return null;
  }
}
