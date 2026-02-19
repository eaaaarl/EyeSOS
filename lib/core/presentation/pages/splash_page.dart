import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/core/presentation/layouts/root_screen.dart';
import 'package:eyesos/features/welcome/presentation/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final sessionState = context.read<SessionBloc>().state;

    Widget nextScreen;
    if (sessionState is AuthAuthenticated) {
      nextScreen = const RootScreen();
    } else {
      nextScreen = const WelcomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFFFFFF,
      ), // ✅ Match native splash background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Logo appears instantly (same as native splash)
            Image.asset(
              'assets/images/splash_logo_white_background.png',
              width: 280,
              height: 280,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.remove_red_eye,
                      size: 80,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),

            // ✅ Loading indicator (only appears in Flutter splash, not native)
            Transform.translate(
              offset: const Offset(0, -50),
              child: LoadingAnimationWidget.discreteCircle(
                color: Colors.red[700]!,
                size: 40,
                secondRingColor: Colors.red[400]!,
                thirdRingColor: Colors.red[200]!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
