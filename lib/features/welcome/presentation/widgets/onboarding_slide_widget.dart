import 'package:eyesos/features/welcome/domain/entities/onboarding_entity.dart';
import 'package:flutter/material.dart';

class OnboardingSlide extends StatelessWidget {
  final OnboardingEntity page;

  const OnboardingSlide({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image instead of icon
          Image.asset(
            page.imagePath, // Use imagePath from your model
            width: 280,
            height: 280,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: page.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(page.icon, size: 100, color: page.color),
              );
            },
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
