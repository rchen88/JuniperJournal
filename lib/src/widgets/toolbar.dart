import 'package:flutter/material.dart';
import '../styling/app_colors.dart';

/// A toolbar for the Concept Exploration page that allows users to build their own modules.
/// Features include inserting textboxes, resizing elements, camera/photo upload, math equations, and tables.
class ConceptExplorationToolbar extends StatelessWidget {
  final VoidCallback? onCamera;
  final VoidCallback? onInsertMath;
  final VoidCallback? onInsertTable;

  const ConceptExplorationToolbar({
    super.key,
    this.onCamera,
    this.onInsertMath,
    this.onInsertTable,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 62,
          decoration: ShapeDecoration(
            color: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(64),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ToolbarButton(
                icon: Icons.camera_alt,
                onPressed: onCamera,
              ),
              _ToolbarButton(
                icon: Icons.functions,
                onPressed: onInsertMath,
              ),
              _ToolbarButton(
                icon: Icons.table_chart,
                onPressed: onInsertTable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual toolbar button with icon
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: AppColors.white,
          size: 26,
        ),
      ),
    );
  }
}
