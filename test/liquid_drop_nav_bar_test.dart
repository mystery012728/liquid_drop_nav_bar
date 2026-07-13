import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_drop_nav_bar/liquid_drop_nav_bar.dart';

void main() {
  testWidgets('LiquidDropNavBar renders all items and responds to taps',
      (WidgetTester tester) async {
    int tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LiquidDropNavBar(
            currentIndex: 0,
            onTap: (index) {
              tappedIndex = index;
            },
            items: const [
              LiquidDropNavBarItem(
                icon: Icons.home,
                activeIcon: Icons.home_filled,
                label: 'Home',
              ),
              LiquidDropNavBarItem(
                icon: Icons.search,
                activeIcon: Icons.search,
                label: 'Search',
              ),
            ],
          ),
        ),
      ),
    );

    // Verify both items render
    expect(find.byIcon(Icons.home_filled), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Tap the search item
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(tappedIndex, 1);
  });
}
