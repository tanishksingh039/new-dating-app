import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';
import '../../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _logoController.forward();

    // Navigate after delay to wrapper (checks auth status)
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/wrapper');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFFC06C84),
              Color(0xFF6C5B7B),
              Color(0xFF355C7D),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles in background
            ...List.generate(20, (index) {
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  final progress = (_particleController.value + index * 0.05) % 1.0;
                  final x = size.width * (0.1 + (index % 5) * 0.2);
                  final y = size.height * progress;
                  final opacity = (1 - progress) * 0.6;

                  return Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: opacity,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20 + (index % 3) * 10,
                      ),
                    ),
                  );
                },
              );
            }),

            // Floating circles
            Positioned(
              top: -100,
              right: -100,
              child: Spin(
                infinite: true,
                duration: const Duration(seconds: 20),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -150,
              left: -150,
              child: Spin(
                infinite: true,
                duration: const Duration(seconds: 15),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with glow effect
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _glowAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(_glowAnimation.value * 0.6),
                                  blurRadius: 40 * _glowAnimation.value,
                                  spreadRadius: 10 * _glowAnimation.value,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo/Picsart_25-11-09_00-12-02-037.jpg',
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // App name with crazy animation
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 1000),
                    child: ElasticIn(
                      delay: const Duration(milliseconds: 800),
                      child: const Text(
                        'ShooLuv',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tagline with slide animation
                  SlideInLeft(
                    delay: const Duration(milliseconds: 1200),
                    duration: const Duration(milliseconds: 800),
                    child: FadeIn(
                      delay: const Duration(milliseconds: 1200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '💕 Find Your Perfect Match 💕',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Loading animation with bouncing hearts
                  FadeInUp(
                    delay: const Duration(milliseconds: 1500),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return Bounce(
                              delay: Duration(milliseconds: 200 * index),
                              infinite: true,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 28,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        Pulse(
                          infinite: true,
                          child: Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sparkle effects
            ...List.generate(15, (index) {
              return Positioned(
                left: (index * 50.0) % size.width,
                top: (index * 80.0) % size.height,
                child: Flash(
                  delay: Duration(milliseconds: 500 + index * 200),
                  infinite: true,
                  child: Icon(
                    Icons.star,
                    color: Colors.white.withOpacity(0.4),
                    size: 12 + (index % 3) * 4,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
