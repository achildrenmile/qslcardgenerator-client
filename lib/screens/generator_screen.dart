import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

  // Form controllers
  final _callsignController = TextEditingController();
  final _dateTimeController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _modeController = TextEditingController();
  final _rstController = TextEditingController();
  final _additionalController = TextEditingController();

  // State
  CardConfig? _activeConfig;
  QsoData _qsoData = QsoData.empty();
  List<File> _backgrounds = [];
  File? _selectedBackground;
  ui.Image? _backgroundImage;
  ui.Image? _templateImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Set current UTC time
    final now = DateTime.now().toUtc();
    _dateTimeController.text = _formatDateTime(now);
    _additionalController.text = 'Thanks for the QSO\nBest regards';

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

    // Load template image for this config
    if (_activeConfig != null) {
      await _loadTemplateImage();
    }

    // Load first background by default if available
    if (_backgrounds.isNotEmpty) {
      await _loadBackgroundImage(_backgrounds.first);
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _updateQsoData() {
    final additionalLines = _additionalController.text.split('\n');
    // Parse the date/time string
    DateTime? parsedDateTime;
    try {
      final parts = _dateTimeController.text.split(' ');
      if (parts.length == 2) {
        final dateParts = parts[0].split('.');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length == 2) {
          parsedDateTime = DateTime.utc(
            int.parse(dateParts[2]), // year
            int.parse(dateParts[1]), // month
            int.parse(dateParts[0]), // day
            int.parse(timeParts[0]), // hour
            int.parse(timeParts[1]), // minute
          );
        }
      }
    } catch (_) {
      // Keep existing date if parsing fails
    }

    setState(() {
      _qsoData = _qsoData.copyWith(
        contactCallsign: _callsignController.text,
        utcDateTime: parsedDateTime,
        frequency: _frequencyController.text,
        mode: _modeController.text,
        rst: _rstController.text,
        additionalLine1: additionalLines.isNotEmpty ? additionalLines[0] : '',
        additionalLine2: additionalLines.length > 1 ? additionalLines[1] : '',
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
      await _loadBackgroundImage(savedFile);
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
    _dateTimeController.dispose();
    _frequencyController.dispose();
    _modeController.dispose();
    _rstController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
                'Card Details',
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

              // Date & Time
              _buildTextField(
                label: 'Date & Time (UTC)',
                controller: _dateTimeController,
                hint: 'DD.MM.YYYY HH:MM',
              ),
              const SizedBox(height: 16),

              // Frequency, Mode, RST row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Frequency',
                      controller: _frequencyController,
                      hint: 'MHz',
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      label: 'RST',
                      controller: _rstController,
                      hint: 'e.g. 59',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Additional Remarks
              _buildTextField(
                label: 'Additional Remarks',
                controller: _additionalController,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              const Divider(color: Color(0xFF475569)),
              const SizedBox(height: 24),

              // Template section
              const Text(
                'Card Template',
                style: TextStyle(
                  color: Color(0xFF94a3b8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickTemplateImage,
                icon: Icon(
                  _templateImage != null ? Icons.check_circle : Icons.add_photo_alternate,
                  color: _templateImage != null ? Colors.green : const Color(0xFF94a3b8),
                ),
                label: Text(
                  _templateImage != null ? 'Template Loaded' : 'Upload Template PNG',
                  style: TextStyle(
                    color: _templateImage != null ? Colors.green : const Color(0xFF94a3b8),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _templateImage != null ? Colors.green : const Color(0xFF475569),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Background Selection
              const Text(
                'Background',
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
                  child: DropdownButton<File?>(
                    value: _selectedBackground,
                    hint: const Text(
                      'Select a background...',
                      style: TextStyle(color: Color(0xFF64748b)),
                    ),
                    dropdownColor: const Color(0xFF1e293b),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<File?>(
                        value: null,
                        child: Text(
                          'No background (white)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ..._backgrounds.map((file) {
                        final name = file.path.split('/').last;
                        return DropdownMenuItem<File?>(
                          value: file,
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ],
                    onChanged: (file) {
                      if (file != null) {
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
}
