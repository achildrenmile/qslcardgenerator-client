import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
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
  late Directory _logosDir;
  late Directory _additionalLogosDir;
  late Directory _signaturesDir;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _appDir = await getApplicationDocumentsDirectory();

    _backgroundsDir = Directory(p.join(_appDir.path, 'qsl_backgrounds'));
    _templatesDir = Directory(p.join(_appDir.path, 'qsl_templates'));
    _logosDir = Directory(p.join(_appDir.path, 'qsl_logos'));
    _additionalLogosDir = Directory(p.join(_appDir.path, 'qsl_additional_logos'));
    _signaturesDir = Directory(p.join(_appDir.path, 'qsl_signatures'));

    if (!await _backgroundsDir.exists()) {
      await _backgroundsDir.create(recursive: true);
    }
    // Copy default background if backgrounds directory is empty
    await _copyDefaultBackgroundIfNeeded();
    if (!await _templatesDir.exists()) {
      await _templatesDir.create(recursive: true);
    }
    if (!await _logosDir.exists()) {
      await _logosDir.create(recursive: true);
    }
    if (!await _additionalLogosDir.exists()) {
      await _additionalLogosDir.create(recursive: true);
    }
    if (!await _signaturesDir.exists()) {
      await _signaturesDir.create(recursive: true);
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
  Directory get logosDirectory => _logosDir;
  Directory get signaturesDirectory => _signaturesDir;

  Future<List<File>> getBackgrounds() async {
    final files = await _backgroundsDir.list().toList();
    return files
        .whereType<File>()
        .where((f) => _isImageFile(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  Future<File> saveBackground(File sourceFile) async {
    final fileName = p.basename(sourceFile.path);
    final destPath = p.join(_backgroundsDir.path, fileName);
    return sourceFile.copy(destPath);
  }

  Future<void> deleteBackground(String fileName) async {
    final file = File(p.join(_backgroundsDir.path, fileName));
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
    final ext = p.extension(sourceFile.path);
    final destPath = p.join(_templatesDir.path, '${callsign.toLowerCase()}$ext');
    return sourceFile.copy(destPath);
  }

  // Logo Image Management
  Future<List<File>> getLogos() async {
    final files = await _logosDir.list().toList();
    return files
        .whereType<File>()
        .where((f) => _isImageFile(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  Future<File> saveLogo(File sourceFile, String callsign) async {
    final ext = p.extension(sourceFile.path);
    final destPath = p.join(_logosDir.path, '${callsign.toLowerCase()}$ext');
    return sourceFile.copy(destPath);
  }

  Future<void> deleteLogo(String callsign) async {
    final logos = await getLogos();
    for (final logo in logos) {
      final baseName = p.basenameWithoutExtension(logo.path);
      if (baseName == callsign.toLowerCase()) {
        await logo.delete();
        break;
      }
    }
  }

  Future<File?> getLogo(String callsign) async {
    final logos = await getLogos();
    final lowerCallsign = callsign.toLowerCase();

    for (final logo in logos) {
      final baseName = p.basenameWithoutExtension(logo.path);
      if (baseName == lowerCallsign) {
        return logo;
      }
    }
    return null;
  }

  // Signature Image Management
  Future<List<File>> getSignatures() async {
    final files = await _signaturesDir.list().toList();
    return files
        .whereType<File>()
        .where((f) => _isImageFile(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  Future<File> saveSignature(File sourceFile, String callsign) async {
    final ext = p.extension(sourceFile.path);
    final destPath = p.join(_signaturesDir.path, '${callsign.toLowerCase()}$ext');
    // Don't copy if source and destination are the same (e.g., from SignatureGenerator)
    if (sourceFile.path == destPath) {
      return sourceFile;
    }
    return sourceFile.copy(destPath);
  }

  Future<void> deleteSignature(String callsign) async {
    final signatures = await getSignatures();
    for (final sig in signatures) {
      final baseName = p.basenameWithoutExtension(sig.path);
      if (baseName == callsign.toLowerCase()) {
        await sig.delete();
        break;
      }
    }
  }

  Future<File?> getSignature(String callsign) async {
    final signatures = await getSignatures();
    final lowerCallsign = callsign.toLowerCase();

    for (final sig in signatures) {
      final baseName = p.basenameWithoutExtension(sig.path);
      if (baseName == lowerCallsign) {
        return sig;
      }
    }
    return null;
  }

  // Additional Logos Management (club logos, sponsor logos, etc.)
  // Max 6 additional logos per callsign, stored as {callsign}_1.png, {callsign}_2.png, etc.

  Future<List<File>> getAdditionalLogos(String callsign) async {
    final lowerCallsign = callsign.toLowerCase();
    final List<File> logos = [];

    final files = await _additionalLogosDir.list().toList();
    for (final file in files.whereType<File>()) {
      final fileName = p.basename(file.path);
      if (fileName.startsWith('${lowerCallsign}_') && _isImageFile(file.path)) {
        logos.add(file);
      }
    }

    // Sort by number suffix
    logos.sort((a, b) {
      final aNum = _extractLogoNumber(a.path);
      final bNum = _extractLogoNumber(b.path);
      return aNum.compareTo(bNum);
    });

    return logos;
  }

  int _extractLogoNumber(String filePath) {
    final baseName = p.basenameWithoutExtension(filePath);
    final parts = baseName.split('_');
    if (parts.length >= 2) {
      return int.tryParse(parts.last) ?? 0;
    }
    return 0;
  }

  Future<File> saveAdditionalLogo(File sourceFile, String callsign, int index) async {
    final ext = p.extension(sourceFile.path);
    final destPath = p.join(_additionalLogosDir.path, '${callsign.toLowerCase()}_$index$ext');
    return sourceFile.copy(destPath);
  }

  Future<void> deleteAdditionalLogo(String callsign, int index) async {
    final logos = await getAdditionalLogos(callsign);
    final lowerCallsign = callsign.toLowerCase();

    for (final logo in logos) {
      final fileName = p.basename(logo.path);
      if (fileName.startsWith('${lowerCallsign}_$index.')) {
        await logo.delete();
        break;
      }
    }
  }

  Future<void> deleteAllAdditionalLogos(String callsign) async {
    final logos = await getAdditionalLogos(callsign);
    for (final logo in logos) {
      await logo.delete();
    }
  }

  bool _isImageFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  // Copy default background from assets if it doesn't exist
  Future<void> _copyDefaultBackgroundIfNeeded() async {
    final destPath = p.join(_backgroundsDir.path, 'default_gradient.png');
    final destFile = File(destPath);
    if (!await destFile.exists()) {
      try {
        final byteData = await rootBundle.load('assets/backgrounds/default_gradient.png');
        await destFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      } catch (e) {
        // Asset not found or failed to copy - not critical
      }
    }
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
      final baseName = p.basenameWithoutExtension(template.path);
      if (baseName == lowerCallsign) {
        return template;
      }
    }
    return null;
  }

  // Migrate all files from old callsign to new callsign
  Future<void> migrateCallsign(String oldCallsign, String newCallsign) async {
    final newLower = newCallsign.toLowerCase();

    // Migrate template
    final template = await getTemplate(oldCallsign);
    if (template != null) {
      final ext = p.extension(template.path);
      final newPath = p.join(_templatesDir.path, '$newLower$ext');
      await template.rename(newPath);
    }

    // Migrate logo
    final logo = await getLogo(oldCallsign);
    if (logo != null) {
      final ext = p.extension(logo.path);
      final newPath = p.join(_logosDir.path, '$newLower$ext');
      await logo.rename(newPath);
    }

    // Migrate signature
    final signature = await getSignature(oldCallsign);
    if (signature != null) {
      final ext = p.extension(signature.path);
      final newPath = p.join(_signaturesDir.path, '$newLower$ext');
      await signature.rename(newPath);
    }

    // Migrate additional logos
    final additionalLogos = await getAdditionalLogos(oldCallsign);
    for (final addLogo in additionalLogos) {
      final ext = p.extension(addLogo.path);
      final num = _extractLogoNumber(addLogo.path);
      final newPath = p.join(_additionalLogosDir.path, '${newLower}_$num$ext');
      await addLogo.rename(newPath);
    }
  }
}
