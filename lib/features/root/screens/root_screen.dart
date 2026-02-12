import 'package:eyesos/core/widgets/connectivity_banner_widget.dart';
import 'package:eyesos/features/root/screens/home_tab.dart';
import 'package:eyesos/features/root/screens/profile_tab.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'maps_tab.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 1;
  final List<Widget> _tabs = const [HomeTab(), MapsTab(), ProfileTab()];

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      // Wrap the entire Scaffold
      child: Scaffold(
        body: _tabs[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 12,
              ),
              child: GNav(
                rippleColor: Colors.red[300]!,
                hoverColor: Colors.red[100]!,
                gap: 8,
                activeColor: Colors.white,
                iconSize: 24,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Colors.red[700]!,
                color: Colors.grey[600],
                tabs: const [
                  GButton(icon: Icons.home, text: 'Home'),
                  GButton(icon: Icons.map, text: 'Maps'),
                  GButton(icon: Icons.person, text: 'Profile'),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
