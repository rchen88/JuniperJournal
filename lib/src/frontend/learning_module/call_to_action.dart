import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:juniper_journal/src/backend/db/repositories/learning_module_repo.dart';
import 'package:juniper_journal/src/frontend/home_page/home.dart';
import 'package:juniper_journal/src/frontend/learning_module/learning_objective.dart';
import 'package:juniper_journal/src/frontend/learning_module/summary.dart';
import 'package:juniper_journal/src/styling/app_colors.dart';
import 'package:juniper_journal/src/frontend/learning_module/create_lm_template.dart';
import 'package:juniper_journal/src/frontend/learning_module/anchoring_phenomenon.dart';
import 'package:juniper_journal/src/frontend/learning_module/3d_learning.dart';
import 'package:juniper_journal/src/frontend/learning_module/concept_exploration.dart';
import 'package:juniper_journal/src/frontend/learning_module/activity.dart';
import 'package:juniper_journal/src/frontend/learning_module/assessment.dart';
import 'package:juniper_journal/main.dart';



class CallToAction extends StatefulWidget {
  final Map<String, dynamic>? existingModule;

  const CallToAction({super.key, this.existingModule});

  @override
  State<CallToAction> createState() => _CallToActionScreenState();
}

class _CallToActionScreenState extends State<CallToAction> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedNavigation = 'CALL TO ACTION';

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadExistingData() async {
    final module = widget.existingModule;
    if (module != null && module['id'] != null) {
      final repo = LearningModuleRepo();
      final fresh = await repo.getModule(module['id'].toString());

      if (!mounted) return;

      if (fresh != null && fresh['call_to_action'] != null) {
        setState(() {
          _controller.text = fresh['call_to_action'].toString();
        });
      }
    }
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) {
      return DateFormat('EEEE, MMMM d').format(DateTime.now());
    }
    try {
      return DateFormat('EEEE, MMMM d')
          .format(DateTime.parse(createdAt).toLocal());
    } catch (_) {
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
                // header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.back,
                        color: AppColors.buttonPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
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

                // chips
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildNavigationDropdown(widgetModule),
                  ],
                ),
                const SizedBox(height: 16),

                // Single text area for call to action
                TextFormField(
                  controller: _controller,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'End the module with a clear next step that guides the user on what to do or explore...',
                    hintStyle: const TextStyle(color: AppColors.hintText),
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
                        width: 1,
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Call to action must be completed';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // complete
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
                    ),
                    onPressed: () async {
  if (_formKey.currentState!.validate()) {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repo = LearningModuleRepo();
      final widgetModule = widget.existingModule ?? {};
      final moduleId = widgetModule['id']?.toString();

      if (moduleId == null || moduleId == 'null') {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Module ID missing – cannot save call to action'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final ok = await repo.updateCallToAction(
        id: moduleId,
        callToAction: _controller.text.trim(),
      );

      if (ok) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeShellScreen(
            ),
          ),
          (route) => false,
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to save call to action'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Error saving call to action: $e');
      debugPrint('Stack trace: $st');

      messenger.showSnackBar(
        SnackBar(
          content: Text('Error saving call to action: $e'),
          backgroundColor: Colors.red,
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

 Widget _buildNavigationDropdown(Map<String, dynamic> module) {
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
          size: 20,
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
            child: Text('TITLE'),
          ),
          DropdownMenuItem(
            value: 'ANCHORING PHENOMENON',
            child: Text('ANCHORING PHENOMENON'),
          ),
          DropdownMenuItem(
            value: 'OBJECTIVE',
            child: Text('OBJECTIVE'),
          ),
          DropdownMenuItem(
            value: 'LEARNING',
            child: Text('LEARNING'),
          ),
          DropdownMenuItem(
            value: 'CONCEPT EXPLORATION',
            child: Text('CONCEPT EXPLORATION'),
          ),
          DropdownMenuItem(
            value: 'ACTIVITY',
            child: Text('ACTIVITY'),
          ),
          DropdownMenuItem(
            value: 'CALL TO ACTION',   // 👈 exactly once
            child: Text('CALL TO ACTION'),
          ),
          DropdownMenuItem(
            value: 'ASSESSMENT',
            child: Text('ASSESSMENT'),
          ),
          DropdownMenuItem(
            value: 'SUMMARY',
            child: Text('SUMMARY'),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _selectedNavigation = value;
          });

          if (value == 'TITLE') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreateTemplateScreen(
                  existingModule: module,
                ),
              ),
            );
          } else if (value == 'ANCHORING PHENOMENON') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AnchoringPhenomenon(
                  existingModule: module,
                ),
              ),
            );
          } else if (value == 'OBJECTIVE') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LearningObjectiveScreen(
                  module: module,
                ),
              ),
            );
          } else if (value == 'LEARNING') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ThreeDLearning(
                  module: module,
                ),
              ),
            );
          } else if (value == 'CONCEPT EXPLORATION') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ConceptExplorationScreen(
                  module: module,
                ),
              ),
            );
          } else if (value == 'ACTIVITY') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ActivityScreen(
                  module: module,
                ),
              ),
            );
          } else if (value == 'ASSESSMENT') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Assessment(
                  module: module,
                ),
              ),
            );
          } else if (value == 'SUMMARY') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Summary(
                  module: module,
                ),
              ),
            );
          }
        },
      ),
    ),
  );
}


}
