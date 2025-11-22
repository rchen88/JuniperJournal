import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juniper_journal/src/frontend/learning_module/learning_objective.dart';
import 'package:juniper_journal/src/styling/app_colors.dart';
import 'package:juniper_journal/src/backend/db/repositories/learning_module_repo.dart';
import 'package:intl/intl.dart';

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
    super.dispose();
  }

  void _loadExistingData() async {
    final module = widget.existingModule;
    if (module != null && module['id'] != null) {
      final repo = LearningModuleRepo();
      final fresh = await repo.getModule(module['id'].toString());

      if (fresh != null) {
        setState(() {
          if (fresh['creator_action'] != null) {
            _selectedQuestionType = fresh['creator_action'];
          }
          if (fresh['inquiry'] != null && fresh['inquiry'] is List) {
            final list = List<String>.from(fresh['inquiry']);
            if (list.isNotEmpty) {
              _controllers
                ..clear()
                ..addAll(list.map((t) => TextEditingController(text: t)));
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
                      icon: const Icon(CupertinoIcons.back,
                          color: AppColors.iconPrimary),
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
                    _buildNavigationDropdown()
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

                // 👇 your “Link a Project…” row goes here
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    // TODO: open project picker or dialog
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // use your asset name here
                      // make sure you add it to pubspec.yaml
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
                            builder: (context) =>
                                LearningObjectiveScreen(module: updatedModule),
                          ),
                        );
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNavigation,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Colors.green),
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
              value: 'CALL TO ACTION',
              child: Text('CALL TO ACTION'),
            ),
          ],
          onChanged: (val) {
            if (val == null) return;
            if (val == 'TITLE') {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _selectedNavigation = val;
              });
            }
          },
        ),
      ),
    );
  }

  
}
