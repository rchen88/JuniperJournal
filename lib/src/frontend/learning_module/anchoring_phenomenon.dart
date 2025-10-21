import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juniper_journal/src/frontend/learning_module/learning_objective.dart';
import 'package:juniper_journal/src/styling/app_colors.dart';
import 'package:juniper_journal/src/backend/db/repositories/learning_module_repo.dart';
import 'package:intl/intl.dart';

class AnchoringPhenomenon extends StatefulWidget {
  final Map<String, dynamic>? existingModule;

  const AnchoringPhenomenon({super.key, this.existingModule});

  @override
  State<AnchoringPhenomenon> createState() => _CreateAnchoringPhenomenonScreenState();
}

class _CreateAnchoringPhenomenonScreenState extends State<AnchoringPhenomenon> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  final _formKey = GlobalKey<FormState>();
  String _selectedNavigation = 'ANCHORING PHENOMENON';
  String _selectedQuestionType = 'WHY';

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadExistingData() async {
    final module = widget.existingModule;
    if (module != null && module['id'] != null) {
      final repo = LearningModuleRepo();

      // If a user navigates backwards, want to laod in existing data that has already been saved
      final freshModuleData = await repo.getModule(module['id'].toString());

      if (freshModuleData != null) {
        setState(() {
          // Load creator_action (question type)
          if (freshModuleData['creator_action'] != null) {
            _selectedQuestionType = freshModuleData['creator_action'];
          }

          // Load inquiry (array of text)
          if (freshModuleData['inquiry'] != null && freshModuleData['inquiry'] is List) {
            final inquiryList = List<String>.from(freshModuleData['inquiry']);
            if (inquiryList.isNotEmpty) {
              // Clear the default controller and add controllers for existing data
              _controllers.clear();
              for (String text in inquiryList) {
                final controller = TextEditingController(text: text);
                _controllers.add(controller);
              }
            }
          }
        });
      }
    }
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) return 'Date not available';

    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final formatter = DateFormat('EEEE, MMMM d');
      return formatter.format(dateTime);
    } catch (e) {
      return 'Date error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetModule = widget.existingModule!;
    final moduleName = widgetModule['module_name'] ?? 'Module Name';
    final formattedDate = _formatDate(widgetModule['created_at']);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.back, color: AppColors.iconPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moduleName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),

              // Navigation and question type dropdowns
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildNavigationDropdown(),
                  _buildQuestionTypeDropdown(),
                ],
              ),
              const SizedBox(height: 16),

              // Dynamic text inputs
              ..._controllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: index == 0
                                ? 'Explain the inquiry...'
                                : 'Additional explanation...',
                            hintStyle: const TextStyle(color: AppColors.hintText),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.primary, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: false,
                          ),
                          validator: index == 0 ? (value) {
                            // Only validate the first text field - require at least one explanation
                            final hasContent = _controllers.any((ctrl) => ctrl.text.trim().isNotEmpty);
                            if (!hasContent) {
                              return 'At least one explanation must be completed';
                            }
                            return null;
                          } : null,
                        ),
                      ),
                      if (_controllers.length > 1) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            setState(() {
                              controller.dispose();
                              _controllers.removeAt(index);
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.error),
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(CupertinoIcons.minus, size: 20, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              // Add button
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        _controllers.add(TextEditingController());
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.add, size: 20, color: AppColors.iconPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Complete button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final messenger = ScaffoldMessenger.of(context);
                      final repo = LearningModuleRepo();
                      final moduleId = widgetModule['id'].toString();
                      final navigator = Navigator.of(context);

                      // Get all non-empty text from controllers
                      final allText = _controllers
                          .map((controller) => controller.text.trim())
                          .where((text) => text.isNotEmpty)
                          .toList();

                      // Save to database
                      final success = await repo.updateAnchoringPhenomenon(
                        id: moduleId,
                        creatorAction: _selectedQuestionType,
                        inquiry: allText,
                      );

                      if (success) {
                        // Navigate to next screen
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => LearningObjectiveScreen(
                              module: widgetModule,
                            ),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Failed to save anchoring phenomenon'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Complete'),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationDropdown() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNavigation,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.white,
          ),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          dropdownColor: AppColors.primary,
          items: const [
            DropdownMenuItem(
              value: 'TITLE',
              child: Text(
                'TITLE',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'ANCHORING PHENOMENON',
              child: Text(
                'ANCHORING PHENOMENON',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            if (value == 'TITLE') {
              // Go back to title (parent of AP)
              Navigator.of(context).pop();
            }
            // If ANCHORING PHENOMENON is selected, stay on current page
            setState(() {
              _selectedNavigation = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildQuestionTypeDropdown() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedQuestionType,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.blue,
          ),
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          dropdownColor: AppColors.lightBlue,
          items: const [
            DropdownMenuItem(
              value: 'WHY',
              child: Text(
                'WHY',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'HOW',
              child: Text(
                'HOW',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'WHAT',
              child: Text(
                'WHAT',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'WHEN',
              child: Text(
                'WHEN',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedQuestionType = value!;
            });
          },
        ),
      ),
    );
  }
}
