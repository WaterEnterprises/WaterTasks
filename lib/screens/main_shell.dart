import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: _currentIndex == 0
          ? const HomeScreen()
          : _currentIndex == 1
              ? const DashboardScreen()
              : const SettingsScreen(),
      bottomNavigationBar: GlassContainer(
        borderRadius: BorderRadius.zero,
        opacity: 0.12,
        blurSigma: 8,
        padding: EdgeInsets.zero,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.checklist_rounded,
                  label: 'Tasks',
                  selected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                  colors: colors,
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Performance',
                  selected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                  colors: colors,
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  colors: colors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF00E5FF);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Icon(
              icon,
              size: 24,
              color: selected ? accent : colors.onSurfaceVariant,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? accent : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
