import 'package:flutter/material.dart';

import '../../services/auth_services.dart';
import '../../utils/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthServices _authServices = AuthServices();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the Terms of Service and Privacy Policy.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authServices.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Firebase signs up and logs in new users automatically.
      // Sign out so the user can test the login page.
      await _authServices.logout();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully. You can now log in.',
          ),
          backgroundColor: Color(0xFF16A34A),
        ),
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

  void _openLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
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
              child: RegisterInformationPanel(),
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
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                disabledForegroundColor: Colors.grey,
                                padding: const EdgeInsets.all(14),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Create your account',
                              style: TextStyle(
                                color: Color(0xFF102A56),
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Join CurrenSee and start converting currencies '
                              'with confidence.',
                              style: TextStyle(
                                color: Color(0xFF71809C),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Full name
                            const FieldLabel(text: 'Full name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              enabled: !_isLoading,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.name,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Enter your full name',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }

                                if (value.trim().length < 3) {
                                  return 'Name must contain at least 3 characters';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Email address
                            const FieldLabel(text: 'Email address'),
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
                            const SizedBox(height: 20),

                            // Password
                            const FieldLabel(text: 'Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              decoration: InputDecoration(
                                hintText: 'Create a password',
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
                                  return 'Please create a password';
                                }

                                if (value.length < 8) {
                                  return 'Password must contain at least 8 characters';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Confirm password
                            const FieldLabel(text: 'Confirm password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              enabled: !_isLoading,
                              obscureText: _hideConfirmPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              onFieldSubmitted: (_) {
                                if (!_isLoading) {
                                  _createAccount();
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter your password again',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _hideConfirmPassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _hideConfirmPassword =
                                          !_hideConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _hideConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }

                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Terms
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _acceptTerms = value ?? false;
                                          });
                                        },
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 11),
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          color: Color(0xFF71809C),
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'I agree to the ',
                                          ),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            // Create-account button
                            ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _createAccount,
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
                                      'Create account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 22),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    color: Color(0xFF71809C),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      _isLoading ? null : _openLoginScreen,
                                  child: const Text(
                                    'Log in',
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

class RegisterInformationPanel extends StatelessWidget {
  const RegisterInformationPanel({super.key});

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
            top: -140,
            right: -120,
            child: Container(
              width: 350,
              height: 350,
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
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                color: Color(0x1A22C55E),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CurrenSeeLogo(),
              Spacer(),
              Text(
                'Make every currency\nmake sense.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Create an account to save conversions, monitor exchange '
                'rates and receive useful currency alerts.',
                style: TextStyle(
                  color: Color(0xFFD7E4FF),
                  fontSize: 17,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 35),
              RegisterBenefit(
                icon: Icons.currency_exchange_rounded,
                text: 'Convert global currencies instantly',
              ),
              SizedBox(height: 18),
              RegisterBenefit(
                icon: Icons.history_rounded,
                text: 'Keep track of your conversion history',
              ),
              SizedBox(height: 18),
              RegisterBenefit(
                icon: Icons.notifications_active_outlined,
                text: 'Receive personalised rate alerts',
              ),
              Spacer(),
              Text(
                'Secure • Reliable • Simple',
                style: TextStyle(
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrenSeeLogo extends StatelessWidget {
  const CurrenSeeLogo({super.key});

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

class RegisterBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const RegisterBenefit({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF67E8F9),
            size: 23,
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

class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel({
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