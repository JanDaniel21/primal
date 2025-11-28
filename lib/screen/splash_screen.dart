import 'package:flutter/material.dart';
import 'landingpage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  bool _hasTapped = false;

  @override
  void initState() {
    super.initState();

    // Fade-in on start
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  void _goToLandingPage() {
    if (_hasTapped) return; // prevents double tap issues
    _hasTapped = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LandingPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(          // <<--- TAP ANYWHERE
        behavior: HitTestBehavior.opaque,
        onTap: _goToLandingPage,

        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 2),

          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B7B4A), // Green
                  Color(0xFF064D76), // Blue
                ],
              ),
            ),

            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Primal",
                    style: TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "Banking Back to its Roots",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFFFE66D), // Yellow tagline
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Optional: "Tap anywhere to continue"
                  Text(
                    "Tap anywhere to continue",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
