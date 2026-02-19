import 'package:flutter/material.dart';

class OnboardingEntity {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String imagePath;

  OnboardingEntity({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.imagePath,
  });
}
