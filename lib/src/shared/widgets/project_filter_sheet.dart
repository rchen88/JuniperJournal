import 'package:flutter/material.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';

// ── FilterOption ──────────────────────────────────────────────────────────────

class FilterOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const FilterOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}

// ── Option lists ──────────────────────────────────────────────────────────────

const kSubjectOptions = [
  FilterOption(
    value: 'Environment & Sustainability',
    label: 'Environment & Sustainability',
    description:
        'Focuses on understanding and improving natural systems, including ecosystems, climate, water, and resource use, to support long-term environmental health.',
    icon: Icons.eco_outlined,
  ),
  FilterOption(
    value: 'Engineering & Design',
    label: 'Engineering & Design',
    description:
        'Centers on creating, building, and optimizing solutions that address real-world sustainability challenges through innovation, prototyping, and problem-solving.',
    icon: Icons.build_outlined,
  ),
  FilterOption(
    value: 'Energy & Systems',
    label: 'Energy & Systems',
    description:
        'Explores how energy is produced, distributed, and used, with an emphasis on efficiency, renewable technologies, and system-level thinking.',
    icon: Icons.bolt_outlined,
  ),
  FilterOption(
    value: 'Community & Built Environment',
    label: 'Community & Built Environment',
    description:
        'Focuses on how people come together to shape sustainable spaces, from hosting workshops to improving shared environments, infrastructure, and local systems.',
    icon: Icons.location_city_outlined,
  ),
];

const kPhaseOptions = [
  FilterOption(
    value: 'Discovering',
    label: 'Discovering',
    description:
        'Exploring and understanding sustainability challenges by observing systems, researching topics, and identifying opportunities for impact.',
    icon: Icons.search_outlined,
  ),
  FilterOption(
    value: 'Ideating',
    label: 'Ideating',
    description:
        'Generating ideas and designing potential solutions to address sustainability challenges through creativity and problem-solving.',
    icon: Icons.lightbulb_outline,
  ),
  FilterOption(
    value: 'Prototyping',
    label: 'Prototyping',
    description:
        'Building and experimenting with early versions of ideas to test functionality, explore solutions, and bring concepts to life.',
    icon: Icons.precision_manufacturing_outlined,
  ),
  FilterOption(
    value: 'Testing & Iterating',
    label: 'Testing & Iterating',
    description:
        'Gathering feedback, collaborating with others, and refining ideas through repeated testing, improvement, and shared learning.',
    icon: Icons.refresh_outlined,
  ),
  FilterOption(
    value: 'Implemented',
    label: 'Implemented',
    description:
        'Putting solutions into action, creating real-world impact through completed projects, measurable outcomes, and sustained change.',
    icon: Icons.check_circle_outline,
  ),
];

const kScaleOptions = [
  FilterOption(
    value: 'Small',
    label: 'Small',
    description:
        'Focused on a single action or idea, typically completed by an individual or small group, with a localized or short-term impact.',
    icon: Icons.person_outline,
  ),
  FilterOption(
    value: 'Medium',
    label: 'Medium',
    description:
        'Involves multiple steps or components, often requiring coordination or planning, with impact extending beyond a single activity or space.',
    icon: Icons.people_outline,
  ),
  FilterOption(
    value: 'Large',
    label: 'Large',
    description:
        'Spans multiple systems, groups, or locations, requiring significant planning, collaboration, or time, with broader and longer-term impact.',
    icon: Icons.public_outlined,
  ),
];

const kDifficultyOptions = [
  FilterOption(
    value: 'Easy',
    label: 'Easy',
    description:
        'Simple to start and complete, requiring minimal resources, prior knowledge, or time, and can be done independently with little planning.',
    icon: Icons.wb_sunny_outlined,
  ),
  FilterOption(
    value: 'Moderate',
    label: 'Moderate',
    description:
        'Requires some planning, effort, or learning, possibly involving multiple steps, tools, or collaboration to successfully complete.',
    icon: Icons.brightness_medium_outlined,
  ),
  FilterOption(
    value: 'Hard',
    label: 'Hard',
    description:
        'Highly involved and complex, requiring significant time, coordination, resources, or technical knowledge to execute effectively.',
    icon: Icons.brightness_high_outlined,
  ),
];

// ── ProjectFilterSheet ────────────────────────────────────────────────────────

class ProjectFilterSheet extends StatefulWidget {
  final String title;
  final List<FilterOption> options;
  final Set<String> initialSelected;
  final void Function(Set<String>) onApply;

  const ProjectFilterSheet({
    super.key,
    required this.title,
    required this.options,
    required this.initialSelected,
    required this.onApply,
  });

  @override
  State<ProjectFilterSheet> createState() => _ProjectFilterSheetState();
}

class _ProjectFilterSheetState extends State<ProjectFilterSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 1,
                height: 16,
                color: AppColors.divider,
              ),
              const Text(
                'Select All That Apply',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    size: 20, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),

          // Options
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.options.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) {
              final opt = widget.options[i];
              final isSelected = _selected.contains(opt.value);
              return InkWell(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selected.remove(opt.value);
                  } else {
                    _selected.add(opt.value);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(opt.icon,
                            size: 20, color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(Set.from(_selected));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: Text(
                _selected.isEmpty ? 'Clear Filters' : 'Apply Filters',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
