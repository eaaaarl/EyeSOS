import 'package:eyesos/features/welcome/data/models/onboarding_model.dart';
import 'package:eyesos/features/welcome/domain/entities/onboarding_entity.dart';
import 'package:eyesos/features/welcome/presentation/widgets/onboarding_slide_widget.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingEntity> _pages = [
    OnboardingModel(
      title: 'Real-Time Accident Monitoring',
      description:
          'View live heatmaps showing accident-prone areas and high-risk zones in your city.',
      icon: Icons.warning_amber_rounded,
      color: Colors.red[700]!,
      imagePath: 'assets/images/onboarding-1.png',
    ),
    OnboardingModel(
      title: 'Track Accident Hotspots',
      description:
          'Identify dangerous roads and intersections based on historical accident data.',
      icon: Icons.location_on,
      color: Colors.orange[700]!,
      imagePath: 'assets/images/onboarding-2.png',
    ),
    OnboardingModel(
      title: 'Report Road Incidents',
      description:
          'Help improve road safety by reporting accidents and hazards in real-time.',
      icon: Icons.camera_alt,
      color: Colors.blue[700]!,
      imagePath: 'assets/images/onboarding-3.png',
    ),
  ];

  void _navigateToMap() {
    context.go('/');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _navigateToMap,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView with onboarding slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingSlide(page: _pages[index]);
                },
              ),
            ),

            // Smooth Page Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: Colors.red[700]!,
                  dotColor: Colors.grey[300]!,
                  dotHeight: 10,
                  dotWidth: 10,
                  expansionFactor: 4,
                  spacing: 8,
                ),
              ),
            ),

            // Bottom Navigation Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.red[700]!, Colors.red[900]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      _navigateToMap();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastPage ? 'Get Started' : 'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
