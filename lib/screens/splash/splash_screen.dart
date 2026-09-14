import 'dart:async';
import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../auth/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const WelcomeScreen();
          },
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF071A40),
              Color(0xFF123B82),
              Color(0xFF2563EB),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              right: -100,
              child: DecorativeCircle(
                size: 350,
                color: Color(0x1A67E8F9),
              ),
            ),
            const Positioned(
              bottom: -160,
              left: -100,
              child: DecorativeCircle(
                size: 420,
                color: Color(0x1A22C55E),
              ),
            ),
            const Positioned(
              top: 100,
              left: 70,
              child: SmallCurrencySymbol(
                symbol: '\$',
                angle: -0.20,
              ),
            ),
            const Positioned(
              top: 140,
              right: 100,
              child: SmallCurrencySymbol(
                symbol: '€',
                angle: 0.15,
              ),
            ),
            const Positioned(
              bottom: 110,
              left: 110,
              child: SmallCurrencySymbol(
                symbol: '£',
                angle: 0.12,
              ),
            ),
            const Positioned(
              bottom: 100,
              right: 90,
              child: SmallCurrencySymbol(
                symbol: '¥',
                angle: -0.15,
              ),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 35,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.currency_exchange_rounded,
                            color: AppTheme.primaryColor,
                            size: 68,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'CurrenSee',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'See the value. Convert with confidence.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD7E4FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 45),
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Loading live exchange rates...',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Text(
                'Powered by ABC Finance Ltd.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const DecorativeCircle({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class SmallCurrencySymbol extends StatelessWidget {
  final String symbol;
  final double angle;

  const SmallCurrencySymbol({
    super.key,
    required this.symbol,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          symbol,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}