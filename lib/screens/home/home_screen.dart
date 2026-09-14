import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../history/history_screen.dart';
import '../alerts/rate_alerts_screen.dart';
import '../currencies/currencies_screen.dart';
import '../news/news_screen.dart';
import '../profile/profile_screen.dart';
import '../support/support_screen.dart';
import '../../services/auth_services.dart';
import '../../services/currencies_service.dart';
import '../../services/database_services.dart';
import '../../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthServices _authServices = AuthServices();
  final CurrencyService _currencyService = CurrencyService();
  final DatabaseServices _databaseServices = DatabaseServices();
  final GlobalKey _converterKey = GlobalKey();

  final TextEditingController _amountController =
      TextEditingController(text: '1000');

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'NGN',
    'CAD',
    'JPY',
  ];

  String _fromCurrency = 'USD';
  String _toCurrency = 'NGN';

  double _convertedAmount = 1600000;
  bool _isConverting = false;
  bool _isCheckingRateAlerts = false;
  Timer? _rateAlertTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveRateAlerts();
    });

    _rateAlertTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkActiveRateAlerts(),
    );
  }

  @override
  void dispose() {
    _rateAlertTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveRateAlerts() async {
    if (_isCheckingRateAlerts ||
        FirebaseAuth.instance.currentUser == null) {
      return;
    }

    _isCheckingRateAlerts = true;

    try {
      final alerts =
          await _databaseServices.getActiveRateAlerts();

      final ratesByBase =
          <String, CurrencyRateResponse>{};

      for (final alert in alerts.docs) {
        final data = alert.data();

        final fromCurrency =
            data['fromCurrency']?.toString().toUpperCase() ??
                '';

        final toCurrency =
            data['toCurrency']?.toString().toUpperCase() ??
                '';

        final targetRate =
            (data['targetRate'] as num?)?.toDouble();

        final condition =
            data['condition']?.toString().toLowerCase() ??
                'above';

        final isTriggered =
            data['isTriggered'] as bool? ?? false;

        if (fromCurrency.isEmpty ||
            toCurrency.isEmpty ||
            targetRate == null ||
            isTriggered) {
          continue;
        }

        try {
          final response = ratesByBase[fromCurrency] ??
              await _currencyService.getRates(fromCurrency);

          ratesByBase[fromCurrency] = response;

          final currentRate = response.rates[toCurrency];

          if (currentRate == null) continue;

          await _databaseServices.updateRateAlertCheck(
            alertId: alert.id,
            currentRate: currentRate,
          );

          final hasReachedTarget = condition == 'below'
              ? currentRate <= targetRate
              : currentRate >= targetRate;

          if (hasReachedTarget) {
            await _databaseServices.triggerRateAlert(
              alertId: alert.id,
              currentRate: currentRate,
            );
          }
        } catch (_) {
          // One unavailable currency pair must not stop
          // the remaining alerts from being checked.
        }
      }
    } finally {
      _isCheckingRateAlerts = false;
    }
  }

  Future<void> _convertCurrency() async {
    if (_isConverting) return;

    FocusScope.of(context).unfocus();

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
          backgroundColor: Color(0xFFE5484D),
        ),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      final result = await _currencyService.convert(
        amount: amount,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
      );

      await _databaseServices.saveConversion(
        amount: amount,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        convertedAmount: result,
      );

      if (!mounted) return;

      setState(() {
        _convertedAmount = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live conversion completed and saved.'),
          backgroundColor: Color(0xFF315CE2),
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
          backgroundColor: const Color(0xFFE5484D),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  Future<void> _swapCurrencies() async {
    setState(() {
      final previousCurrency = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = previousCurrency;
    });

    await _convertCurrency();
  }

  void _scrollToConverter() {
    final converterContext = _converterKey.currentContext;

    if (converterContext == null) return;

    Scrollable.ensureVisible(
      converterContext,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1050;
    final isMobile = !isDesktop;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: const Color(0xFF081B40),
              child: PremiumSidebar(
                authServices: _authServices,
                onConvertTap: _scrollToConverter,
              ),
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF071A40),
              Color(0xFF12347A),
              Color(0xFF315CE2),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -170,
              right: -100,
              child: BackgroundGlow(
                size: 430,
                color: Color(0x1A67E8F9),
              ),
            ),
            const Positioned(
              bottom: -220,
              left: 100,
              child: BackgroundGlow(
                size: 500,
                color: Color(0x16315CE2),
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  if (isDesktop)
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: SizedBox(
                        width: 255,
                        child: PremiumSidebar(
                          authServices: _authServices,
                          onConvertTap: _scrollToConverter,
                        ),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 18 : (isMobile ? 14 : 20),
                        isMobile ? 12 : 18,
                        isDesktop ? 30 : (isMobile ? 14 : 20),
                        isMobile ? 24 : 35,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PremiumHeader(isDesktop: isDesktop),
                          SizedBox(height: isMobile ? 16 : 24),
                          const HeroSection(),
                          SizedBox(height: isMobile ? 16 : 22),
                          const MarketCards(),
                          SizedBox(height: isMobile ? 16 : 22),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final converter = PremiumConverter(
                                key: _converterKey,
                                amountController: _amountController,
                                currencies: _currencies,
                                fromCurrency: _fromCurrency,
                                toCurrency: _toCurrency,
                                convertedAmount: _convertedAmount,
                                isConverting: _isConverting,
                                onFromChanged: (value) {
                                  if (value == null) return;

                                  setState(() {
                                    _fromCurrency = value;
                                  });
                                },
                                onToChanged: (value) {
                                  if (value == null) return;

                                  setState(() {
                                    _toCurrency = value;
                                  });
                                },
                                onSwap: _swapCurrencies,
                                onConvert: _convertCurrency,
                              );

                              if (constraints.maxWidth >= 850) {
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: converter,
                                      ),
                                      const SizedBox(width: 22),
                                      Expanded(
                                        flex: 5,
                                        child: TrendCard(
                                          fromCurrency: _fromCurrency,
                                          toCurrency: _toCurrency,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  converter,
                                  SizedBox(height: isMobile ? 16 : 22),
                                  TrendCard(
                                    fromCurrency: _fromCurrency,
                                    toCurrency: _toCurrency,
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: isMobile ? 16 : 22),
                          RecentConversions(
                            databaseServices: _databaseServices,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumSidebar extends StatelessWidget {
  final AuthServices authServices;
  final VoidCallback onConvertTap;

  const PremiumSidebar({
    super.key,
    required this.authServices,
    required this.onConvertTap,
  });

 Future<void> _logout(BuildContext context) async {
  try {
    await authServices.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
        ),
        backgroundColor: const Color(0xFFE5484D),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 28, 22, 25),
            child: Row(
              children: [
                LogoBox(),
                SizedBox(width: 12),
                Text(
                  'CurrenSee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: Colors.white12,
            height: 1,
          ),
          const SizedBox(height: 18),
          const SidebarItem(
            icon: Icons.grid_view_rounded,
            text: 'Overview',
            selected: true,
          ),
          SidebarItem(
            icon: Icons.currency_exchange_rounded,
            text: 'Convert',
            onTap: onConvertTap,
          ),
          SidebarItem(
            icon: Icons.account_balance_wallet_outlined,
            text: 'Currencies',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrenciesScreen(),
                ),
              );
            },
          ),
          SidebarItem(
            icon: Icons.show_chart_rounded,
            text: 'Market',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewsScreen(),
                ),
              );
            },
          ),
          SidebarItem(
          icon: Icons.history_rounded,
          text: 'History',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistoryScreen(),
              ),
            );
          },
        ),
          SidebarItem(
            icon: Icons.notifications_none_rounded,
            text: 'Rate alerts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RateAlertsScreen(),
                ),
              );
            },
          ),
          SidebarItem(
            icon: Icons.help_outline_rounded,
            text: 'Help & support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupportScreen(),
                ),
              );
            },
          ),
          const Spacer(),
          SidebarItem(
            icon: Icons.person_outline_rounded,
            text: 'Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          SidebarItem(
            icon: Icons.logout_rounded,
            text: 'Log out',
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.text,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 4,
      ),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: onTap,
          dense: true,
          leading: Icon(
            icon,
            color: selected
                ? const Color(0xFF8BE9FF)
                : Colors.white60,
          ),
          title: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: selected
              ? Container(
                  width: 5,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8BE9FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class PremiumHeader extends StatelessWidget {
  final bool isDesktop;

  const PremiumHeader({
    super.key,
    required this.isDesktop,
  });

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  Future<void> _showNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await DatabaseServices().markAllNotificationsAsRead();
    }

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F9FD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            22,
          ),
          title: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF071A40),
                  Color(0xFF315CE2),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.12),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 480,
            height: 420,
            child: user == null
                ? const NotificationMessage(
                    icon: Icons.person_off_outlined,
                    title: 'You are not logged in',
                    message:
                        'Log in to view your notifications.',
                  )
                : StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                    stream: DatabaseServices()
                        .getNotifications(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const NotificationMessage(
                          icon: Icons.error_outline_rounded,
                          title:
                              'Unable to load notifications',
                          message:
                              'Check your connection and try again.',
                        );
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF315CE2),
                          ),
                        );
                      }

                      final notifications =
                          snapshot.data?.docs ?? [];

                      if (notifications.isEmpty) {
                        return const NotificationMessage(
                          icon:
                              Icons.notifications_none_rounded,
                          title: 'No notifications yet',
                          message:
                              'Your currency-rate alerts will appear here.',
                        );
                      }

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${notifications.length} '
                            '${notifications.length == 1 ? 'notification' : 'notifications'}',
                            style: const TextStyle(
                              color: Color(0xFF71809C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ListView.separated(
                              itemCount: notifications.length,
                              separatorBuilder:
                                  (context, index) {
                                return const SizedBox(
                                  height: 11,
                                );
                              },
                              itemBuilder: (context, index) {
                                final data =
                                    notifications[index].data();

                                final title =
                                    data['title']?.toString() ??
                                        'Rate alert reached';

                                final message =
                                    data['message']?.toString() ??
                                        '';

                                final isRead =
                                    data['isRead'] as bool? ?? false;

                                return NotificationCard(
                                  title: title,
                                  message: message,
                                  isRead: isRead,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isMobile = MediaQuery.sizeOf(context).width < 1050;

    return Row(
      children: [
        if (!isDesktop)
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                ),
              );
            },
          ),
        Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 22 : 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),

        // Notification bell
        StreamBuilder<int>(
          stream: user == null
              ? Stream.value(0)
              : DatabaseServices()
                  .getUnreadNotificationCount(),
          builder: (context, snapshot) {
            final notificationCount =
                snapshot.data ?? 0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () {
                      _showNotifications(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 13),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white12,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5484D),
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1F3D88),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        notificationCount > 9
                            ? '9+'
                            : '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(width: isMobile ? 8 : 12),

        // Clickable profile
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () {
              _openProfile(context);
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 4 : 7,
                isMobile ? 4 : 6,
                isMobile ? 4 : 15,
                isMobile ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        const Color(0xFF8BE9FF),
                    child: Text(
                      _initial(user),
                      style: const TextStyle(
                        color: Color(0xFF071A40),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 10),
                    Text(
                      _firstName(user),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 19,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _initial(User? user) {
    final value =
        user?.displayName ?? user?.email ?? 'User';

    if (value.isEmpty) return 'U';

    return value[0].toUpperCase();
  }

  static String _firstName(User? user) {
    final value = user?.displayName?.trim();

    if (value != null && value.isNotEmpty) {
      return value.split(' ').first;
    }

    return 'User';
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final bool isRead;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E9F3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isRead
                  ? const Color(0xFFF0F2F6)
                  : const Color(0xFFE8FBF3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF168B62),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                  message,
                  style: const TextStyle(
                    color: Color(0xFF71809C),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFE5484D),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class NotificationMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const NotificationMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF315CE2),
              size: 38,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF102A56),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF71809C),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isMobile = MediaQuery.sizeOf(context).width < 1050;
    final fullName = user?.displayName?.trim();

    final firstName = fullName != null && fullName.isNotEmpty
        ? fullName.split(' ').first
        : 'there';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF315CE2),
            Color(0xFF4F6DF5),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44315CE2),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 20,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $firstName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 24 : 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'The global market is moving. Stay ahead of every rate.',
                style: TextStyle(
                  color: Color(0xFFD7E4FF),
                  fontSize: isMobile ? 14 : 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isMobile ? 9 : 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0x33071A40),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: Color(0xFF8BE9FF),
                  size: 11,
                ),
                SizedBox(width: 9),
                Text(
                  'Markets are live',
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

class MarketCards extends StatefulWidget {
  const MarketCards({super.key});

  @override
  State<MarketCards> createState() => _MarketCardsState();
}

class _MarketCardsState extends State<MarketCards> {
  final CurrencyService _currencyService = CurrencyService();

  late Future<List<DashboardMarketRate>> _ratesFuture;

  @override
  void initState() {
    super.initState();
    _ratesFuture = _loadRates();
  }

  Future<List<DashboardMarketRate>> _loadRates() async {
    final responses = await Future.wait([
      _currencyService.getRates('USD'),
      _currencyService.getRates('EUR'),
      _currencyService.getRates('GBP'),
    ]);

    final usdRates = responses[0];
    final eurRates = responses[1];
    final gbpRates = responses[2];

    final usdNgn = usdRates.rates['NGN'];
    final eurUsd = eurRates.rates['USD'];
    final gbpUsd = gbpRates.rates['USD'];
    final usdJpy = usdRates.rates['JPY'];

    if (usdNgn == null ||
        eurUsd == null ||
        gbpUsd == null ||
        usdJpy == null) {
      throw Exception(
        'Some dashboard rates are unavailable.',
      );
    }

    return [
      DashboardMarketRate(
        symbol: '\$',
        pair: 'USD / NGN',
        value: usdNgn,
        color: const Color(0xFF5B8DEF),
      ),
      DashboardMarketRate(
        symbol: '€',
        pair: 'EUR / USD',
        value: eurUsd,
        color: const Color(0xFF8069E8),
      ),
      DashboardMarketRate(
        symbol: '£',
        pair: 'GBP / USD',
        value: gbpUsd,
        color: const Color(0xFFFF7A59),
      ),
      DashboardMarketRate(
        symbol: '¥',
        pair: 'USD / JPY',
        value: usdJpy,
        color: const Color(0xFF21B6C9),
      ),
    ];
  }

  void _refreshRates() {
    setState(() {
      _ratesFuture = _loadRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1050;
        final useSingleColumn = constraints.maxWidth < 350;
        final mobileCardWidth = useSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;

        return FutureBuilder<List<DashboardMarketRate>>(
          future: _ratesFuture,
          builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Wrap(
            spacing: isMobile ? 12 : 15,
            runSpacing: isMobile ? 12 : 15,
            children: [
              DashboardRateLoadingCard(width: isMobile ? mobileCardWidth : 220),
              DashboardRateLoadingCard(width: isMobile ? mobileCardWidth : 220),
              DashboardRateLoadingCard(width: isMobile ? mobileCardWidth : 220),
              DashboardRateLoadingCard(width: isMobile ? mobileCardWidth : 220),
            ],
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: Color(0xFFFFA3A3),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Unable to load the dashboard exchange rates.',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Try again',
                  onPressed: _refreshRates,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF8BE9FF),
                  ),
                ),
              ],
            ),
          );
        }

        final rates = snapshot.data!;

        return Wrap(
          spacing: isMobile ? 12 : 15,
          runSpacing: isMobile ? 12 : 15,
          children: rates.map((rate) {
            return CurrencyMarketCard(
              width: isMobile ? mobileCardWidth : 220,
              symbol: rate.symbol,
              pair: rate.pair,
              value: _formatRate(rate.value),
              subtitle: 'Latest API rate',
              color: rate.color,
            );
          }).toList(),
        );
          },
        );
      },
    );
  }

  static String _formatRate(double value) {
    if (value >= 100) {
      return value.toStringAsFixed(2);
    }

    if (value >= 1) {
      return value.toStringAsFixed(4);
    }

    return value.toStringAsFixed(6);
  }
}

