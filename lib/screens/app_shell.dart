import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'create_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Allows any descendant widget to switch the shell's bottom navigation tab.
class ShellNavigator extends InheritedWidget {
  const ShellNavigator({
    super.key,
    required this.switchTab,
    required super.child,
  });

  final ValueChanged<int> switchTab;

  static ShellNavigator? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellNavigator>();

  @override
  bool updateShouldNotify(ShellNavigator old) => switchTab != old.switchTab;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Create'),
    _NavItem(Icons.grid_view_rounded, Icons.grid_view_outlined, 'History'),
    _NavItem(Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final screens = const [
      HomeScreen(),
      CreateScreen(),
      HistoryScreen(),
      SettingsScreen(),
    ];

    return ShellNavigator(
      switchTab: (index) => setState(() => _selectedIndex = index),
      child: Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: List.generate(_destinations.length, (index) {
                final item = _destinations[index];
                final selected = _selectedIndex == index;
                return Expanded(
                  child: _NavButton(
                    item: item,
                    selected: selected,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _NavItem {
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected ? AppGradients.brand : null,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                selected ? item.activeIcon : item.inactiveIcon,
                size: 22,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white38 : AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.brandPurple
                    : (isDark ? Colors.white38 : AppColors.textMuted),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
