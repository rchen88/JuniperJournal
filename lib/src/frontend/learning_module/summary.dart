import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juniper_journal/src/frontend/learning_module/learning_objective.dart';
import 'package:juniper_journal/src/styling/app_colors.dart';
import 'package:juniper_journal/src/backend/db/repositories/learning_module_repo.dart';
import 'package:intl/intl.dart';

class Summary extends StatefulWidget {
  final Map<String, dynamic>? existingModule;

  const Summary({super.key, this.existingModule});

  @override
  State<Summary> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<Summary> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  final _formKey = GlobalKey<FormState>();

  // this screen is SUMMARY now
  String _selectedNavigation = 'SUMMARY';
  String _selectedQuestionType = 'WHY';

  @override
  void initState() {
    super.initState();
    _loadExistingData(); // fetch from Supabase, but only read
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // KEEP: read from Supabase so we prefill
  void _loadExistingData() async {
    final module = widget.existingModule;
    if (module != null && module['id'] != null) {
      final repo = LearningModuleRepo();

      // pull latest data from backend
      final freshModuleData = await repo.getModule(module['id'].toString());

      if (freshModuleData != null) {
        setState(() {
          // Load question type
          if (freshModuleData['creator_action'] != null) {
            _selectedQuestionType = freshModuleData['creator_action'];
          }

          // Load inquiry list
          if (freshModuleData['inquiry'] != null &&
              freshModuleData['inquiry'] is List) {
            final inquiryList = List<String>.from(freshModuleData['inquiry']);
            if (inquiryList.isNotEmpty) {
              _controllers.clear();
              for (final text in inquiryList) {
                _controllers.add(TextEditingController(text: text));
              }
            }
          }
        });
      }
    }
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) {
      return DateFormat('EEEE, MMMM d').format(DateTime.now());
    }

    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      return DateFormat('EEEE, MMMM d').format(dateTime);
    } catch (e) {
      return 'Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final widgetModule = widget.existingModule ?? {};
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
                      icon: const Icon(
                        CupertinoIcons.back,
                        color: AppColors.iconPrimary,
                      ),
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
                  ],
                ),
                const SizedBox(height: 16),

                // Summary + question type
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildNavigationDropdown()
                  ],
                ),
                const SizedBox(height: 16),

                // Dynamic text fields
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
                                  ? 'Write the summary...'
                                  : 'Additional summary detail...',
                              hintStyle:
                                  const TextStyle(color: AppColors.hintText),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: index == 0
                                ? (value) {
                                    final hasContent = _controllers.any(
                                      (ctrl) =>
                                          ctrl.text.trim().isNotEmpty,
                                    );
                                    if (!hasContent) {
                                      return 'At least one summary must be completed';
                                    }
                                    return null;
                                  }
                                : null,
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
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.minus,
                                  size: 20,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                // Add another summary
                

                // Complete: DON'T update Supabase, just navigate
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final allText = _controllers
                            .map((c) => c.text.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();

                        final updatedModule = {
                          ...widgetModule,
                          'creator_action': _selectedQuestionType,
                          'inquiry': allText,
                        };

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LearningObjectiveScreen(
                              module: updatedModule,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Generate Summary Report'),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNavigation,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Colors.green,
          ),
          style: const TextStyle(
            color: Colors.green,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          dropdownColor: Colors.green[50],
          items: const [
            DropdownMenuItem(
              value: 'TITLE',
              child: Text(
                'TITLE',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'SUMMARY',
              child: Text(
                'SUMMARY',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            if (value == 'TITLE') {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _selectedNavigation = value;
              });
            }
          },
        ),
      ),
    );
  }

}
