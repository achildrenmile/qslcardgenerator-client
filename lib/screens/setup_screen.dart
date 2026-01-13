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
  final _templateGenerator = TemplateGenerator();

  int _currentStep = 0;
  final int _totalSteps = 3;

  // Station info
  final _callsignController = TextEditingController();
  final _stationNameController = TextEditingController();

  // Operator/Address info
  final _operatorNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _locatorController = TextEditingController();
  final _emailController = TextEditingController();

  final List<File> _backgroundImages = [];
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void dispose() {
    _pageController.dispose();
    _callsignController.dispose();
    _stationNameController.dispose();
    _operatorNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _locatorController.dispose();
    _emailController.dispose();
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

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Creating your station...';
    });

    try {
      final callsign = _callsignController.text.toUpperCase();

      // Create operator info
      final operatorInfo = OperatorInfo(
        operatorName: _operatorNameController.text,
        street: _streetController.text,
        city: _cityController.text,
        country: _countryController.text,
        locator: _locatorController.text.toUpperCase(),
        email: _emailController.text,
      );

      // Create card config
      setState(() => _loadingMessage = 'Saving configuration...');
      final config = await widget.storageService.createConfig(
        CardConfig(
          callsign: callsign,
          name: _stationNameController.text.isNotEmpty
              ? _stationNameController.text
              : callsign,
          qrzLink: 'https://www.qrz.com/db/$callsign',
          textPositions: TextPositions.defaultPositions(),
          operatorInfo: operatorInfo,
        ),
      );

      // Generate card template
      setState(() => _loadingMessage = 'Generating card template...');
      await _templateGenerator.generateTemplate(
        callsign: callsign,
        operatorName: _operatorNameController.text,
        street: _streetController.text,
        city: _cityController.text,
        country: _countryController.text,
        email: _emailController.text,
      );

      // Save background images
      setState(() => _loadingMessage = 'Saving backgrounds...');
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
                  _buildStationInfoPage(),
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
                      onPressed: _isLoading ? null : _previousStep,
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
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_loadingMessage),
                              ],
                            )
                          : const Text('Generate Card & Finish'),
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
        return _callsignController.text.isNotEmpty &&
            _operatorNameController.text.isNotEmpty;
      case 2:
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
            'Create beautiful QSL cards for your amateur radio contacts.\n\nWe\'ll generate a professional card template with your callsign and address.',
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

  Widget _buildStationInfoPage() {
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
            'This information will appear on your QSL card template.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 32),

          // Callsign (required)
          _buildTextField(
            label: 'Callsign *',
            controller: _callsignController,
            hint: 'e.g. OE8YML',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),

          const Divider(color: Color(0xFF475569)),
          const SizedBox(height: 24),

          const Text(
            'Address (for card template)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Operator Name (required)
          _buildTextField(
            label: 'Your Name *',
            controller: _operatorNameController,
            hint: 'e.g. Michael Linder',
          ),
          const SizedBox(height: 16),

          // Street
          _buildTextField(
            label: 'Street Address',
            controller: _streetController,
            hint: 'e.g. Musterstraße 55',
          ),
          const SizedBox(height: 16),

          // City and Country row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'City / QTH',
                  controller: _cityController,
                  hint: 'e.g. 9611 Nötsch im Gailtal',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Country',
                  controller: _countryController,
                  hint: 'e.g. Austria',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            hint: 'e.g. oe8yml@example.at',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Locator
          _buildTextField(
            label: 'Grid Locator',
            controller: _locatorController,
            hint: 'e.g. JN66',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),

          // Preview hint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1e3a5f),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3b82f6)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: const Color(0xFF60a5fa)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'A professional QSL card template will be generated with your callsign and address information.',
                    style: TextStyle(
                      color: Color(0xFF93c5fd),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            'Add background images for your QSL cards. These will appear behind your card template.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1e3a5f),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3b82f6)),
            ),
            child: Row(
              children: [
                Icon(Icons.landscape, color: const Color(0xFF60a5fa)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Use scenic photos like mountains, landscapes, or your shack. You can add more later.',
                    style: TextStyle(
                      color: Color(0xFF93c5fd),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
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
                      Icons.add_photo_alternate,
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
    TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
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
