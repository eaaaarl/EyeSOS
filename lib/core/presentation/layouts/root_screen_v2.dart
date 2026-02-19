import 'package:eyesos/features/profile/presentation/pages/profile_page.dart';
import 'package:eyesos/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import '../../../features/root/screens/maps_tab.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class RootScreenV2 extends StatefulWidget {
  const RootScreenV2({super.key});

  @override
  State<RootScreenV2> createState() => _RootScreenV2State();
}

class _RootScreenV2State extends State<RootScreenV2> {
  int _selectedIndex = 1; // Default to Maps tab
  final List<Widget> _tabs = const [HomePage(), MapsTab(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Crucial: extendBody allows the screen content to show behind the curves
      extendBody: true,
      body: _tabs[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 70.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.map, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        color: Colors.red[700]!, // The bar color
        buttonBackgroundColor: Colors.red[700], // The floating button color
        backgroundColor: Colors.transparent, // Background of the "gap"
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
