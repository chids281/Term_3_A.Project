import 'package:flutter/material.dart';

import '../../services/currencies_service.dart';

class CurrencyDetailsScreen extends StatefulWidget {
  final String currencyCode;
  final String currencyName;
  final String initialBaseCurrency;

  const CurrencyDetailsScreen({
    super.key,
    required this.currencyCode,
    required this.currencyName,
    required this.initialBaseCurrency,
  });

  @override
  State<CurrencyDetailsScreen> createState() =>
      _CurrencyDetailsScreenState();
}

class _CurrencyDetailsScreenState
    extends State<CurrencyDetailsScreen> {
  final CurrencyService _currencyService = CurrencyService();

  final TextEditingController _amountController =
      TextEditingController(text: '1');

  late Future<CurrencyRateResponse> _ratesFuture;

  late String _baseCurrency;
  double _convertedAmount = 0;
  bool _isFavourite = false;

  final List<String> _popularCurrencies = [
    'USD',
    'NGN',
    'GBP',
    'EUR',
    'CAD',
    'JPY',
  ];

  @override
  void initState() {
    super.initState();
    _baseCurrency = widget.initialBaseCurrency;
    _ratesFuture = _loadRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<CurrencyRateResponse> _loadRates() async {
    final response =
        await _currencyService.getRates(_baseCurrency);

    final rate = response.rates[widget.currencyCode] ?? 0;
    final amount = double.tryParse(
          _amountController.text.trim().replaceAll(',', ''),
        ) ??
        1;

    _convertedAmount = amount * rate;

    return response;
  }

  void _refreshRates() {
    setState(() {
      _ratesFuture = _loadRates();
    });
  }

  void _convert(
    CurrencyRateResponse response,
  ) {
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

    final rate = response.rates[widget.currencyCode];

    if (rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This currency rate is unavailable.'),
          backgroundColor: Color(0xFFE5484D),
        ),
      );
      return;
    }

    setState(() {
      _convertedAmount = amount * rate;
    });
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
              CurrencyDetailsHeader(
                currencyCode: widget.currencyCode,
                onFavouritePressed: () {
                  setState(() {
                    _isFavourite = !_isFavourite;
                  });
                },
                isFavourite: _isFavourite,
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
                  child:
                      FutureBuilder<CurrencyRateResponse>(
                    future: _ratesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF315CE2),
                          ),
                        );
                      }

                      if (snapshot.hasError ||
                          snapshot.data == null) {
                        return CurrencyDetailsError(
                          onRetry: _refreshRates,
                        );
                      }

                      final response = snapshot.data!;
                      final currentRate =
                          response.rates[widget.currencyCode] ??
                              0;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(25),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 1450,
                            ),
                            child: Column(
                              children: [
                                CurrencyInformationBanner(
                                  currencyCode:
                                      widget.currencyCode,
                                  currencyName:
                                      widget.currencyName,
                                  baseCurrency:
                                      _baseCurrency,
                                  currentRate: currentRate,
                                  lastUpdated:
                                      response.lastUpdated,
                                ),
                                const SizedBox(height: 22),
                                LayoutBuilder(
                                  builder:
                                      (context, constraints) {
                                    final calculator =
                                        ConversionCalculator(
                                      amountController:
                                          _amountController,
                                      baseCurrency:
                                          _baseCurrency,
                                      targetCurrency:
                                          widget.currencyCode,
                                      convertedAmount:
                                          _convertedAmount,
                                      onConvert: () {
                                        _convert(response);
                                      },
                                    );

                                    final comparison =
                                        PopularComparisons(
                                      rates: response.rates,
                                      baseCurrency:
                                          _baseCurrency,
                                      popularCurrencies:
                                          _popularCurrencies,
                                    );

                                    if (constraints.maxWidth >=
                                        900) {
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: calculator,
                                          ),
                                          const SizedBox(
                                            width: 22,
                                          ),
                                          Expanded(
                                            flex: 6,
                                            child: comparison,
                                          ),
                                        ],
                                      );
                                    }

                                    return Column(
                                      children: [
                                        calculator,
                                        const SizedBox(
                                          height: 22,
                                        ),
                                        comparison,
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 22),
                                RateInformationCard(
                                  baseCurrency:
                                      _baseCurrency,
                                  targetCurrency:
                                      widget.currencyCode,
                                  currentRate: currentRate,
                                ),
                              ],
                            ),
                          ),
                        ),
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

class CurrencyDetailsHeader extends StatelessWidget {
  final String currencyCode;
  final bool isFavourite;
  final VoidCallback onFavouritePressed;

