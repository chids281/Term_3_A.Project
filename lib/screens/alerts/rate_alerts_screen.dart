import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/currencies_service.dart';
import '../../services/database_services.dart';

class RateAlertsScreen extends StatefulWidget {
  const RateAlertsScreen({super.key});

  @override
  State<RateAlertsScreen> createState() => _RateAlertsScreenState();
}

class _RateAlertsScreenState extends State<RateAlertsScreen> {
  final DatabaseServices _databaseServices = DatabaseServices();
  final CurrencyService _currencyService = CurrencyService();

  Timer? _alertTimer;
  bool _isCheckingAlerts = false;

  final List<String> _currencies = [
    'USD',
    'NGN',
    'GBP',
    'EUR',
    'CAD',
    'GHS',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveAlerts();
    });

    _alertTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkActiveAlerts(),
    );
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _showCreateAlertDialog() async {
    String fromCurrency = 'USD';
    String toCurrency = 'NGN';
    String condition = 'above';
    final rateController = TextEditingController();

    final alertData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF7F9FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(25, 24, 25, 10),
              actionsPadding: const EdgeInsets.fromLTRB(25, 10, 25, 24),
              title: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF071A40),
                      Color(0xFF315CE2),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Create rate alert',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currency pair',
                      style: TextStyle(
                        color: Color(0xFF102A56),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CurrencyDropdown(
                            value: fromCurrency,
                            currencies: _currencies,
                            label: 'From',
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                fromCurrency = value;
                              });
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF315CE2),
                          ),
                        ),
                        Expanded(
                          child: CurrencyDropdown(
                            value: toCurrency,
                            currencies: _currencies,
                            label: 'To',
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                toCurrency = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Alert condition',
                      style: TextStyle(
                        color: Color(0xFF102A56),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AlertConditionButton(
                            title: 'Goes above',
                            icon: Icons.trending_up_rounded,
                            isSelected: condition == 'above',
                            onTap: () {
                              setDialogState(() {
                                condition = 'above';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AlertConditionButton(
                            title: 'Goes below',
                            icon: Icons.trending_down_rounded,
                            isSelected: condition == 'below',
                            onTap: () {
                              setDialogState(() {
                                condition = 'below';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Target exchange rate',
                      style: TextStyle(
                        color: Color(0xFF102A56),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'For example: 1600',
                        prefixIcon: const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF315CE2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFDCE3F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFDCE3F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFF315CE2),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF315CE2),
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final targetRate = double.tryParse(
                      rateController.text.trim().replaceAll(',', ''),
                    );

                    if (fromCurrency == toCurrency) {
                      _showMessage(
                        dialogContext,
                        'Please select two different currencies.',
                        isError: true,
                      );
                      return;
                    }

                    if (targetRate == null || targetRate <= 0) {
                      _showMessage(
                        dialogContext,
                        'Please enter a valid target rate.',
                        isError: true,
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'fromCurrency': fromCurrency,
                        'toCurrency': toCurrency,
                        'targetRate': targetRate,
                        'condition': condition,
                      },
                    );
                  },
                  icon: const Icon(Icons.add_alert_rounded),
                  label: const Text(
                    'Create alert',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    rateController.dispose();

    if (alertData == null || !mounted) return;

    try {
      await _databaseServices.saveRateAlert(
        fromCurrency: alertData['fromCurrency'] as String,
        toCurrency: alertData['toCurrency'] as String,
        targetRate: alertData['targetRate'] as double,
        condition: alertData['condition'] as String,
      );

      await _checkActiveAlerts();

      if (!mounted) return;

      _showMessage(
        context,
        '${alertData['fromCurrency']} to '
        '${alertData['toCurrency']} alert created.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _checkActiveAlerts({
    bool showResult = false,
  }) async {
    if (_isCheckingAlerts) return;

    if (mounted) {
      setState(() {
        _isCheckingAlerts = true;
      });
    }

    int triggeredCount = 0;

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

        final response = ratesByBase[fromCurrency] ??
            await _currencyService.getRates(fromCurrency);

        ratesByBase[fromCurrency] = response;

        final currentRate = response.rates[toCurrency];

        if (currentRate == null) {
          continue;
        }

        await _databaseServices.updateRateAlertCheck(
          alertId: alert.id,
          currentRate: currentRate,
        );

        final hasReachedTarget = condition == 'below'
            ? currentRate <= targetRate
            : currentRate >= targetRate;

        if (hasReachedTarget) {
          final wasTriggered =
              await _databaseServices.triggerRateAlert(
            alertId: alert.id,
            currentRate: currentRate,
          );

          if (wasTriggered) {
            triggeredCount++;
          }
        }
      }

      if (showResult && mounted) {
        _showMessage(
          context,
          triggeredCount > 0
              ? '$triggeredCount rate '
                  '${triggeredCount == 1 ? 'alert was' : 'alerts were'} triggered.'
              : 'All active alerts are up to date.',
        );
      }
    } catch (error) {
      if (showResult && mounted) {
        _showMessage(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAlerts = false;
        });
      }
    }
  }

  Future<void> _updateAlertStatus({
    required String alertId,
    required bool isActive,
  }) async {
    try {
      await _databaseServices.updateRateAlertStatus(
        alertId: alertId,
        isActive: isActive,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _deleteAlert(String alertId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const Icon(
            Icons.notifications_off_outlined,
            color: Color(0xFFE5484D),
            size: 45,
          ),
          title: const Text(
            'Delete this alert?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'You will no longer be notified about this target rate.',
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
                  horizontal: 20,
                  vertical: 13,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete alert'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await _databaseServices.deleteRateAlert(alertId);

      if (!mounted) return;

      _showMessage(context, 'Rate alert deleted.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showMessage(
    BuildContext context,
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
              AlertsHeader(
                onCreateAlert: _showCreateAlertDialog,
                onCheckAlerts: () {
                  _checkActiveAlerts(showResult: true);
                },
                isCheckingAlerts: _isCheckingAlerts,
              ),
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
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: _databaseServices.getRateAlerts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const AlertMessage(
                          icon: Icons.error_outline_rounded,
                          title: 'Unable to load alerts',
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

                      final alerts = snapshot.data?.docs ?? [];

                      if (alerts.isEmpty) {
                        return EmptyAlerts(
                          onCreateAlert: _showCreateAlertDialog,
                        );
                      }

                      final activeAlerts = alerts.where((document) {
                        return document.data()['isActive'] == true;
                      }).length;

                      return Column(
                        children: [
                          AlertsSummary(
                            totalAlerts: alerts.length,
                            activeAlerts: activeAlerts,
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                5,
                                24,
                                30,
                              ),
                              itemCount: alerts.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 14);
                              },
                              itemBuilder: (context, index) {
                                final document = alerts[index];
                                final data = document.data();

                                final fromCurrency =
                                    data['fromCurrency']?.toString() ?? '';
                                final toCurrency =
                                    data['toCurrency']?.toString() ?? '';
                                final targetRate =
                                    (data['targetRate'] as num?)
                                            ?.toDouble() ??
                                        0;
                                final isActive =
                                    data['isActive'] as bool? ?? true;
                                final isTriggered =
                                    data['isTriggered'] as bool? ?? false;
                                final condition =
                                    data['condition']?.toString() ??
                                        'above';
                                final currentRate =
                                    (data['lastCheckedRate'] as num?)
                                        ?.toDouble();

                                return AlertCard(
                                  fromCurrency: fromCurrency,
                                  toCurrency: toCurrency,
                                  targetRate: targetRate,
                                  isActive: isActive,
                                  isTriggered: isTriggered,
                                  condition: condition,
                                  currentRate: currentRate,
                                  onStatusChanged: (value) {
                                    _updateAlertStatus(
                                      alertId: document.id,
                                      isActive: value,
                                    );
                                  },
                                  onDelete: () {
                                    _deleteAlert(document.id);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
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

class AlertsHeader extends StatelessWidget {
  final VoidCallback onCreateAlert;
  final VoidCallback onCheckAlerts;
  final bool isCheckingAlerts;

  const AlertsHeader({
    super.key,
    required this.onCreateAlert,
    required this.onCheckAlerts,
    required this.isCheckingAlerts,
  });

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
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Get notified when currencies reach your target rate.',
                  style: TextStyle(
                    color: Color(0xFFD7E4FF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Check live rates',
            onPressed: isCheckingAlerts ? null : onCheckAlerts,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  Colors.white.withValues(alpha: 0.08),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.all(14),
            ),
            icon: isCheckingAlerts
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF315CE2),
              minimumSize: Size.zero,
              fixedSize: const Size(150, 50),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: onCreateAlert,
            icon: const Icon(Icons.add_alert_rounded),
            label: const Text(
              'New alert',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertsSummary extends StatelessWidget {
  final int totalAlerts;
  final int activeAlerts;

  const AlertsSummary({
    super.key,
    required this.totalAlerts,
    required this.activeAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: AlertSummaryCard(
              icon: Icons.notifications_active_outlined,
              title: '$activeAlerts',
              subtitle: 'Active alerts',
              color: const Color(0xFF315CE2),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: AlertSummaryCard(
              icon: Icons.notifications_none_rounded,
              title: '$totalAlerts',
              subtitle: 'Total alerts',
              color: const Color(0xFF8069E8),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: AlertSummaryCard(
              icon: Icons.cloud_done_outlined,
              title: 'Synced',
              subtitle: 'Firebase storage',
              color: Color(0xFF21A4D8),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const AlertSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D102A56),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102A56),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
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
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final String fromCurrency;
  final String toCurrency;
  final double targetRate;
  final bool isActive;
  final bool isTriggered;
  final String condition;
  final double? currentRate;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback onDelete;

  const AlertCard({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.targetRate,
    required this.isActive,
    required this.isTriggered,
    required this.condition,
    required this.currentRate,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE3E9F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C102A56),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? const [
                        Color(0xFF315CE2),
                        Color(0xFF21A4D8),
                      ]
                    : const [
                        Color(0xFF9AA7BC),
                        Color(0xFFBBC4D2),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fromCurrency → $toCurrency',
                  style: const TextStyle(
                    color: Color(0xFF102A56),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Notify me when 1 $fromCurrency goes $condition '
                  '${_formatRate(targetRate)} $toCurrency',
                  style: const TextStyle(
                    color: Color(0xFF71809C),
                  ),
                ),
                if (currentRate != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Current live rate: '
                    '${_formatRate(currentRate!)} $toCurrency',
                    style: const TextStyle(
                      color: Color(0xFF315CE2),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFEAF0FF)
                  : isTriggered
                      ? const Color(0xFFE8FBF3)
                      : const Color(0xFFF0F2F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isTriggered
                  ? 'Triggered'
                  : isActive
                      ? 'Active'
                      : 'Paused',
              style: TextStyle(
                color: isTriggered
                    ? const Color(0xFF168B62)
                    : isActive
                        ? const Color(0xFF315CE2)
                        : const Color(0xFF8290AA),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: isActive,
            activeThumbColor: const Color(0xFF315CE2),
            onChanged: onStatusChanged,
          ),
          IconButton(
            tooltip: 'Delete alert',
            onPressed: onDelete,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFF0F0),
            ),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFE5484D),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRate(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }
}

class EmptyAlerts extends StatelessWidget {
  final VoidCallback onCreateAlert;

  const EmptyAlerts({
    super.key,
    required this.onCreateAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 470),
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFE3E9F3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12102A56),
              blurRadius: 25,
              offset: Offset(0, 12),
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
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.add_alert_rounded,
                color: Color(0xFF315CE2),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No rate alerts yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF102A56),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an alert and CurrenSee will monitor your '
              'selected currency pair.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF71809C),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF315CE2),
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onCreateAlert,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create your first alert',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const AlertMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFFE5484D),
              size: 55,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF102A56),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF71809C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertConditionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const AlertConditionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEAF0FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF315CE2)
                  : const Color(0xFFDCE3F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF315CE2)
                    : const Color(0xFF71809C),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF315CE2)
                      : const Color(0xFF102A56),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyDropdown extends StatelessWidget {
  final String value;
  final String label;
  final List<String> currencies;
  final ValueChanged<String?> onChanged;

  const CurrencyDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.currencies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFDCE3F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFDCE3F0),
          ),
        ),
      ),
      items: currencies.map((currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(
            currency,
            style: const TextStyle(
              color: Color(0xFF102A56),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
