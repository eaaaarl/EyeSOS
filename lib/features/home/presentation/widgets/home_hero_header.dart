import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:eyesos/features/home/presentation/widgets/quick_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeroHeader extends StatelessWidget {
  final String userName;
  const HomeHeroHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[700]!, Colors.red[900]!],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personalized Greeting
              Text(
                'Hello, $userName!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(),

              const SizedBox(height: 4),

              // App Name with Animation
              Row(
                children: [
                  Icon(
                    Icons.remove_red_eye,
                    color: Colors.white,
                    size: 32,
                  ).animate().scale(delay: 300.ms),
                  const SizedBox(width: 8),
                  Text(
                    'EyeSOS',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                ],
              ),

              const SizedBox(height: 12),

              // Animated Description
              DefaultTextStyle(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Report emergencies instantly with real-time alerts',
                      speed: const Duration(milliseconds: 50),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
              ),

              const SizedBox(height: 20),

              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: QuickStatsCard(
                      icon: Icons.speed,
                      label: 'Fast Response',
                      color: Colors.white,
                    ).animate().fadeIn(delay: 400.ms).slideX(),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: QuickStatsCard(
                      icon: Icons.location_on,
                      label: 'Real-time Location',
                      color: Colors.white,
                    ).animate().fadeIn(delay: 500.ms).slideX(),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: QuickStatsCard(
                      icon: Icons.camera_alt,
                      label: 'Photo Evidence',
                      color: Colors.white,
                    ).animate().fadeIn(delay: 600.ms).slideX(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
