import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/repositories/learning_module_repo.dart';
import 'package:juniper_journal/src/frontend/learning_module/anchoring_phenomenon.dart';
import '../../styling/app_colors.dart';

/// **Purpose:**  
/// Provides a clear and engaging title for the learning experience.
///
/// **Key Features:**  
/// - Serves as the headline for the lesson or module.  
/// - Displayed on module cards and schedules.  
/// - Helps categorize and communicate the content scope.
///
/// **Creator Actions / Behaviors:**  
/// - Enter a short, descriptive, and engaging title during module creation  
///   (e.g., `"What is Photosynthesis?"`).  
/// - Ensure the title reflects the key theme or learning objective of the lesson.
///
/// **User Behaviors:**  
/// - View the lesson title when browsing or selecting learning modules.  
/// - Use the title as a cue to determine relevance or interest.  
/// - Search for lessons by title using the search bar.


class CreateTemplateScreen extends StatefulWidget {
  final Map<String, dynamic>? existingModule;

  const CreateTemplateScreen({super.key, this.existingModule});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}


class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _moduleNameController = TextEditingController();
  String? _selectedDifficulty;

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
  void initState() {
    super.initState();

    // If editing, prefill data
    final module = widget.existingModule;
    if (module != null) {
      _moduleNameController.text = module['module_name'] ?? '';
      _selectedDifficulty = module['difficulty'];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                    borderSide: const BorderSide(
                      color: AppColors.inputBorder,
                      width: 2,
                    ),
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
                    borderSide: const BorderSide(
                      color: AppColors.inputBorder,
                      width: 2,
                    ),
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
                        child: Text(
                          value,
                          style: const TextStyle(color: AppColors.inputText),
                        ),
                      ),
                    )
                    .toList(),
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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final moduleName = _moduleNameController.text.trim();
                      final difficulty = _selectedDifficulty!;
                      int ecoPoints = 0;

                      if (difficulty.contains('Basic')) {
                        ecoPoints = 100;
                      }
                      else if (difficulty.contains('Intermediate')) {
                        ecoPoints = 250;
                      }
                      else if (difficulty.contains('Advanced')) {
                        ecoPoints = 500;
                      }

                      // Purpose here is to avoid using context across async gap later
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final repo = LearningModuleRepo();

                      Map<String, dynamic>? moduleData;

                      if (widget.existingModule == null) {
                        // CREATE new module
                        moduleData = await repo.createModule(
                          moduleName: moduleName,
                          difficulty: difficulty,
                          ecoPoints: ecoPoints,
                        );
                      } else {
                        // UPDATE existing module
                        final success = await repo.updateModule(
                          id: widget.existingModule!['id'].toString(),
                          moduleName: moduleName,
                          difficulty: difficulty,
                          ecoPoints: ecoPoints,
                        );
                        if (success) {
                          // Update the existing module data with new values
                          moduleData = Map<String, dynamic>.from(widget.existingModule!);
                          moduleData['module_name'] = moduleName;
                          moduleData['difficulty'] = difficulty;
                          moduleData['eco_points'] = ecoPoints;
                        } else {
                          moduleData = null;
                        }
                      }

                      if (moduleData != null) {
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => AnchoringPhenomenon(
                              existingModule: moduleData!,
                            ),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Failed to save module')),
                        );
                      }
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