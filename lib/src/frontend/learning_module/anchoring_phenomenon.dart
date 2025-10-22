import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:juniper_journal/src/frontend/learning_module/learning_objective.dart';
import 'package:juniper_journal/src/styling/app_colors.dart';

class AnchoringPhenomenon extends StatefulWidget {
  final Map<String, dynamic>? existingModule;

  const AnchoringPhenomenon({super.key, this.existingModule});

  @override
  State<AnchoringPhenomenon> createState() => _CreateAnchoringPhenomenonScreenState();
}

class _CreateAnchoringPhenomenonScreenState extends State<AnchoringPhenomenon> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgetModule = widget.existingModule!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar (back + title + subtitle)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.back),
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Basics of Climate Change',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2024),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Saturday, May 24',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF868686),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),

              // Chips row
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: const [
                  _TagChip(
                    label: 'ANCHORING PHENOMENON',
                    bg: AppColors.primary,
                    fg: AppColors.buttonPrimary,
                  ),
                  _TagChip(
                    label: 'WHY',
                    bg: AppColors.lightBlue,
                    fg: AppColors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Multiline input
              TextField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Explain the inquiry...',
                  hintStyle: const TextStyle(color: Color(0xFF808080)),
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
                  filled: false,
                ),
              ),
              const SizedBox(height: 12),

              // Small circular "+" button
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      // TODO: add your action (e.g., attach media/step)
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.add, size: 20),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    /*
                    Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LearningObjectiveScreen(
                              module: widgetModule,
                            ),
                          ),
                        ); */
                    // TODO: submit handling
                    debugPrint('Complete pressed: ${_controller.text}');
                  },
                  child: const Text('Complete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _TagChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down, size: 16, color: fg),
        ],
      ),
    );
  }
}
