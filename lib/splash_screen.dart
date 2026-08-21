import 'package:flutter/material.dart';
import 'package:touristpro/login_page.dart';
import 'dart:async';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(

        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            "assets/splash3_bg.jpg",
            fit: BoxFit.fill,
          ),

          // Dark Overlay
          Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),

          // App Logo & Name
          AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(seconds: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.travel_explore, color: Colors.white, size: 80),
                SizedBox(height: 20),
                // Text(
                //   "MahaExplore",
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: 32,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ],
            ),
          )
        ],
      ),
    );
  }
}