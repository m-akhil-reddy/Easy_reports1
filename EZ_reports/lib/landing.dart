import 'package:flutter/material.dart';
import 'dart:math';
import 'login.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  Animation<double>? _scaleAnimation; // ✅ Made nullable
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));


    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      _scaleController.forward();
    });

    // Start wave animation after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      _waveController.forward();
    });

    // Navigate to next page after wave animation completes (2s delay + 5s animation = 7s total)
    Future.delayed(const Duration(milliseconds: 7000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1f2b5b),
              Color(0xFF1f2b5b),
              Color(0xFF1f2b5b),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 100),
              Expanded(
                flex: 2,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: _scaleAnimation == null
                        ? const SizedBox.shrink()
                        : ScaleTransition(
                            scale: _scaleAnimation!,
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 300,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // Bottom section with animated dots
              Expanded(
                flex: 1,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _waveAnimation,
                              builder: (context, child) {
                                double waveOffset = _waveAnimation.value;
                                double dotOffset = (index * 0.3) + waveOffset;
                                double yOffset =
                                    sin(dotOffset * 2 * pi) * 15;

                                return Transform.translate(
                                  offset: Offset(0, yOffset),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2720ff),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2720ff)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

