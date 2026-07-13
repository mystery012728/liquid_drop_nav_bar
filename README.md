# liquid_drop_nav_bar

A highly customizable Flutter bottom navigation bar featuring a smooth, organic liquid drop/metaball transition animation.

![Liquid Drop Navigation Bar Demo](https://raw.githubusercontent.com/mystery012728/liquid_drop_nav_bar/main/assets/DemoLiquideDropNavBar.gif)

## Features

* **Organic Liquid Animation**: Smooth, fluid metaball stretch and snap effects when transitioning between navigation tabs.
* **Smart Hiding/Shrinking**: Intelligently hides/shrinks the inactive icon/labels when traveling across tabs to keep the UI clean and clutter-free.
* **Customization**: Easily configure colors, height, capsule size, minimum pill width, and margins.
* **Responsive Layouts**: Designed to run cleanly across different screen dimensions without third-party layout dependencies.

## Installation

Add `liquid_drop_nav_bar` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  liquid_drop_nav_bar: ^0.0.1
```

Or run:

```bash
flutter pub add liquid_drop_nav_bar
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:liquid_drop_nav_bar/liquid_drop_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Active Index: $_currentIndex'),
      ),
      bottomNavigationBar: LiquidDropNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          LiquidDropNavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          LiquidDropNavBarItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Chats',
          ),
          LiquidDropNavBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

## Additional parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `currentIndex` | `int` | *required* | The index of the active tab. |
| `onTap` | `ValueChanged<int>` | *required* | Called when a tab is tapped. |
| `items` | `List<LiquidDropNavBarItem>` | *required* | Up to 5 navigation items. |
| `height` | `double?` | `56.0` | Overall height of the bar. |
| `capsuleHeight` | `double?` | `40.0` | Height of the traveling capsule. |
| `minCapsuleWidth` | `double?` | `56.0` | Minimum width of the selected capsule. |
| `margin` | `EdgeInsetsGeometry?` | *dynamic* | Custom margins for positioning. |
