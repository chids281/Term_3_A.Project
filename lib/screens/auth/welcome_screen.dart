import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 850;

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
              top: -100,
              right: -80,
              child: GlowCircle(
                size: 350,
                color: Color(0x3322D3EE),
              ),
            ),
            const Positioned(
              bottom: -130,
              left: -80,
              child: GlowCircle(
                size: 400,
                color: Color(0x3322C55E),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 80 : 24,
                  vertical: 30,
                ),
                child: Column(
                  children: [
                    const Header(),
                    Expanded(
                      child: isDesktop
                          ? const DesktopContent()
                          : const MobileContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.currency_exchange_rounded,
            color: AppTheme.primaryColor,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'CurrenSee',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        const Text(
          'Currency made simple',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class DesktopContent extends StatelessWidget {
  const DesktopContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 6, child: WelcomeInformation()),
        SizedBox(width: 70),
        Expanded(flex: 4, child: ActionCard()),
      ],
    );
  }
}

class MobileContent extends StatelessWidget {
  const MobileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(top: 60, bottom: 25),
      child: Column(
        children: [
          WelcomeInformation(),
          SizedBox(height: 45),
          ActionCard(),
        ],
      ),
    );
  }
}

class WelcomeInformation extends StatelessWidget {
  const WelcomeInformation({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: const Text(
            '●  LIVE EXCHANGE RATES',
            style: TextStyle(
              color: Color(0xFF86EFAC),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'See the world\nin every currency.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 54,
            height: 1.08,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        const SizedBox(
          width: 550,
          child: Text(
            'Convert currencies using real-time exchange rates, '
            'monitor global markets and manage your finances confidently.',
            style: TextStyle(
              color: Color(0xFFD7E4FF),
              fontSize: 18,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 34),
        const Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            FeatureChip(
              icon: Icons.bolt_rounded,
              text: 'Instant conversion',
            ),
            FeatureChip(
              icon: Icons.trending_up_rounded,
              text: 'Live market rates',
            ),
            FeatureChip(
              icon: Icons.security_rounded,
              text: 'Secure and reliable',
            ),
          ],
        ),
      ],
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 45,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.secondaryColor,
                  AppTheme.primaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.currency_exchange_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to CurrenSee',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF102A56),
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your smarter way to understand and convert money worldwide.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF71809C),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
               Navigator.push(
               context,
              MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );// We will connect this to the registration screen.
            },
            child: const Text(
              'Create an account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(
                  color: Color(0xFFD2DBEA),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'I already have an account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Trusted currency information at your fingertips',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AA6B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureChip({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF67E8F9), size: 19),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const GlowCircle({
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