import 'dart:async';
import 'package:camera/camera.dart';
import 'package:eyesos/core/presentation/layouts/root_screen.dart';
import 'package:eyesos/core/presentation/pages/splash_page.dart';
import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/auth/presentation/pages/sign_in_page.dart';
import 'package:eyesos/features/auth/presentation/pages/sign_up_page.dart';
import 'package:eyesos/features/home/presentation/pages/accident_report_page.dart';
import 'package:eyesos/features/home/presentation/pages/camera_page.dart';
import 'package:eyesos/features/home/presentation/widgets/report_details_modal.dart';
import 'package:eyesos/features/home/presentation/pages/home_page.dart';
import 'package:eyesos/features/map/presentation/pages/maps_page.dart';
import 'package:eyesos/features/profile/presentation/pages/profile_page.dart';
import 'package:eyesos/features/profile/presentation/pages/report_history_page.dart';
import 'package:eyesos/features/welcome/presentation/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

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

String? _redirect(
  BuildContext context,
  GoRouterState state,
  SessionBloc sessionBloc,
) {
  final isLoggedIn = sessionBloc.state is AuthAuthenticated;

  // Always allow splash
  if (state.matchedLocation == '/splash') {
    return null;
  }

  // Redirect to signin if not logged in and trying to access protected routes
  if (!isLoggedIn &&
      state.matchedLocation != '/signin' &&
      state.matchedLocation != '/signup' &&
      state.matchedLocation != '/welcome') {
    return '/signin';
  }

  // Redirect to home if logged in and trying to access auth pages
  if (isLoggedIn &&
      (state.matchedLocation == '/signin' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/welcome')) {
    return '/home';
  }

  return null;
}

GoRouter createRouter(SessionBloc sessionBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(sessionBloc.stream),
    redirect: (context, state) => _redirect(context, state, sessionBloc),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
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
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: HomePage());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/maps',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: MapsPage());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: ProfilePage());
                },
              ),
            ],
          ),
        ],
      ),

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
      GoRoute(
        path: '/report-history',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideTransition(state: state, child: const ReportHistoryPage()),
      ),
    ],
  );
}
