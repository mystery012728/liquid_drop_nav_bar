import 'package:flutter/material.dart';
import 'package:liquid_drop_nav_bar/liquid_drop_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Drop Nav Bar Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Axis _layoutAxis = Axis.vertical;
  int _itemCount = 4;

  // The full list of potential navigation items (up to 5)
  final List<LiquidDropNavBarItem> _allNavBarItems = const [
    LiquidDropNavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    LiquidDropNavBarItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Search',
    ),
    LiquidDropNavBarItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Likes',
    ),
    LiquidDropNavBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
    LiquidDropNavBarItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Generate the items to display based on the selected count
    final activeItems = _allNavBarItems.take(_itemCount).toList();

    // Clamp current index if it exceeds the new length
    if (_currentIndex >= _itemCount) {
      _currentIndex = _itemCount - 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquid Drop Nav Bar Playground'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Active Tab: ${activeItems[_currentIndex].label}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Index: $_currentIndex',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Controls Section
              const Text(
                'Layout Axis Format',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SegmentedButton<Axis>(
                segments: const [
                  ButtonSegment<Axis>(
                    value: Axis.horizontal,
                    label: Text('Horizontal (Row)'),
                    icon: Icon(Icons.align_horizontal_left),
                  ),
                  ButtonSegment<Axis>(
                    value: Axis.vertical,
                    label: Text('Vertical (Column)'),
                    icon: Icon(Icons.align_vertical_bottom),
                  ),
                ],
                selected: {_layoutAxis},
                onSelectionChanged: (Set<Axis> newSelection) {
                  setState(() {
                    _layoutAxis = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Number of Options',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 2, label: Text('2 Items')),
                  ButtonSegment<int>(value: 3, label: Text('3 Items')),
                  ButtonSegment<int>(value: 4, label: Text('4 Items')),
                  ButtonSegment<int>(value: 5, label: Text('5 Items')),
                ],
                selected: {_itemCount},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _itemCount = newSelection.first;
                  });
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: LiquidDropNavBar(
        currentIndex: _currentIndex,
        layoutAxis: _layoutAxis,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: activeItems,
      ),
    );
  }
}
