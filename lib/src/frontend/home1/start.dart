import 'package:flutter/material.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF6BB578);

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------- Floating "+" Button ----------
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 72,
        width: 72,
        child: FloatingActionButton(
          elevation: 4,
          shape: const CircleBorder(),
          backgroundColor: green,
          onPressed: () {},
          child: const Icon(Icons.add, size: 32),
        ),
      ),

      // ---------- Bottom Navigation ----------
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavIcon(
                icon: Icons.home_outlined,
                isActive: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _BottomNavIcon(
                icon: Icons.landscape_outlined,
                isActive: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              const SizedBox(width: 40), // space for notch
              _BottomNavIcon(
                icon: Icons.article_outlined,
                isActive: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _BottomNavIcon(
                icon: Icons.person_outline,
                isActive: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),

      // ---------- BODY ----------
      body: SafeArea(
        child: Column(
          children: [
            // ---------- FIXED TOP BAR ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    icon: const Icon(Icons.search, size: 28),
                  ),
                  const Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 26),
                  ),
                ],
              ),
            ),

            // ---------- EMPTY (OPTIONALLY SCROLLABLE) MIDDLE AREA ----------
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  // this just gives you a white canvas to build on later
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple widget for bottom icons
class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF6BB578);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Icon(
          icon,
          size: 28,
          color: isActive ? green : Colors.black54,
        ),
      ),
    );
  }
}
