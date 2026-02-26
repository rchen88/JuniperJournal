import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const UserAvatar({super.key, this.avatarUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE6E8EC),
      backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
      child: hasImage
          ? null
          : Icon(
              Icons.person,
              size: radius * 0.9,
              color: const Color(0xFF4A4A4A),
            ),
    );
  }
}
