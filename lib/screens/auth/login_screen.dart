import 'package:flutter/material.dart';

import '../../services/auth_services.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthServices _authServices = AuthServices();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authServices.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
              size: 58,
            ),
            title: const Text(
              'Login successful',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF102A56),
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Welcome back to CurrenSee! Your account has been authenticated.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF71809C),
                height: 1.5,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst(
            'Exception: ',
            '',
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goBackToWelcome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            const Expanded(
              child: LoginInformationPanel(),
            ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FB),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 70 : 24,
                    vertical: 30,
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              tooltip: 'Go back',
                              onPressed:
                                  _isLoading ? null : _goBackToWelcome,
                              icon: const Icon(
                              Icons.arrow_back_rounded
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                disabledForegroundColor: Colors.grey,
                                padding: const EdgeInsets.all(14),
                              ),
                            ),
                            const SizedBox(height: 50),
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                color: Color(0xFF102A56),
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Log in to continue managing your currencies.',
                              style: TextStyle(
                                color: Color(0xFF71809C),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 38),

                            // Email field
                            const LoginFieldLabel(
                              text: 'Email address',
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Enter your email address',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email address';
                                }

                                final emailPattern = RegExp(
                                  r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$',
                                );

                                if (!emailPattern.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 22),

                            // Password field
                            const LoginFieldLabel(
                              text: 'Password',
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.password,
                              ],
                              onFieldSubmitted: (_) {
                                if (!_isLoading) {
                                  _login();
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _hidePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }

                                if (value.length < 8) {
                                  return 'Password must contain at least 8 characters';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Remember me and forgot password
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Color(0xFF60708E),
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          // Forgot-password functionality
                                          // will be added later.
                                        },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Login button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 25),

                            // Registration link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Don’t have an account?',
                                  style: TextStyle(
                                    color: Color(0xFF71809C),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _goBackToWelcome,
                                  child: const Text(
                                    'Create account',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginInformationPanel extends StatelessWidget {
  const LoginInformationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(70),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071A40),
            Color(0xFF123B82),
            Color(0xFF315CE2),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -130,
            child: Container(
              width: 370,
              height: 370,
              decoration: const BoxDecoration(
                color: Color(0x1A67E8F9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -150,
            child: Container(
              width: 430,
              height: 430,
              decoration: const BoxDecoration(
                color: Color(0x1A22C55E),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CurrenSeeLoginLogo(),
              Spacer(),
              Text(
                'Your currencies.\nYour control.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Access live exchange rates, saved conversions, '
                'currency alerts and market insights.',
                style: TextStyle(
                  color: Color(0xFFD7E4FF),
                  fontSize: 17,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 38),
              LoginFeature(
                icon: Icons.bolt_rounded,
                text: 'Fast and accurate conversions',
              ),
              SizedBox(height: 18),
              LoginFeature(
                icon: Icons.notifications_none_rounded,
                text: 'Personalised exchange-rate alerts',
              ),
              SizedBox(height: 18),
              LoginFeature(
                icon: Icons.shield_outlined,
                text: 'Secure access to your account',
              ),
              Spacer(),
              Text(
                'Powered by ABC Finance Ltd.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrenSeeLoginLogo extends StatelessWidget {
  const CurrenSeeLoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.currency_exchange_rounded,
          color: Colors.white,
          size: 38,
        ),
        SizedBox(width: 12),
        Text(
          'CurrenSee',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class LoginFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const LoginFeature({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF67E8F9),
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class LoginFieldLabel extends StatelessWidget {
  final String text;

  const LoginFieldLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF243B67),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}