import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../support/support_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _currencies = [
    'USD',
    'NGN',
    'GBP',
    'EUR',
    'CAD',
    'JPY',
  ];

  String _defaultCurrency = 'USD';
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;

  User? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = _user;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final document = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = document.data();

      if (!mounted) return;

      setState(() {
        _defaultCurrency =
            data?['defaultCurrency']?.toString() ?? 'USD';

        if (!_currencies.contains(_defaultCurrency)) {
          _defaultCurrency = 'USD';
        }

        _notificationsEnabled =
            data?['notificationsEnabled'] as bool? ?? true;

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _savePreferences() async {
    final user = _user;

    if (user == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'defaultCurrency': _defaultCurrency,
        'notificationsEnabled': _notificationsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _showMessage('Profile preferences saved successfully.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _user?.email;

    if (email == null || email.isEmpty) {
      _showMessage(
        'No email address was found for this account.',
        isError: true,
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            icon: const Icon(
              Icons.mark_email_read_outlined,
              color: Color(0xFF315CE2),
              size: 48,
            ),
            title: const Text(
              'Check your email',
              textAlign: TextAlign.center,
            ),
            content: Text(
              'A password reset link has been sent to $email.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Okay'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst(
              RegExp(r'\[firebase_auth/.*?\]\s*'),
              '',
            ),
        isError: true,
      );
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFE5484D),
            size: 45,
          ),
          title: const Text(
            'Log out?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Are you sure you want to leave CurrenSee?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await _auth.signOut();

    if (!mounted) return;

   Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFE5484D)
            : const Color(0xFF315CE2),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final displayName = user?.displayName?.trim();

    final name = displayName != null && displayName.isNotEmpty
        ? displayName
        : 'CurrenSee User';

    final email = user?.email ?? 'No email available';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF071A40),
              Color(0xFF12347A),
              Color(0xFF315CE2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const ProfileHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(24, 5, 24, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F9FD),
                    borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF315CE2),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(25),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 1450,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isLaptop =
                                      constraints.maxWidth >= 900;

                                  final profilePanel = Column(
                                    children: [
                                      ProfileIdentityCard(
                                        name: name,
                                        email: email,
                                      ),
                                      const SizedBox(height: 20),
                                      ProfileDetailsCard(
                                        name: name,
                                        email: email,
                                        joinedDate:
                                            user?.metadata.creationTime,
                                        lastSignIn:
                                            user?.metadata.lastSignInTime,
                                        userId: user?.uid ?? '',
                                      ),
                                    ],
                                  );

                                  final settingsPanel = Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ProfileStatCard(
                                              icon: Icons
                                                  .verified_user_outlined,
                                              title: user?.emailVerified ==
                                                      true
                                                  ? 'Verified'
                                                  : 'Registered',
                                              subtitle: 'Account status',
                                              color:
                                                  const Color(0xFF315CE2),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: ProfileStatCard(
                                              icon: Icons
                                                  .currency_exchange_rounded,
                                              title: _defaultCurrency,
                                              subtitle: 'Base currency',
                                              color:
                                                  const Color(0xFF8069E8),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: ProfileStatCard(
                                              icon: Icons
                                                  .notifications_active_outlined,
                                              title:
                                                  _notificationsEnabled
                                                      ? 'Enabled'
                                                      : 'Disabled',
                                              subtitle:
                                                  'Rate notifications',
                                              color:
                                                  const Color(0xFF21A4D8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SettingsCard(
                                        title: 'App preferences',
                                        icon: Icons.tune_rounded,
                                        children: [
                                          PreferenceRow(
                                            icon: Icons
                                                .account_balance_wallet_outlined,
                                            title: 'Default currency',
                                            subtitle:
                                                'Your preferred base currency',
                                            trailing: SizedBox(
                                              width: 130,
                                              child:
                                                  DropdownButtonFormField<
                                                      String>(
                                                initialValue:
                                                    _defaultCurrency,
                                                decoration:
                                                    InputDecoration(
                                                  filled: true,
                                                  fillColor:
                                                      const Color(
                                                    0xFFF4F7FC,
                                                  ),
                                                  border:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(12),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 13,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                items: _currencies.map(
                                                  (currency) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: currency,
                                                      child:
                                                          Text(currency),
                                                    );
                                                  },
                                                ).toList(),
                                                onChanged: (value) {
                                                  if (value == null) {
                                                    return;
                                                  }

                                                  setState(() {
                                                    _defaultCurrency =
                                                        value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          const Divider(
                                            color: Color(0xFFE5EAF3),
                                          ),
                                          PreferenceRow(
                                            icon: Icons
                                                .notifications_active_outlined,
                                            title:
                                                'Currency notifications',
                                            subtitle:
                                                'Receive updates for active rate alerts',
                                            trailing: Switch(
                                              value:
                                                  _notificationsEnabled,
                                              activeThumbColor:
                                                  const Color(
                                                0xFF315CE2,
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _notificationsEnabled =
                                                      value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SettingsCard(
                                        title: 'Account and security',
                                        icon: Icons.shield_outlined,
                                        children: [
                                          ActionRow(
                                            icon:
                                                Icons.lock_reset_rounded,
                                            title: 'Change password',
                                            subtitle:
                                                'Receive a secure password reset email',
                                            onTap:
                                                _sendPasswordResetEmail,
                                          ),
                                          const Divider(
                                            color: Color(0xFFE5EAF3),
                                          ),
                                       ActionRow(
                                            icon: Icons.help_outline_rounded,
                                            title: 'Help and support',
                                            subtitle: 'Get assistance with CurrenSee',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const SupportScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          const Divider(
                                            color: Color(0xFFE5EAF3),
                                          ),
                                          ActionRow(
                                            icon: Icons
                                                .privacy_tip_outlined,
                                            title: 'Privacy and security',
                                            subtitle:
                                                'Your data is protected by Firebase',
                                            onTap: () {
                                              _showMessage(
                                                'Your account data is securely stored.',
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                OutlinedButton.icon(
                                              style: OutlinedButton
                                                  .styleFrom(
                                                foregroundColor:
                                                    const Color(
                                                  0xFFE5484D,
                                                ),
                                                minimumSize:
                                                    const Size(0, 54),
                                                side: const BorderSide(
                                                  color: Color(
                                                    0xFFFFC8C8,
                                                  ),
                                                ),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(15),
                                                ),
                                              ),
                                              onPressed: _logout,
                                              icon: const Icon(
                                                Icons.logout_rounded,
                                              ),
                                              label: const Text(
                                                'Log out',
                                                style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child:
                                                ElevatedButton.icon(
                                              style: ElevatedButton
                                                  .styleFrom(
                                                backgroundColor:
                                                    const Color(
                                                  0xFF315CE2,
                                                ),
                                                foregroundColor:
                                                    Colors.white,
                                                minimumSize:
                                                    const Size(0, 54),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(15),
                                                ),
                                              ),
                                              onPressed: _isSaving
                                                  ? null
                                                  : _savePreferences,
                                              icon: _isSaving
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color:
                                                            Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons
                                                          .save_outlined,
                                                    ),
                                              label: Text(
                                                _isSaving
                                                    ? 'Saving...'
                                                    : 'Save changes',
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );

                                  if (!isLaptop) {
                                    return Column(
                                      children: [
                                        profilePanel,
                                        const SizedBox(height: 20),
                                        settingsPanel,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 390,
                                        child: profilePanel,
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: settingsPanel,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
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

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 22),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to dashboard',
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile and settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your account and CurrenSee preferences.',
                style: TextStyle(
                  color: Color(0xFFD7E4FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileIdentityCard extends StatelessWidget {
  final String name;
  final String email;

  const ProfileIdentityCard({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? 'U' : name[0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102A56),
            Color(0xFF315CE2),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33315CE2),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFF8BE9FF),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF071A40),
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD7E4FF),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF8BE9FF),
                  size: 18,
                ),
                SizedBox(width: 7),
                Text(
                  'CurrenSee account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileDetailsCard extends StatelessWidget {
  final String name;
  final String email;
  final DateTime? joinedDate;
  final DateTime? lastSignIn;
  final String userId;

  const ProfileDetailsCard({
    super.key,
    required this.name,
    required this.email,
    required this.joinedDate,
    required this.lastSignIn,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E9F3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C102A56),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.badge_outlined,
                color: Color(0xFF315CE2),
              ),
              SizedBox(width: 10),
              Text(
                'Personal information',
                style: TextStyle(
                  color: Color(0xFF102A56),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ProfileDetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Full name',
            value: name,
          ),
          const Divider(
            height: 28,
            color: Color(0xFFE5EAF3),
          ),
          ProfileDetailRow(
            icon: Icons.email_outlined,
            label: 'Email address',
            value: email,
          ),
          const Divider(
            height: 28,
            color: Color(0xFFE5EAF3),
          ),
          ProfileDetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Member since',
            value: _formatDate(joinedDate),
          ),
          const Divider(
            height: 28,
            color: Color(0xFFE5EAF3),
          ),
          ProfileDetailRow(
            icon: Icons.login_rounded,
            label: 'Last sign in',
            value: _formatDate(lastSignIn),
          ),
          const Divider(
            height: 28,
            color: Color(0xFFE5EAF3),
          ),
          ProfileDetailRow(
            icon: Icons.fingerprint_rounded,
            label: 'Account ID',
            value: _shortenId(userId),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _shortenId(String id) {
    if (id.isEmpty) return 'Not available';
    if (id.length <= 12) return id;

    return '${id.substring(0, 7)}...'
        '${id.substring(id.length - 5)}';
  }
}

class ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF315CE2),
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8290AA),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF102A56),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const ProfileStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE3E9F3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C102A56),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102A56),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8290AA),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SettingsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E9F3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C102A56),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF315CE2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102A56),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const PreferenceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF315CE2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102A56),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8290AA),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          trailing,
        ],
      ),
    );
  }
}

class ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF315CE2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF102A56),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8290AA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9AA7BC),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}