import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/services.dart';

class SetupScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onSetupComplete;

  const SetupScreen({
    super.key,
    required this.storageService,
    required this.onSetupComplete,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _pageController = PageController();
  final _imagePicker = ImagePicker();

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form data
  final _callsignController = TextEditingController();
  final _stationNameController = TextEditingController();
  final _qrzLinkController = TextEditingController();

  File? _templateImage;
  final List<File> _backgroundImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _callsignController.dispose();
    _stationNameController.dispose();
    _qrzLinkController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickTemplateImage() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() => _templateImage = File(result.path));
    }
  }

  Future<void> _pickBackgroundImages() async {
    final results = await _imagePicker.pickMultiImage();
    if (results.isNotEmpty) {
      setState(() {
        _backgroundImages.addAll(results.map((r) => File(r.path)));
      });
    }
  }

  void _removeBackground(int index) {
    setState(() => _backgroundImages.removeAt(index));
  }

  Future<void> _completeSetup() async {
    if (_callsignController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your callsign')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final callsign = _callsignController.text.toUpperCase();

      // Create card config
      final config = await widget.storageService.createConfig(
        CardConfig(
          callsign: callsign,
          name: _stationNameController.text.isNotEmpty
              ? _stationNameController.text
              : callsign,
          qrzLink: _qrzLinkController.text.isNotEmpty
              ? _qrzLinkController.text
              : 'https://www.qrz.com/db/$callsign',
          textPositions: TextPositions.defaultPositions(),
        ),
      );

      // Save template image
      if (_templateImage != null) {
        await widget.storageService.saveTemplate(_templateImage!, callsign);
      }

      // Save background images
      for (final bg in _backgroundImages) {
        await widget.storageService.saveBackground(bg);
      }

      // Mark setup as complete
      await widget.storageService.setActiveConfig(config.id!);
      await widget.storageService.setSetupComplete(true);

      widget.onSetupComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(_totalSteps, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? const Color(0xFF3b82f6)
                            : const Color(0xFF475569),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildCallsignPage(),
                  _buildTemplatePage(),
                  _buildBackgroundsPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _previousStep,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_currentStep < _totalSteps - 1)
                    ElevatedButton(
                      onPressed: _canProceed() ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3b82f6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Continue'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isLoading ? null : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22c55e),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Complete Setup'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true; // Welcome page
      case 1:
        return _callsignController.text.isNotEmpty;
      case 2:
        return true; // Template is optional
      case 3:
        return true; // Backgrounds are optional
      default:
        return true;
    }
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radio,
            size: 80,
            color: const Color(0xFF3b82f6),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to\nQSL Card Generator',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create beautiful QSL cards for your amateur radio contacts.\n\nLet\'s set up your station in a few simple steps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF94a3b8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsignPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Station',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your callsign and station details.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Callsign *',
            controller: _callsignController,
            hint: 'e.g. OE8YML',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 20),

          _buildTextField(
            label: 'Station Name (optional)',
            controller: _stationNameController,
            hint: 'e.g. My Home Station',
          ),
          const SizedBox(height: 20),

          _buildTextField(
            label: 'QRZ.com Profile URL (optional)',
            controller: _qrzLinkController,
            hint: 'https://www.qrz.com/db/OE8YML',
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Card Template',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a PNG overlay template with transparent areas for the QSO data. This is optional - you can add it later.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 32),

          if (_templateImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _templateImage!,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _templateImage = null),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ] else ...[
            InkWell(
              onTap: _pickTemplateImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF475569),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF1e293b),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Color(0xFF64748b),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Click to upload template',
                        style: TextStyle(color: Color(0xFF64748b)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PNG with transparency recommended',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackgroundsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Background Images',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add background images for your QSL cards. You can add more later from the generator.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 32),

          // Add button
          InkWell(
            onTap: _pickBackgroundImages,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF475569)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF1e293b),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 32,
                      color: Color(0xFF3b82f6),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add Background Images',
                      style: TextStyle(color: Color(0xFF3b82f6)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_backgroundImages.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '${_backgroundImages.length} image(s) selected',
              style: const TextStyle(color: Color(0xFF94a3b8)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _backgroundImages.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        entry.value,
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeBackground(entry.key),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
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
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748b)),
            filled: true,
            fillColor: const Color(0xFF1e293b),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
