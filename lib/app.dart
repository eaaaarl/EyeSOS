import 'package:eyesos/core/config/router.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EyeSOS',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
