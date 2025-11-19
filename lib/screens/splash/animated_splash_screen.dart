import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../constants/app_colors.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    // Smooth zoom in/out animation
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _zoomAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _zoomController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated love logo with zoom in/out
                  ZoomIn(
                    duration: const Duration(milliseconds: 1000),
                    child: AnimatedBuilder(
                      animation: _zoomAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _zoomAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo/Picsart_25-11-11_22-30-10-727.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name with fade in
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 800),
                    child: const Text(
                      'shooLuv',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'Find Your Perfect Match',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    duration: const Duration(milliseconds: 800),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom hearts animation
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: FadeIn(
                delay: const Duration(milliseconds: 1000),
                duration: const Duration(milliseconds: 1000),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Bounce(
                        delay: Duration(milliseconds: 200 * index),
                        infinite: true,
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white.withOpacity(0.3),
                          size: 20,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
