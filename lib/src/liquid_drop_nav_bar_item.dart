import 'package:flutter/material.dart';

/// An item in the [LiquidDropNavBar].
class LiquidDropNavBarItem {
  /// The icon to show when the item is NOT selected.
  final IconData icon;

  /// The icon to show when the item IS selected.
  final IconData activeIcon;

  /// The text label to display next to the icon when the item is active.
  final String? label;

  const LiquidDropNavBarItem({
    required this.icon,
    required this.activeIcon,
    this.label,
  });
}