class DashboardMarketRate {
  final String symbol;
  final String pair;
  final double value;
  final Color color;

  const DashboardMarketRate({
    required this.symbol,
    required this.pair,
    required this.value,
    required this.color,
  });
}

class DashboardRateLoadingCard extends StatelessWidget {
  final double width;

  const DashboardRateLoadingCard({
    super.key,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 84,
      padding: EdgeInsets.all(width < 200 ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Color(0xFF8BE9FF),
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(width: width < 200 ? 8 : 13),
          Expanded(
            child: Text(
              width < 200 ? 'Loading...' : 'Loading rate...',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyMarketCard extends StatelessWidget {
  final double width;
  final String symbol;
  final String pair;
  final String value;
  final String subtitle;
  final Color color;

  const CurrencyMarketCard({
    super.key,
    this.width = 220,
    required this.symbol,
    required this.pair,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.all(width < 200 ? 13 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: width < 200 ? 40 : 47,
            height: width < 200 ? 40 : 47,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                color: Colors.white,
              fontSize: width < 200 ? 20 : 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: width < 200 ? 9 : 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pair,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8BE9FF),
                    fontSize: 12,
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

class PremiumConverter extends StatelessWidget {
  final TextEditingController amountController;
  final List<String> currencies;
  final String fromCurrency;
  final String toCurrency;
  final double convertedAmount;
  final bool isConverting;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final VoidCallback onSwap;
  final VoidCallback onConvert;

  const PremiumConverter({
    super.key,
    required this.amountController,
    required this.currencies,
    required this.fromCurrency,
    required this.toCurrency,
    required this.convertedAmount,
    required this.isConverting,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSwap,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 1050;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.currency_exchange_rounded,
                color: Color(0xFF8BE9FF),
              ),
              SizedBox(width: 10),
              Text(
                'Quick conversion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 17 : 22),
          TextField(
            controller: amountController,
            enabled: !isConverting,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: Colors.white70,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          SizedBox(height: isMobile ? 13 : 17),
          Row(
            children: [
              Expanded(
                child: CurrencyDropdown(
                  title: 'From',
                  value: fromCurrency,
                  currencies: currencies,
                  enabled: !isConverting,
                  onChanged: onFromChanged,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10),
                child: IconButton.filled(
                  onPressed: isConverting ? null : onSwap,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF315CE2),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white24,
                  ),
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                  ),
                ),
              ),
              Expanded(
                child: CurrencyDropdown(
                  title: 'To',
                  value: toCurrency,
                  currencies: currencies,
                  enabled: !isConverting,
                  onChanged: onToChanged,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 15 : 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF315CE2),
                  Color(0xFF21A4D8),
                ],
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              children: [
                const Text(
                  'You will receive',
                  style: TextStyle(
                    color: Color(0xFFD7E4FF),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  child: Text(
                    '$toCurrency ${convertedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 14 : 17),
          ElevatedButton.icon(
            onPressed: isConverting ? null : onConvert,
            icon: isConverting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(
                    Icons.auto_graph_rounded,
                  ),
            label: Text(
              isConverting
                  ? 'Getting live rate...'
                  : 'Convert now',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyDropdown extends StatelessWidget {
  final String title;
  final String value;
  final List<String> currencies;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const CurrencyDropdown({
    super.key,
    required this.title,
    required this.value,
    required this.currencies,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF17366F),
      iconEnabledColor: Colors.white70,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: title,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
      ),
      items: currencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

class TrendCard extends StatefulWidget {
  final String fromCurrency;
  final String toCurrency;

  const TrendCard({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  final CurrencyService _currencyService =
      CurrencyService();

  late Future<List<HistoricalRatePoint>> _trendFuture;

  @override
  void initState() {
    super.initState();
    _trendFuture = _loadTrend();
  }

  @override
  void didUpdateWidget(covariant TrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fromCurrency != widget.fromCurrency ||
        oldWidget.toCurrency != widget.toCurrency) {
      _trendFuture = _loadTrend();
    }
  }

  Future<List<HistoricalRatePoint>> _loadTrend() {
    return _currencyService.getHistoricalRates(
      fromCurrency: widget.fromCurrency,
      toCurrency: widget.toCurrency,
      days: 7,
    );
  }

  void _refreshTrend() {
    setState(() {
      _trendFuture = _loadTrend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 1050;

    return GlassCard(
      child: FutureBuilder<List<HistoricalRatePoint>>(
        future: _trendFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const SizedBox(
              height: 350,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF8BE9FF),
                    ),
                    SizedBox(height: 13),
                    Text(
                      'Loading historical rates...',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.length < 2) {
            return SizedBox(
              height: 350,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      color: Color(0xFFFFA3A3),
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Historical trend unavailable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check your connection and try again.',
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 13),
                    IconButton(
                      tooltip: 'Retry',
                      onPressed: _refreshTrend,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF8BE9FF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final points = snapshot.data!;
          final latestRate = points.last.rate;
          final firstRate = points.first.rate;

          final change =
              ((latestRate - firstRate) / firstRate) * 100;

          final isPositive = change >= 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.fromCurrency} to '
                          '${widget.toCurrency}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Seven-day historical performance',
                          style: TextStyle(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh graph',
                    onPressed: _refreshTrend,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF8BE9FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    latestRate.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 4,
                    ),
                    child: Text(
                      widget.toCurrency,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color(0x2634D399)
                          : const Color(0x26FF7B7B),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isPositive
                              ? const Color(0xFF66E0B4)
                              : const Color(0xFFFFA3A3),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${change.abs().toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isPositive
                                ? const Color(0xFF66E0B4)
                                : const Color(0xFFFFA3A3),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: isMobile ? 165 : 210,
                width: double.infinity,
                child: CustomPaint(
                  painter: TrendPainter(
                    points: points,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: points.map((point) {
                  return Text(
                    _weekday(point.date),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 9),
              const Text(
                'Historical source: Fawaz Ahmed Currency API',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _weekday(DateTime date) {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return weekdays[date.weekday - 1];
  }
}

class TrendPainter extends CustomPainter {
  final List<HistoricalRatePoint> points;

  const TrendPainter({
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final rates = points
        .map((point) => point.rate)
        .toList();

    double minimumRate = rates.first;
    double maximumRate = rates.first;

    for (final rate in rates) {
      if (rate < minimumRate) {
        minimumRate = rate;
      }

      if (rate > maximumRate) {
        maximumRate = rate;
      }
    }

    double range = maximumRate - minimumRate;

    if (range == 0) {
      range = 1;
    }

    final padding = range * 0.18;
    minimumRate -= padding;
    maximumRate += padding;
    range = maximumRate - minimumRate;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;

    for (int index = 1; index <= 4; index++) {
      final y = size.height * index / 5;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final chartPoints = <Offset>[];

    for (int index = 0;
        index < points.length;
        index++) {
      final x = size.width *
          index /
          (points.length - 1);

      final normalizedRate =
          (points[index].rate - minimumRate) / range;

      final y =
          size.height - (normalizedRate * size.height);

      chartPoints.add(Offset(x, y));
    }

    final linePath = Path()
      ..moveTo(
        chartPoints.first.dx,
        chartPoints.first.dy,
      );

    for (int index = 1;
        index < chartPoints.length;
        index++) {
      linePath.lineTo(
        chartPoints[index].dx,
        chartPoints[index].dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x668BE9FF),
          Color(0x008BE9FF),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF8BE9FF)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = const Color(0xFF8BE9FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final point in chartPoints) {
      canvas.drawCircle(
        point,
        4,
        pointPaint,
      );

      canvas.drawCircle(
        point,
        4,
        pointBorderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant TrendPainter oldDelegate,
  ) {
    return oldDelegate.points != points;
  }
}
class RecentConversions extends StatelessWidget {
  final DatabaseServices databaseServices;

  const RecentConversions({
    super.key,
    required this.databaseServices,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: databaseServices.getConversionHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load conversion history.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: CircularProgressIndicator(
                  color: Color(0xFF8BE9FF),
                ),
              ),
            );
          }

          final conversions = snapshot.data?.docs ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent conversions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${conversions.length} saved',
                      style: const TextStyle(
                        color: Color(0xFF8BE9FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (conversions.isEmpty)
                const EmptyHistory()
              else
                ...List.generate(conversions.length, (index) {
                  final document = conversions[index];
                  final data = document.data();

                  final amount =
                      (data['amount'] as num?)?.toDouble() ?? 0;

                  final convertedAmount =
                      (data['convertedAmount'] as num?)
                              ?.toDouble() ??
                          0;

                  final fromCurrency =
                      data['fromCurrency']?.toString() ?? '';

                  final toCurrency =
                      data['toCurrency']?.toString() ?? '';

                  final timestamp = data['createdAt'];

                  return Column(
                    children: [
                      ConversionRow(
                        from:
                            '${_formatAmount(amount)} $fromCurrency',
                        to:
                            '${_formatAmount(convertedAmount)} $toCurrency',
                        time: _formatTime(timestamp),
                        onDelete: () async {
                          try {
                            await databaseServices.deleteConversion(
                              document.id,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Conversion deleted.',
                                ),
                                backgroundColor: Color(0xFF315CE2),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error
                                      .toString()
                                      .replaceFirst('Exception: ', ''),
                                ),
                                backgroundColor:
                                    const Color(0xFFE5484D),
                              ),
                            );
                          }
                        },
                      ),
                      if (index != conversions.length - 1)
                        const Divider(
                          color: Colors.white12,
                          height: 30,
                        ),
                    ],
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  static String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }

    return amount.toStringAsFixed(2);
  }

  static String _formatTime(dynamic value) {
    if (value is! Timestamp) {
      return 'Just now';
    }

    final date = value.toDate();
    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    return '${difference.inDays}d ago';
  }
}

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_rounded,
            color: Color(0xFF8BE9FF),
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'No conversions yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your completed conversions will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class ConversionRow extends StatelessWidget {
  final String from;
  final String to;
  final String time;
  final VoidCallback onDelete;

  const ConversionRow({
    super.key,
    required this.from,
    required this.to,
    required this.time,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 1050;

    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 19,
            backgroundColor: Color(0x26315CE2),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF8BE9FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  from,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white38,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        to,
                        style: const TextStyle(
                          color: Color(0xFF8BE9FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete conversion',
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFFFA3A3),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0x26315CE2),
          child: Icon(
            Icons.swap_horiz_rounded,
            color: Color(0xFF8BE9FF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            from,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white38,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            to,
            style: const TextStyle(
              color: Color(0xFF8BE9FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Delete conversion',
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFFFA3A3),
          ),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 1050;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 17 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class LogoBox extends StatelessWidget {
  const LogoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.currency_exchange_rounded,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

class BackgroundGlow extends StatelessWidget {
  final double size;
  final Color color;

  const BackgroundGlow({
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
