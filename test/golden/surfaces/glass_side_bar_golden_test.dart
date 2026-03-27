import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('GlassSideBar Golden Tests', () {
    testWidgets('Standard GlassSideBar appearance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black, // Dark bg for glass contrast
            body: Stack(
              children: [
                // Colorful background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Sidebar
                GlassSideBar(
                  width: 250,
                  header: const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text('My App',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ),
                  footer: GlassButton(
                    onTap: () {},
                    label: 'Logout',
                    icon: Icon(Icons.logout),
                    width: double.infinity,
                  ),
                  children: [
                    GlassSideBarItem(
                      icon: Icon(Icons.home),
                      label: 'Dashboard',
                      isSelected: true,
                      onTap: () {},
                    ),
                    GlassSideBarItem(
                      icon: Icon(Icons.folder),
                      label: 'Projects',
                      onTap: () {},
                    ),
                    GlassSideBarItem(
                      icon: Icon(Icons.people),
                      label: 'Team',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(GlassSideBar),
        matchesGoldenFile('goldens/glass_side_bar_standard.png'),
      );
    });
  });
}
