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

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
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
            GoRoute(path: '/', builder: (context, state) => const MapsTab()),
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
    GoRoute(
      path: '/accident-report',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccidentReportPage(),
    ),
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final camera = state.extra as CameraDescription;
        return CameraScreen(camera: camera);
      },
    ),
    GoRoute(
      path: '/gallery',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final imageUrls = extra['imageUrls'] as List<String>;
        final initialIndex = extra['initialIndex'] as int;
        return FullScreenImageGallery(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        );
      },
    ),
  ],
);
