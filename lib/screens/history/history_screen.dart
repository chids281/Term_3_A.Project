import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/database_services.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseServices _databaseServices = DatabaseServices();

  Future<void> _clearHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const Icon(
            Icons.delete_sweep_outlined,
            color: Color(0xFFE5484D),
            size: 48,
          ),
          title: const Text(
            'Clear conversion history?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Every saved conversion will be permanently removed.',
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
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Clear history'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    try {
      await _databaseServices.clearConversionHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversion history cleared.'),
          backgroundColor: Color(0xFF315CE2),
        ),
      );
    } catch (error) {
      if (!mounted) return;

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
              HistoryHeader(
                onClearHistory: _clearHistory,
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
                    stream:
                        _databaseServices.getConversionHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const HistoryMessage(
                          icon: Icons.error_outline_rounded,
                          title: 'Unable to load history',
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

                      final conversions = snapshot.data?.docs ?? [];

                      if (conversions.isEmpty) {
                        return const HistoryMessage(
                          icon: Icons.history_rounded,
                          title: 'No conversions yet',
                          message:
                              'Complete a conversion and it will appear here.',
                        );
                      }

                      return Column(
                        children: [
                          HistorySummary(
                            conversionCount: conversions.length,
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                5,
                                24,
                                30,
                              ),
                              itemCount: conversions.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 14);
                              },
                              itemBuilder: (context, index) {
                                final document = conversions[index];
                                final data = document.data();

                                return HistoryCard(
                                  fromCurrency: data['fromCurrency']
                                          ?.toString() ??
                                      '',
                                  toCurrency: data['toCurrency']
                                          ?.toString() ??
                                      '',
                                  amount: (data['amount'] as num?)
                                          ?.toDouble() ??
                                      0,
                                  convertedAmount:
                                      (data['convertedAmount'] as num?)
                                              ?.toDouble() ??
                                          0,
                                  timestamp: data['createdAt'],
                                  onDelete: () async {
                                    await _databaseServices
                                        .deleteConversion(
                                      document.id,
                                    );
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

class HistoryHeader extends StatelessWidget {
  final VoidCallback onClearHistory;

  const HistoryHeader({
    super.key,
    required this.onClearHistory,
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
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversion history',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review and manage your previous conversions.',
                  style: TextStyle(
                    color: Color(0xFFD7E4FF),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onClearHistory,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.25),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Color(0xFFFFB4B4),
            ),
            label: const Text(
              'Clear history',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistorySummary extends StatelessWidget {
  final int conversionCount;

  const HistorySummary({
    super.key,
    required this.conversionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: SummaryCard(
              icon: Icons.swap_horiz_rounded,
              title: '$conversionCount',
              subtitle: 'Saved conversions',
              color: const Color(0xFF315CE2),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: SummaryCard(
              icon: Icons.public_rounded,
              title: '6',
              subtitle: 'Available currencies',
              color: Color(0xFF8069E8),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: SummaryCard(
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

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const SummaryCard({
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
        border: Border.all(
          color: const Color(0xFFE5EAF3),
        ),
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
            child: Icon(
              icon,
              color: color,
            ),
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

class HistoryCard extends StatelessWidget {
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double convertedAmount;
  final dynamic timestamp;
  final VoidCallback onDelete;

  const HistoryCard({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.convertedAmount,
    required this.timestamp,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
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
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF315CE2),
                  Color(0xFF21A4D8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.currency_exchange_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${_formatAmount(amount)} $fromCurrency',
                  style: const TextStyle(
                    color: Color(0xFF102A56),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF9AA7BC),
                ),
                Text(
                  '${_formatAmount(convertedAmount)} $toCurrency',
                  style: const TextStyle(
                    color: Color(0xFF315CE2),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Text(
            _formatDate(timestamp),
            style: const TextStyle(
              color: Color(0xFF8290AA),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Delete conversion',
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

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  static String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Just now';
    }

    final date = value.toDate();

    return '${date.day}/${date.month}/${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const HistoryMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFFE3E9F3),
          ),
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
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF315CE2),
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
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
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}