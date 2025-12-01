import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juniper_journal/main.dart';
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

      if (fresh != null && mounted) {
        final callToAction = fresh['call_to_action'];
        if (callToAction != null && callToAction is String) {
          setState(() {
            _controller.text = callToAction;
          });
        }
      }
    }
  }

  Future<void> _saveAndNavigateHome() async {
    if (!_formKey.currentState!.validate()) return;

    final module = widget.existingModule;
    if (module != null && module['id'] != null) {
      final repo = LearningModuleRepo();
      final success = await repo.updateCallToAction(
        id: module['id'].toString(),
        callToAction: _controller.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // Navigate to home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage(
            title: 'Juniper Journal'
          )),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save call to action'),
            backgroundColor: AppColors.error,
          ),
        );
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
                    onPressed: _saveAndNavigateHome,
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
