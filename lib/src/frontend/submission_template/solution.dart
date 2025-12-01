import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';

class SolutionScreen extends StatefulWidget {
  const SolutionScreen({super.key});

  @override
  State<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends State<SolutionScreen> {
  final TextEditingController _bodyCtrl =
      TextEditingController(text: "This is our product for the terrarium project. Using materials you can easily find at home such as a mason jar, dirt, grass, and carefully picked rocks. We c");

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Header ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Terrarium Project",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Saturday, May 24",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.lightGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    child: const Text("Done"),
                  ),
                ],
              ),
            ),

            // ---------- Chips Row ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // SOLUTION chip (light green with arrow)
                  _Pill(
                    label: "SOLUTION",
                    trailing: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF2E7D32),
                    ),
                    bg: const Color(0xFFE9F7EE),
                    borderColor: const Color(0xFFD4ECDC),
                    fg: const Color(0xFF2E7D32),
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),

                  // EDUCATIONAL IMPACT chip (solid green)
                  _Pill(
                    label: "EDUCATIONAL IMPACT",
                    bg: const Color(0xFF4CAF50),
                    fg: Colors.white,
                    onTap: () {},
                  ),
                  const Spacer(),

                  // + pill
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F3F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Main Content ----------
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          // Image with rounded corners
                          ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: Container(
                                color: const Color(0xFFF2F4F7),
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey.shade400,
                                    size: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section Title
                          Text(
                            "Solution",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Thin divider
                          Container(
                            height: 1,
                            color: const Color(0xFFE5E5E5),
                          ),
                          const SizedBox(height: 10),

                          // Body text
                          TextField(
                            controller: _bodyCtrl,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF8E8E93),
                              height: 1.35,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),

                          const SizedBox(height: 88),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Bottom Toolbar ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _BottomToolbar(
                items: [
                  _Tool(icon: Icons.text_fields_rounded, onTap: () {}),
                  _Tool(icon: Icons.crop_square_rounded, onTap: () {}),
                  _Tool(icon: Icons.brush_outlined, onTap: () {}),
                  _Tool(icon: Icons.photo_camera_outlined, onTap: () {}),
                  _Tool(icon: Icons.image_outlined, onTap: () {}),
                  _Tool(icon: Icons.table_chart_outlined, onTap: () {}),
                  _Tool(icon: Icons.functions_rounded, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Reusable Components --------------------

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color? borderColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.borderColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.1,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final VoidCallback? onTap;

  _Tool({required this.icon, this.onTap});
}

/// Bottom toolbar styled like the screenshot:
/// green pill, white icons, evenly spaced.
class _BottomToolbar extends StatelessWidget {
  final List<_Tool> items;

  const _BottomToolbar({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF5BA968), // iOS-y green bar
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (t) => IconButton(
                iconSize: 24,
                splashRadius: 26,
                icon: Icon(
                  t.icon,
                  color: Colors.white,
                ),
                onPressed: t.onTap,
              ),
            )
            .toList(),
      ),
    );
  }
}
