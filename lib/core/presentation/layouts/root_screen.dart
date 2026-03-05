import 'package:eyesos/core/presentation/widgets/connectivity_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:go_router/go_router.dart';

class RootScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: Scaffold(
        body: navigationShell,
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
                selectedIndex: navigationShell.currentIndex,
                onTabChange: (index) {
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
