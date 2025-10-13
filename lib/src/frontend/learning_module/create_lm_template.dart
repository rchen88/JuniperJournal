import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';

class CreateTemplateScreen extends StatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  // used for validation of 'module name' and 'difficulty band' inputs
  final _formKey = GlobalKey<FormState>(); 

  final _moduleNameController = TextEditingController();
  String? _selectedDifficulty;

  // TODO change to correct difficulty bands
  final List<String> _difficultyOptions = [
      'Basic (100 EcoPoints)', 
      'Intermediate (250 EcoPoints)', 
      'Advanced (500 EcoPoints)'
    ];

  @override
  void dispose() {
    _moduleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.border),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Learning Module',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Module Name Field
              TextFormField(
                controller: _moduleNameController,
                decoration: InputDecoration(
                  labelText: 'Module Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.inputBorder, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                ),
                style: const TextStyle(color: AppColors.inputText),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Module name must be completed';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              const Text(
                'Difficulty Band',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // Difficulty Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedDifficulty,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.inputBorder, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                ),
                hint: const Text(
                  'Select difficulty level',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                items: _difficultyOptions
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: const TextStyle(color: AppColors.inputText)),
                      ),
                    ).toList(),
                onChanged: (value) {
                  setState(() => _selectedDifficulty = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Difficulty level must be selected';
                  }
                  return null;
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      debugPrint('Creating module: ${_moduleNameController.text}');
                      debugPrint('Difficulty: $_selectedDifficulty');

                      // TODO implement creation logic
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.buttonText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
