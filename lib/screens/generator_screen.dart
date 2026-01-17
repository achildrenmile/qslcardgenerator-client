import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class GeneratorScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onResetSetup;

  const GeneratorScreen({
    super.key,
    required this.storageService,
    required this.onResetSetup,
  });

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exportService = ExportService();
  final _imagePicker = ImagePicker();
  final _templateGenerator = TemplateGenerator();
  final _signatureGenerator = SignatureGenerator();

  // Form controllers
  final _callsignController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _bandController = TextEditingController();
  final _modeController = TextEditingController();
  final _rstSentController = TextEditingController();
  final _rstRcvdController = TextEditingController();
  final _powerController = TextEditingController();
  final _remarksController = TextEditingController();

  // Checkbox states
  bool _twoWay = true;
  bool _pseQsl = false;
  bool _tnxQsl = true;

  // State
  CardConfig? _activeConfig;
  QsoData _qsoData = QsoData.empty();
  List<File> _backgrounds = [];
  File? _selectedBackground;
  ui.Image? _backgroundImage;
  ui.Image? _templateImage;
  ui.Image? _logoImage;
  ui.Image? _signatureImage;
  List<ui.Image> _additionalLogos = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String _updateMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Set current UTC time
    final now = DateTime.now().toUtc();
    _dateController.text = _formatDate(now);
    _timeController.text = _formatTime(now);
    _rstSentController.text = '59';
    _remarksController.text = 'Thanks for the QSO! 73';

    // Load backgrounds
    _backgrounds = await widget.storageService.getBackgrounds();

    // Load active config
    _activeConfig = await widget.storageService.getActiveConfig();

    // Create default config if none exists
    _activeConfig ??= await widget.storageService.createConfig(
      CardConfig(
        callsign: 'MYCALL',
        name: 'My Station',
        qrzLink: 'https://www.qrz.com/db/MYCALL',
        textPositions: TextPositions.defaultPositions(),
      ),
    );

    // Load images for this config
    if (_activeConfig != null) {
      await _loadTemplateImage();
      await _loadLogoImage();
      await _loadSignatureImage();
      await _loadAdditionalLogos();
    }

    // Load default background (prefer default_gradient, then first available)
    if (_backgrounds.isNotEmpty) {
      final defaultBg = _backgrounds.firstWhere(
        (f) => f.path.endsWith('default_gradient.png'),
        orElse: () => _backgrounds.first,
      );
      await _loadBackgroundImage(defaultBg);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadTemplateImage() async {
    if (_activeConfig == null) return;

    final templateFile = await widget.storageService.getTemplate(_activeConfig!.callsign);
    if (templateFile != null) {
      final image = await _exportService.loadImage(templateFile);
      setState(() {
        _templateImage = image;
      });
    }
  }

  Future<void> _loadLogoImage() async {
    if (_activeConfig == null) return;

    final logoFile = await widget.storageService.getLogo(_activeConfig!.callsign);
    if (logoFile != null) {
      try {
        final image = await _exportService.loadImage(logoFile);
        setState(() {
          _logoImage = image;
        });
      } catch (e) {
        // Invalid logo file - delete it and continue
        debugPrint('Invalid logo file, removing: $e');
        await widget.storageService.deleteLogo(_activeConfig!.callsign);
      }
    }
  }

  Future<void> _loadSignatureImage() async {
    if (_activeConfig == null) return;

    final sigFile = await widget.storageService.getSignature(_activeConfig!.callsign);
    if (sigFile != null) {
      try {
        final image = await _exportService.loadImage(sigFile);
        setState(() {
          _signatureImage = image;
        });
      } catch (e) {
        // Invalid signature file - delete it and continue
        debugPrint('Invalid signature file, removing: $e');
        await widget.storageService.deleteSignature(_activeConfig!.callsign);
      }
    }
  }

  Future<void> _loadAdditionalLogos() async {
    if (_activeConfig == null) return;

    final logoFiles = await widget.storageService.getAdditionalLogos(_activeConfig!.callsign);
    final List<ui.Image> loadedLogos = [];

    for (final file in logoFiles) {
      try {
        final image = await _exportService.loadImage(file);
        if (image != null) {
          loadedLogos.add(image);
        }
      } catch (e) {
        debugPrint('Invalid additional logo file, skipping: $e');
      }
    }

    setState(() {
      _additionalLogos = loadedLogos;
    });
  }

  Future<void> _pickLogoImage() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null && _activeConfig != null) {
      final file = File(result.path);
      await widget.storageService.saveLogo(file, _activeConfig!.callsign);
      await _loadLogoImage();
    }
  }

  Future<void> _pickSignatureImage() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null && _activeConfig != null) {
      final file = File(result.path);
      await widget.storageService.saveSignature(file, _activeConfig!.callsign);
      await _loadSignatureImage();
    }
  }

  Future<void> _pickAdditionalLogo() async {
    if (_activeConfig == null) return;
    if (_additionalLogos.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 additional logos allowed')),
      );
      return;
    }

    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      final file = File(result.path);
      final nextIndex = _additionalLogos.length + 1;
      await widget.storageService.saveAdditionalLogo(file, _activeConfig!.callsign, nextIndex);
      await _loadAdditionalLogos();
    }
  }

  Future<void> _removeAdditionalLogo(int index) async {
    if (_activeConfig == null) return;
    await widget.storageService.deleteAdditionalLogo(_activeConfig!.callsign, index + 1);
    await _loadAdditionalLogos();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _updateQsoData() {
    // Parse date and time
    DateTime? parsedDateTime;
    try {
      final dateParts = _dateController.text.split('.');
      final timeParts = _timeController.text.split(':');
      if (dateParts.length == 3 && timeParts.length == 2) {
        parsedDateTime = DateTime.utc(
          int.parse(dateParts[2]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[0]), // day
          int.parse(timeParts[0]), // hour
          int.parse(timeParts[1]), // minute
        );
      }
    } catch (_) {
      // Keep existing date if parsing fails
    }

    setState(() {
      _qsoData = _qsoData.copyWith(
        contactCallsign: _callsignController.text,
        utcDateTime: parsedDateTime,
        frequency: _frequencyController.text,
        band: _bandController.text,
        mode: _modeController.text,
        rstSent: _rstSentController.text,
        rstRcvd: _rstRcvdController.text,
        power: _powerController.text,
        twoWay: _twoWay,
        pseQsl: _pseQsl,
        tnxQsl: _tnxQsl,
        remarks: _remarksController.text,
      );
    });
  }

  Future<void> _loadBackgroundImage(File file) async {
    final image = await _exportService.loadImage(file);
    setState(() {
      _selectedBackground = file;
      _backgroundImage = image;
    });
  }

  Future<void> _pickCustomBackground() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      final file = File(result.path);
      final savedFile = await widget.storageService.saveBackground(file);
      _backgrounds = await widget.storageService.getBackgrounds();
      // Find the matching file in the reloaded list by path
      final matchingFile = _backgrounds.firstWhere(
        (f) => f.path == savedFile.path,
        orElse: () => savedFile,
      );
      await _loadBackgroundImage(matchingFile);
    }
  }

  Future<void> _pickTemplateImage() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null && _activeConfig != null) {
      final file = File(result.path);
      await widget.storageService.saveTemplate(file, _activeConfig!.callsign);
      await _loadTemplateImage();
    }
  }

  Future<void> _showCallsignColorPicker() async {
    if (_activeConfig == null) return;

    Color currentColor = Color(_activeConfig!.callsignColor);
    Color pickedColor = currentColor;

    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Callsign Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) => pickedColor = color,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, pickedColor),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (selectedColor != null && selectedColor.value != currentColor.value) {
      setState(() {
        _isUpdating = true;
        _updateMessage = 'Updating callsign color...';
      });

      try {
        final updatedConfig = _activeConfig!.copyWith(
          callsignColor: selectedColor.value,
        );
        await widget.storageService.updateConfig(updatedConfig);
        setState(() {
          _activeConfig = updatedConfig;
          _updateMessage = 'Regenerating template...';
        });
        await _regenerateTemplate(selectedColor);
      } finally {
        setState(() {
          _isUpdating = false;
          _updateMessage = '';
        });
      }
    }
  }

  Future<void> _regenerateTemplate(Color callsignColor) async {
    if (_activeConfig == null) return;

    final operatorInfo = _activeConfig!.operatorInfo;
    await _templateGenerator.generateTemplate(
      callsign: _activeConfig!.callsign,
      operatorName: operatorInfo.operatorName,
      street: operatorInfo.street,
      city: operatorInfo.city,
      country: operatorInfo.country,
      locator: operatorInfo.locator,
      email: operatorInfo.email,
      callsignColor: callsignColor,
    );

    // Reload the template image
    await _loadTemplateImage();
  }

  Future<void> _showEditStationInfo() async {
    if (_activeConfig == null) return;

    final operatorInfo = _activeConfig!.operatorInfo;
    final nameController = TextEditingController(text: operatorInfo.operatorName);
    final streetController = TextEditingController(text: operatorInfo.street);
    final cityController = TextEditingController(text: operatorInfo.city);
    final countryController = TextEditingController(text: operatorInfo.country);
    final locatorController = TextEditingController(text: operatorInfo.locator);
    final emailController = TextEditingController(text: operatorInfo.email);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Station Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Operator Name',
                  hintText: 'e.g. Michael Linder',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: streetController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'e.g. Musterstraße 55',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City / QTH',
                  hintText: 'e.g. 9611 Nötsch im Gailtal',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  hintText: 'e.g. Austria',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locatorController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Grid Locator',
                  hintText: 'e.g. JN66',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'e.g. oe8yml@example.at',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isUpdating = true;
        _updateMessage = 'Updating station info...';
      });

      try {
        final newOperatorInfo = OperatorInfo(
          operatorName: nameController.text,
          street: streetController.text,
          city: cityController.text,
          country: countryController.text,
          locator: locatorController.text.toUpperCase(),
          email: emailController.text,
        );

        final updatedConfig = _activeConfig!.copyWith(
          operatorInfo: newOperatorInfo,
        );
        await widget.storageService.updateConfig(updatedConfig);
        setState(() {
          _activeConfig = updatedConfig;
          _updateMessage = 'Regenerating template...';
        });

        // Regenerate template with updated info
        await _regenerateTemplate(Color(_activeConfig!.callsignColor));
      } finally {
        setState(() {
          _isUpdating = false;
          _updateMessage = '';
        });
      }
    }

    nameController.dispose();
    streetController.dispose();
    cityController.dispose();
    countryController.dispose();
    locatorController.dispose();
    emailController.dispose();
  }

  Future<void> _showEditCallsign() async {
    if (_activeConfig == null) return;

    final callsignController = TextEditingController(text: _activeConfig!.callsign);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Callsign'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFfef3c7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFf59e0b)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Color(0xFFd97706), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changing callsign will update all card templates and stored images.',
                      style: TextStyle(color: Color(0xFFd97706), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: callsignController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Callsign',
                hintText: 'e.g. OE8YML',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newCallsign = callsignController.text.toUpperCase().trim();
              if (newCallsign.isNotEmpty) {
                Navigator.pop(context, newCallsign);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    callsignController.dispose();

    if (result != null && result != _activeConfig!.callsign) {
      setState(() {
        _isUpdating = true;
        _updateMessage = 'Updating callsign...';
      });

      try {
        final oldCallsign = _activeConfig!.callsign;
        final newCallsign = result;

        // Migrate stored files to new callsign
        setState(() => _updateMessage = 'Migrating files...');
        await widget.storageService.migrateCallsign(oldCallsign, newCallsign);

        // Update config with new callsign
        final updatedConfig = _activeConfig!.copyWith(
          callsign: newCallsign,
        );
        await widget.storageService.updateConfig(updatedConfig);
        setState(() {
          _activeConfig = updatedConfig;
          _updateMessage = 'Regenerating template...';
        });

        // Regenerate template with new callsign
        await _regenerateTemplate(Color(_activeConfig!.callsignColor));

        // Reload images
        setState(() => _updateMessage = 'Reloading images...');
        await _loadTemplateImage();
        await _loadLogoImage();
        await _loadSignatureImage();
        await _loadAdditionalLogos();
      } finally {
        setState(() {
          _isUpdating = false;
          _updateMessage = '';
        });
      }
    }
  }

  Future<void> _showSignatureEditor() async {
    if (_activeConfig == null) return;

    await showDialog(
      context: context,
      builder: (context) => _SignatureEditorDialog(
        activeConfig: _activeConfig!,
        signatureGenerator: _signatureGenerator,
        storageService: widget.storageService,
        imagePicker: _imagePicker,
        onSignatureSaved: () async {
          await _loadSignatureImage();
        },
      ),
    );
  }

  Future<void> _removeSignature() async {
    if (_activeConfig == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Signature?'),
        content: const Text('This will remove your signature from all QSL cards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.storageService.deleteSignature(_activeConfig!.callsign);
      setState(() {
        _signatureImage = null;
      });
    }
  }

  Future<void> _exportCard() async {
    if (_activeConfig == null) return;

    final callsign = _callsignController.text.isEmpty
        ? 'QSL'
        : _callsignController.text.toUpperCase();

    // High resolution export (matches web version)
    const width = 4961;
    const height = 3189;

    final file = await _exportService.exportCard(
      backgroundImage: _backgroundImage,
      templateImage: _templateImage,
      logoImage: _logoImage,
      signatureImage: _signatureImage,
      additionalLogos: _additionalLogos,
      qsoData: _qsoData,
      cardConfig: _activeConfig!,
      width: width,
      height: height,
      suggestedFileName: '$callsign.png',
    );

    if (file != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QSL card saved: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _callsignController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _frequencyController.dispose();
    _bandController.dispose();
    _modeController.dispose();
    _rstSentController.dispose();
    _rstRcvdController.dispose();
    _powerController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('QSL Card Generator - ${_activeConfig?.callsign ?? ""}'),
        backgroundColor: const Color(0xFF1e293b),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) async {
              if (value == 'reset') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Setup?'),
                    content: const Text(
                      'This will clear your station settings and show the setup wizard again.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await widget.storageService.resetSetup();
                  widget.onResetSetup();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Reset Setup Wizard'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF0f172a),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildPreviewSection()),
                  Expanded(flex: 2, child: _buildFormSection()),
                ],
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFormSection(),
                    _buildPreviewSection(),
                  ],
                ),
              );
            }
          },
        ),
      ),
        ),
        // Loading overlay
        if (_isUpdating)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF3b82f6)),
                    const SizedBox(height: 16),
                    Text(
                      _updateMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QSL Card Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Open QRZ link
                },
                child: const Text('View on QRZ.com'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0f172a),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _activeConfig != null
                ? QslCardPreview(
                    backgroundImage: _backgroundImage,
                    templateImage: _templateImage,
                    logoImage: _logoImage,
                    signatureImage: _signatureImage,
                    additionalLogos: _additionalLogos,
                    qsoData: _qsoData,
                    cardConfig: _activeConfig!,
                  )
                : const Center(
                    child: Text(
                      'No configuration loaded',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Download Button
          ElevatedButton.icon(
            onPressed: _exportCard,
            icon: const Icon(Icons.download),
            label: const Text('Download QSL Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1e293b),
        border: Border(
          left: BorderSide(color: Color(0xFF475569)),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'QSO Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Contact Callsign
              _buildTextField(
                label: 'Contact Callsign',
                controller: _callsignController,
                hint: 'e.g. DL5XYZ',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Date & Time row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Date (UTC)',
                      controller: _dateController,
                      hint: 'DD.MM.YYYY',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Time (UTC)',
                      controller: _timeController,
                      hint: 'HH:MM',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Frequency & Band row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Frequency (MHz)',
                      controller: _frequencyController,
                      hint: 'e.g. 145.500',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Band',
                      controller: _bandController,
                      hint: 'e.g. 2m',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode & Power row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Mode',
                      controller: _modeController,
                      hint: 'e.g. FM',
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Power (W)',
                      controller: _powerController,
                      hint: 'e.g. 50',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // RST Sent & Received row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'RST Sent',
                      controller: _rstSentController,
                      hint: 'e.g. 59',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'RST Received',
                      controller: _rstRcvdController,
                      hint: 'e.g. 59',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Checkboxes row
              Row(
                children: [
                  _buildCheckbox('2-Way', _twoWay, (v) {
                    setState(() => _twoWay = v ?? false);
                    _updateQsoData();
                  }),
                  const SizedBox(width: 24),
                  _buildCheckbox('PSE QSL', _pseQsl, (v) {
                    setState(() => _pseQsl = v ?? false);
                    _updateQsoData();
                  }),
                  const SizedBox(width: 24),
                  _buildCheckbox('TNX QSL', _tnxQsl, (v) {
                    setState(() => _tnxQsl = v ?? false);
                    _updateQsoData();
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Remarks
              _buildTextField(
                label: 'Remarks',
                controller: _remarksController,
                hint: 'Thanks for the QSO! 73',
              ),
              const SizedBox(height: 24),

              const Divider(color: Color(0xFF475569)),
              const SizedBox(height: 24),

              // Callsign section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Callsign',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showEditCallsign,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3b82f6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Display current callsign
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0f172a),
                  border: Border.all(color: const Color(0xFF475569)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _activeConfig?.callsign ?? '',
                  style: TextStyle(
                    color: Color(_activeConfig?.callsignColor ?? CardConfig.defaultCallsignColor),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Station Info section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Station Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showEditStationInfo,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3b82f6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Display current station info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0f172a),
                  border: Border.all(color: const Color(0xFF475569)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_activeConfig?.operatorInfo.operatorName.isNotEmpty ?? false)
                      Text(
                        _activeConfig!.operatorInfo.operatorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (_activeConfig?.operatorInfo.street.isNotEmpty ?? false)
                      Text(
                        _activeConfig!.operatorInfo.street,
                        style: const TextStyle(color: Color(0xFF94a3b8)),
                      ),
                    if (_activeConfig?.operatorInfo.city.isNotEmpty ?? false)
                      Text(
                        _activeConfig!.operatorInfo.city,
                        style: const TextStyle(color: Color(0xFF94a3b8)),
                      ),
                    if (_activeConfig?.operatorInfo.country.isNotEmpty ?? false)
                      Text(
                        _activeConfig!.operatorInfo.country,
                        style: const TextStyle(color: Color(0xFF94a3b8)),
                      ),
                    if (_activeConfig?.operatorInfo.locator.isNotEmpty ?? false)
                      Text(
                        'LOC: ${_activeConfig!.operatorInfo.locator}',
                        style: const TextStyle(color: Color(0xFF64748b), fontSize: 12),
                      ),
                    if (_activeConfig?.operatorInfo.email.isNotEmpty ?? false)
                      Text(
                        _activeConfig!.operatorInfo.email,
                        style: const TextStyle(color: Color(0xFF3b82f6), fontSize: 12),
                      ),
                    if ((_activeConfig?.operatorInfo.operatorName.isEmpty ?? true) &&
                        (_activeConfig?.operatorInfo.street.isEmpty ?? true) &&
                        (_activeConfig?.operatorInfo.city.isEmpty ?? true))
                      const Text(
                        'No station info configured',
                        style: TextStyle(color: Color(0xFF64748b), fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Divider(color: Color(0xFF475569)),
              const SizedBox(height: 24),

              // Callsign Style section
              const Text(
                'Callsign Style',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Callsign color picker
              Row(
                children: [
                  const Text(
                    'CALLSIGN COLOR',
                    style: TextStyle(
                      color: Color(0xFF94a3b8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _showCallsignColorPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0f172a),
                          border: Border.all(color: const Color(0xFF475569)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(_activeConfig?.callsignColor ?? CardConfig.defaultCallsignColor),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '#${(_activeConfig?.callsignColor ?? CardConfig.defaultCallsignColor).toRadixString(16).substring(2).toUpperCase()}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const Icon(Icons.color_lens, color: Color(0xFF94a3b8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Divider(color: Color(0xFF475569)),
              const SizedBox(height: 24),

              // Card Images section
              const Text(
                'Card Images',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Template
              _buildImageButton(
                label: 'Card Template',
                hasImage: _templateImage != null,
                loadedText: 'Template Loaded',
                uploadText: 'Upload Template PNG',
                onPressed: _pickTemplateImage,
              ),
              const SizedBox(height: 12),

              // Logo
              _buildImageButton(
                label: 'Station Logo',
                hasImage: _logoImage != null,
                loadedText: 'Logo Loaded',
                uploadText: 'Upload Logo Image',
                onPressed: _pickLogoImage,
              ),
              const SizedBox(height: 16),

              // Signature section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SIGNATURE',
                    style: TextStyle(
                      color: Color(0xFF94a3b8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_signatureImage != null)
                    TextButton(
                      onPressed: _removeSignature,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text('Remove', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Signature preview or create button
              if (_signatureImage != null)
                InkWell(
                  onTap: _showSignatureEditor,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF22c55e)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 50,
                          child: RawImage(
                            image: _signatureImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF22c55e), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Signature loaded - tap to change',
                              style: TextStyle(color: Color(0xFF22c55e), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: _showSignatureEditor,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0f172a),
                      border: Border.all(color: const Color(0xFF475569)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.draw, color: Color(0xFF3b82f6), size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Create Signature',
                          style: TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upload image or type your name',
                          style: TextStyle(color: Color(0xFF64748b), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Additional Logos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ADDITIONAL LOGOS',
                    style: TextStyle(
                      color: Color(0xFF94a3b8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${_additionalLogos.length}/6',
                    style: const TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Additional logos grid
              if (_additionalLogos.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _additionalLogos.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF475569)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: RawImage(
                              image: entry.value,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => _removeAdditionalLogo(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),

              if (_additionalLogos.length < 6) ...[
                if (_additionalLogos.isNotEmpty) const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickAdditionalLogo,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(_additionalLogos.isEmpty ? 'Add Logo' : 'Add Another'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3b82f6),
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Background Selection
              const Text(
                'BACKGROUND',
                style: TextStyle(
                  color: Color(0xFF94a3b8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Background dropdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0f172a),
                  border: Border.all(color: const Color(0xFF475569)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBackground?.path ?? '',
                    dropdownColor: const Color(0xFF1e293b),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                          'No background (white)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ..._backgrounds.map((file) {
                        final name = file.path.split(Platform.pathSeparator).last;
                        return DropdownMenuItem<String>(
                          value: file.path,
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ],
                    onChanged: (path) {
                      if (path != null && path.isNotEmpty) {
                        final file = _backgrounds.firstWhere(
                          (f) => f.path == path,
                          orElse: () => File(path),
                        );
                        _loadBackgroundImage(file);
                      } else {
                        setState(() {
                          _selectedBackground = null;
                          _backgroundImage = null;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Custom background button
              OutlinedButton.icon(
                onPressed: _pickCustomBackground,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Custom Background'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF94a3b8),
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF94a3b8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748b)),
            filled: true,
            fillColor: const Color(0xFF0f172a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF475569)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF475569)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3b82f6), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (_) => _updateQsoData(),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3b82f6),
            side: const BorderSide(color: Color(0xFF94a3b8)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94a3b8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton({
    required String label,
    required bool hasImage,
    required String loadedText,
    required String uploadText,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF94a3b8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            hasImage ? Icons.check_circle : Icons.add_photo_alternate,
            color: hasImage ? Colors.green : const Color(0xFF94a3b8),
          ),
          label: Text(
            hasImage ? loadedText : uploadText,
            style: TextStyle(
              color: hasImage ? Colors.green : const Color(0xFF94a3b8),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: hasImage ? Colors.green : const Color(0xFF475569),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }
}

// Signature Editor Dialog
enum _SignatureMode { upload, typed }

class _SignatureEditorDialog extends StatefulWidget {
  final CardConfig activeConfig;
  final SignatureGenerator signatureGenerator;
  final StorageService storageService;
  final ImagePicker imagePicker;
  final VoidCallback onSignatureSaved;

  const _SignatureEditorDialog({
    required this.activeConfig,
    required this.signatureGenerator,
    required this.storageService,
    required this.imagePicker,
    required this.onSignatureSaved,
  });

  @override
  State<_SignatureEditorDialog> createState() => _SignatureEditorDialogState();
}

class _SignatureEditorDialogState extends State<_SignatureEditorDialog> {
  _SignatureMode _mode = _SignatureMode.upload;
  File? _previewImage;
  final _textController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    final result = await widget.imagePicker.pickImage(source: ImageSource.gallery);
    if (result == null) return;

    // Crop with 6:1 aspect ratio
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: result.path,
      aspectRatio: const CropAspectRatio(ratioX: 6, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Signature',
          toolbarColor: const Color(0xFF0f172a),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
          hideBottomControls: false,
          activeControlsWidgetColor: const Color(0xFF3b82f6),
        ),
        IOSUiSettings(
          title: 'Crop Signature',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _previewImage = File(croppedFile.path);
      });
    }
  }

  Future<void> _generateTypedSignature() async {
    if (_textController.text.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      final file = await widget.signatureGenerator.generateSignature(
        text: _textController.text,
        callsign: widget.activeConfig.callsign,
        fontFamily: 'DancingScript',
      );
      setState(() {
        _previewImage = file;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveSignature() async {
    if (_previewImage == null) return;

    await widget.storageService.saveSignature(
      _previewImage!,
      widget.activeConfig.callsign,
    );
    widget.onSignatureSaved();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Signature'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format guidance
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFe0f2fe),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0ea5e9)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF0369a1), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Ideal Format',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0369a1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• PNG with transparent background\n'
                      '• Wide aspect ratio (6:1 recommended)\n'
                      '• Dark color for visibility on light card',
                      style: TextStyle(color: Color(0xFF0369a1), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mode toggle
              Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      mode: _SignatureMode.upload,
                      icon: Icons.image,
                      label: 'Upload Image',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeButton(
                      mode: _SignatureMode.typed,
                      icon: Icons.edit,
                      label: 'Type Name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mode-specific content
              if (_mode == _SignatureMode.upload) ...[
                // Upload mode
                OutlinedButton.icon(
                  onPressed: _pickAndCropImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(_previewImage == null ? 'Select Image' : 'Change Image'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ] else ...[
                // Typed mode
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'e.g. John Smith',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Live preview of typed text
                if (_textController.text.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview:',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _textController.text,
                          style: const TextStyle(
                            fontFamily: 'DancingScript',
                            fontSize: 28,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Generate button
                ElevatedButton.icon(
                  onPressed: _textController.text.isNotEmpty && !_isGenerating
                      ? _generateTypedSignature
                      : null,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(_isGenerating ? 'Generating...' : 'Generate Signature Image'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],

              // Preview of generated/uploaded image
              if (_previewImage != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Ready to save:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF22c55e), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    _previewImage!,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _previewImage != null ? _saveSignature : null,
          child: const Text('Save Signature'),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required _SignatureMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () => setState(() {
        _mode = mode;
        _previewImage = null; // Clear preview when switching modes
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3b82f6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3b82f6) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
