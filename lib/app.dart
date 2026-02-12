import 'package:eyesos/core/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EyeSOS',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
