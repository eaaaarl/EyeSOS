import 'package:camera/camera.dart';
import 'package:eyesos/core/presentation/layouts/root_screen.dart';
import 'package:eyesos/core/presentation/pages/splash_page.dart';
import 'package:eyesos/features/auth/presentation/pages/sign_in_page.dart';
import 'package:eyesos/features/auth/presentation/pages/sign_up_page.dart';
import 'package:eyesos/features/home/presentation/pages/accident_report_page.dart';
import 'package:eyesos/features/home/presentation/pages/camera_page.dart';
import 'package:eyesos/features/home/presentation/widgets/report_details_modal.dart';
import 'package:eyesos/features/home/presentation/pages/home_page.dart';
import 'package:eyesos/features/profile/presentation/pages/profile_page.dart';
import 'package:eyesos/features/root/screens/maps_tab.dart';
import 'package:eyesos/features/welcome/presentation/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// Reusable slide transition
CustomTransitionPage _slideTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
  );
}

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Auth and onboarding — no custom transition needed, go() is used here
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),

    // Shell — tabs persist in memory, no animation between them
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return RootScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            // Fixed: changed '/' to '/maps' to avoid root conflict
            GoRoute(
              path: '/maps',
              builder: (context, state) => const MapsTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // Routes that push OVER the shell — use push(), slide animation
    GoRoute(
      path: '/accident-report',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _slideTransition(state: state, child: const AccidentReportPage()),
    ),
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _slideTransition(
        state: state,
        child: CameraScreen(camera: state.extra as CameraDescription),
      ),
    ),
    GoRoute(
      path: '/gallery',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _slideTransition(
          state: state,
          child: FullScreenImageGallery(
            imageUrls: extra['imageUrls'] as List<String>,
            initialIndex: extra['initialIndex'] as int,
          ),
        );
      },
    ),
  ],
);
