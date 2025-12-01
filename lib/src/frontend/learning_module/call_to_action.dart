import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:juniper_journal/src/backend/db/repositories/learning_module_repo.dart';
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
  final List<TextEditingController> _controllers = [TextEditingController()];
  final _formKey = GlobalKey<FormState>();

  String _selectedNavigation = 'CALL TO ACTION';
  String _selectedQuestionType = 'WHY';

  // NEW: for the project URL
  final TextEditingController _projectUrlCtrl = TextEditingController();
  String? _projectUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingData(); // read from supabase
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    _projectUrlCtrl.dispose(); // NEW
    super.dispose();
  }

  void _loadExistingData() async {
    final module = widget.existingModule;
    if (module != null && module['id'] != null) {
      final repo = LearningModuleRepo();
      final fresh = await repo.getModule(module['id'].toString());

      if (!mounted) return;

      if (fresh != null) {
        setState(() {
          // if you still want to track this:
          if (fresh['creator_action'] != null) {
            _selectedQuestionType = fresh['creator_action'];
          }

          // CHANGED: load from call_to_action instead of inquiry
          if (fresh['call_to_action'] != null &&
              fresh['call_to_action'] is List) {
            final list = List<String>.from(fresh['call_to_action']);
            if (list.isNotEmpty) {
              _controllers
                ..clear()
                ..addAll(list.map((t) => TextEditingController(text: t)));
            }
          }

          // NEW: load project_url
          _projectUrl = fresh['project_url'] as String?;
          _projectUrlCtrl.text = _projectUrl ?? '';
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

                // dynamic text areas
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
                                  ? 'End the module with a clear next step that guides the user on what to do or explore...'
                                  : 'Additional detail...',
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
                                  width: 1.5),
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
                                      return 'At least one call to action must be completed';
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

                const SizedBox(height: 6),

                // “Link a Project…” -> opens URL dialog
                InkWell(
                  onTap: () async {
                    await _showProjectLinkDialog(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/link_project.png',
                        height: 28,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Link a Project...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // show current URL if present
                if (_projectUrl != null &&
                    _projectUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _projectUrl!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],

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
      final allText = _controllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

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
        callToAction: allText,
        projectUrl: _projectUrlCtrl.text.trim().isEmpty
            ? null
            : _projectUrlCtrl.text.trim(),
      );

      if (ok) {
        
        // If instead you want to go all the way back to the first page:
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MyHomePage(
              title: 'Juniper Journal',
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
      // 🔴 This will show the REAL Supabase error
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


  // NEW: dialog to add/edit project URL
  Future<void> _showProjectLinkDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Link a Project'),
          content: TextField(
            controller: _projectUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Project URL',
              hintText: 'https://...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _projectUrl = _projectUrlCtrl.text.trim();
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