  const CurrencyDetailsHeader({
    super.key,
    required this.currencyCode,
    required this.isFavourite,
    required this.onFavouritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 22),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to currencies',
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currencyCode details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Review the live rate and calculate conversions.',
                  style: TextStyle(
                    color: Color(0xFFD7E4FF),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isFavourite
                ? 'Remove from favourites'
                : 'Add to favourites',
            onPressed: onFavouritePressed,
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.white.withValues(alpha: 0.12),
              foregroundColor: isFavourite
                  ? const Color(0xFFFFC857)
                  : Colors.white,
              padding: const EdgeInsets.all(14),
            ),
            icon: Icon(
              isFavourite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyInformationBanner extends StatelessWidget {
  final String currencyCode;
  final String currencyName;
  final String baseCurrency;
  final double currentRate;
  final DateTime lastUpdated;

  const CurrencyInformationBanner({
    super.key,
    required this.currencyCode,
    required this.currencyName,
    required this.baseCurrency,
    required this.currentRate,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102A56),
            Color(0xFF315CE2),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33315CE2),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFF8BE9FF),
              borderRadius: BorderRadius.circular(21),
            ),
            alignment: Alignment.center,
            child: Text(
              currencyCode.substring(0, 1),
              style: const TextStyle(
                color: Color(0xFF071A40),
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 21),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  currencyCode,
                  style: const TextStyle(
                    color: Color(0xFFD7E4FF),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'CURRENT RATE',
                style: TextStyle(
                  color: Color(0xFF8BE9FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '1 $baseCurrency = '
                '${_formatRate(currentRate)} $currencyCode',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Updated ${_formatDate(lastUpdated)}',
                style: const TextStyle(
                  color: Color(0xFFD7E4FF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRate(double value) {
    if (value >= 100) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(4);

    return value.toStringAsFixed(6);
  }

  static String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month =
        localDate.month.toString().padLeft(2, '0');
    final hour =
        localDate.hour.toString().padLeft(2, '0');
    final minute =
        localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/${localDate.year} $hour:$minute';
  }
}

class ConversionCalculator extends StatelessWidget {
  final TextEditingController amountController;
  final String baseCurrency;
  final String targetCurrency;
  final double convertedAmount;
  final VoidCallback onConvert;

  const ConversionCalculator({
    super.key,
    required this.amountController,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.convertedAmount,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      title: 'Quick conversion',
      icon: Icons.calculate_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              color: Color(0xFF102A56),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: amountController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: Color(0xFF315CE2),
              ),
              suffixText: baseCurrency,
              filled: true,
              fillColor: const Color(0xFFF4F7FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE3E9F3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'CONVERTED AMOUNT',
                  style: TextStyle(
                    color: Color(0xFF71809C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${_formatAmount(convertedAmount)} '
                  '$targetCurrency',
                  style: const TextStyle(
                    color: Color(0xFF315CE2),
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF315CE2),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 53),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onConvert,
              icon: const Icon(
                Icons.currency_exchange_rounded,
              ),
              label: const Text(
                'Convert amount',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAmount(double value) {
    return value.toStringAsFixed(2);
  }
}

class PopularComparisons extends StatelessWidget {
  final Map<String, double> rates;
  final String baseCurrency;
  final List<String> popularCurrencies;

  const PopularComparisons({
    super.key,
    required this.rates,
    required this.baseCurrency,
    required this.popularCurrencies,
  });

  @override
  Widget build(BuildContext context) {
    final currencies = popularCurrencies
        .where((code) => rates.containsKey(code))
        .toList();

    return DetailsCard(
      title: 'Popular comparisons',
      icon: Icons.compare_arrows_rounded,
      child: Column(
        children: currencies.map((currency) {
          final rate = rates[currency] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    currency.substring(0, 1),
                    style: const TextStyle(
                      color: Color(0xFF315CE2),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    '$baseCurrency / $currency',
                    style: const TextStyle(
                      color: Color(0xFF102A56),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _formatRate(rate),
                  style: const TextStyle(
                    color: Color(0xFF315CE2),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _formatRate(double value) {
    if (value >= 100) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(4);

    return value.toStringAsFixed(6);
  }
}

class RateInformationCard extends StatelessWidget {
  final String baseCurrency;
  final String targetCurrency;
  final double currentRate;

  const RateInformationCard({
    super.key,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.currentRate,
  });

  @override
  Widget build(BuildContext context) {
   final double inverseRate =
    currentRate == 0 ? 0.0 : 1.0 / currentRate;

    return DetailsCard(
      title: 'Rate information',
      icon: Icons.analytics_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              RateInfoBox(
                width: _boxWidth(constraints.maxWidth),
                title: 'Direct rate',
                value:
                    '1 $baseCurrency = '
                    '${_formatRate(currentRate)} $targetCurrency',
              ),
              RateInfoBox(
                width: _boxWidth(constraints.maxWidth),
                title: 'Inverse rate',
                value:
                    '1 $targetCurrency = '
                    '${_formatRate(inverseRate)} $baseCurrency',
              ),
              RateInfoBox(
                width: _boxWidth(constraints.maxWidth),
                title: 'Data type',
                value: 'Indicative midpoint rate',
              ),
            ],
          );
        },
      ),
    );
  }

  static double _boxWidth(double availableWidth) {
    if (availableWidth >= 850) {
      return (availableWidth - 30) / 3;
    }

    return availableWidth;
  }

  static String _formatRate(double value) {
    if (value >= 100) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(4);

    return value.toStringAsFixed(6);
  }
}

class RateInfoBox extends StatelessWidget {
  final double width;
  final String title;
  final String value;

  const RateInfoBox({
    super.key,
    required this.width,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE3E9F3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8290AA),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF102A56),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const DetailsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
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
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
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
          const SizedBox(height: 19),
          child,
        ],
      ),
    );
  }
}

class CurrencyDetailsError extends StatelessWidget {
  final VoidCallback onRetry;

  const CurrencyDetailsError({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Color(0xFFE5484D),
              size: 55,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load currency details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF102A56),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 17),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF315CE2),
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}