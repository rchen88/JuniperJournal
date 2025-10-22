import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';

class ThreeDLearning extends StatefulWidget {
  const ThreeDLearning({super.key});

  @override
  State<ThreeDLearning> createState() => _ThreeDLearningState();
}

class _ThreeDLearningState extends State<ThreeDLearning> {
  // ---------------- Options ----------------
  final List<String> _dciOptions = const [
    'Environment & Sustainability',
    'Engineering & Design',
    'Energy & Systems',
    'Community & Built Environment',
  ];

  final List<String> _sepOptions = const [
    'Asking Questions and Defining Problems',
    'Developing and Using Models',
    'Planning and Carrying Out Investigations',
    'Analyzing and Interpreting Data',
    'Using Mathematics and Computational Thinking',
    'Constructing Explanations and Designing Solutions',
    'Engaging in Argument from Evidence',
    'Obtaining, Evaluating, and Communicating Information',
  ];

  final List<String> _cccOptions = const [
    'Patterns',
    'Cause and Effect',
    'Algorithms and Equations',
    'Scale, Proportion, and Quantity',
    'Systems and System Models',
    'Energy and Matter',
    'Structure and Function',
    'Stability and Change',
  ];

  // ------------- Dynamic selections (multiple) -------------
  // Start with one empty pill for each section
  final List<String?> _dci = [null];
  final List<String?> _sep = [null];
  final List<String?> _ccc = [null];

  // ---------------- Utilities ----------------
  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekday = weekdays[now.weekday % 7];
    final month = months[now.month - 1];
    return '$weekday, $month ${now.day}';
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String> onPicked,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final o = options[i];
                      final selected = o == current;
                      return ListTile(
                        title: Text(
                          o,
                          style: TextStyle(
                            color: AppColors.textPrimary.withOpacity(selected ? 1 : 0.95),
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check, color: AppColors.border)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(o),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (picked != null && picked != current) onPicked(picked);
  }

  // Open a picker and set the selection at list[index]
  Future<void> _editItem({
    required List<String?> list,
    required int index,
    required String title,
    required List<String> options,
  }) async {
    await _pickOption(
      title: title,
      options: options,
      current: list[index],
      onPicked: (v) => setState(() => list[index] = v),
    );
  }

  // Add a new pill for the section (and immediately open picker)
  Future<void> _addItem({
    required List<String?> list,
    required String title,
    required List<String> options,
  }) async {
    setState(() => list.add(null));
    final newIndex = list.length - 1;
    await _editItem(
      list: list,
      index: newIndex,
      title: title,
      options: options,
    );
  }

  // Remove a pill; if list becomes empty, add a blank one back
  void _removeItem(List<String?> list, int index) {
    setState(() {
      list.removeAt(index);
      if (list.isEmpty) {
        list.add(null);
      }
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.border),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            children: [
              // Title + date
              const Text(
                'Foundations of Sustainability',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getFormattedDate(),
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // LEARNING pill
              _StatusPill(
                label: 'LEARNING',
                icon: Icons.expand_more,
                onTap: () {},
              ),
              const SizedBox(height: 24),

              // -------- DCI --------
              const _SectionHeader('Disciplinary Core Ideas (DCI)'),
              ..._dci.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoundedChoicePill(
                    label: e.value ?? 'Select DCI',
                    onTap: () => _editItem(
                      list: _dci,
                      index: e.key,
                      title: 'Select DCI',
                      options: _dciOptions,
                    ),
                    onRemove: () => _removeItem(_dci, e.key),
                  ),
                ),
              ),
              _AddCircleButton(
                onTap: () => _addItem(
                  list: _dci,
                  title: 'Select DCI',
                  options: _dciOptions,
                ),
              ),

              // -------- SEP --------
              const SizedBox(height: 22),
              const _SectionHeader('Science and Engineering Practices (SEP)'),
              ..._sep.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoundedChoicePill(
                    label: e.value ?? 'Select SEP',
                    onTap: () => _editItem(
                      list: _sep,
                      index: e.key,
                      title: 'Select SEP',
                      options: _sepOptions,
                    ),
                    onRemove: () => _removeItem(_sep, e.key),
                  ),
                ),
              ),
              _AddCircleButton(
                onTap: () => _addItem(
                  list: _sep,
                  title: 'Select SEP',
                  options: _sepOptions,
                ),
              ),

              // -------- CCC --------
              const SizedBox(height: 22),
              const _SectionHeader('Cross Cutting Concepts (CCC)'),
              ..._ccc.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoundedChoicePill(
                    label: e.value ?? 'Select CCC',
                    onTap: () => _editItem(
                      list: _ccc,
                      index: e.key,
                      title: 'Select CCC',
                      options: _cccOptions,
                    ),
                    onRemove: () => _removeItem(_ccc, e.key),
                  ),
                ),
              ),
              _AddCircleButton(
                onTap: () => _addItem(
                  list: _ccc,
                  title: 'Select CCC',
                  options: _cccOptions,
                ),
              ),

              // Complete button
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Module marked complete')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.buttonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- UI widgets ---------- */

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoundedChoicePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _RoundedChoicePill({
    required this.label,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightBlue,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              // remove button (left)
              if (onRemove != null)
                InkResponse(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.close, size: 18, color: Colors.black38),
                  ),
                )
              else
                const SizedBox(width: 30),

              // label centered
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // chevron (right)
              const Padding(
                padding: EdgeInsets.only(left: 6.0),
                child: Icon(Icons.expand_more, color: AppColors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatusPill({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.accent.withOpacity(0.25),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Center(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black12.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 18, color: Colors.black26),
          ),
        ),
      ),
    );
  }
}
