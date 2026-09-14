import 'package:flutter/material.dart';
import 'currency_details_screen.dart';
import '../../services/currencies_service.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() =>
      _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  final CurrencyService _currencyService = CurrencyService();

  final TextEditingController _searchController =
      TextEditingController();

  final List<String> _baseCurrencies = [
    'USD',
    'NGN',
    'GBP',
    'EUR',
    'CAD',
    'JPY',
  ];

  final Map<String, String> _currencyNames = {
    'USD': 'United States Dollar',
    'NGN': 'Nigerian Naira',
    'GBP': 'British Pound Sterling',
    'EUR': 'Euro',
    'CAD': 'Canadian Dollar',
    'JPY': 'Japanese Yen',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'GHS': 'Ghanaian Cedi',
    'ZAR': 'South African Rand',
    'KES': 'Kenyan Shilling',
    'AED': 'United Arab Emirates Dirham',
    'INR': 'Indian Rupee',
    'NZD': 'New Zealand Dollar',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'BRL': 'Brazilian Real',
    'MXN': 'Mexican Peso',
    'SAR': 'Saudi Riyal',
    'TRY': 'Turkish Lira',
    'KRW': 'South Korean Won',
    'EGP': 'Egyptian Pound',
    'UGX': 'Ugandan Shilling',
    'TZS': 'Tanzanian Shilling',
  };

  String _selectedBaseCurrency = 'USD';

  late Future<CurrencyRateResponse> _ratesFuture;

  @override
  void initState() {
    super.initState();
    _ratesFuture = _loadRates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<CurrencyRateResponse> _loadRates() {
    return _currencyService.getRates(_selectedBaseCurrency);
  }

  void _refreshRates() {
    setState(() {
      _ratesFuture = _loadRates();
    });
  }

  void _changeBaseCurrency(String? currency) {
    if (currency == null ||
        currency == _selectedBaseCurrency) {
      return;
    }

    setState(() {
      _selectedBaseCurrency = currency;
      _ratesFuture = _loadRates();
    });
  }

  List<MapEntry<String, double>> _filterRates(
    Map<String, double> rates,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    final filteredRates = rates.entries.where((entry) {
      final code = entry.key.toLowerCase();
      final name =
          (_currencyNames[entry.key] ?? '').toLowerCase();

      return query.isEmpty ||
          code.contains(query) ||
          name.contains(query);
    }).toList();

    filteredRates.sort((first, second) {
      final firstIsKnown =
          _currencyNames.containsKey(first.key);
      final secondIsKnown =
          _currencyNames.containsKey(second.key);

      if (firstIsKnown && !secondIsKnown) return -1;
      if (!firstIsKnown && secondIsKnown) return 1;

      return first.key.compareTo(second.key);
    });

    return filteredRates;
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
              const CurrenciesHeader(),
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
                clipBehavior: Clip.antiAlias,
                child: FutureBuilder<CurrencyRateResponse>(
                    future: _ratesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CurrencyLoadingView();
                      }

                      if (snapshot.hasError) {
                        return CurrencyErrorView(
                          onRetry: _refreshRates,
                        );
                      }

                      final response = snapshot.data;

                      if (response == null) {
                        return CurrencyErrorView(
                          onRetry: _refreshRates,
                        );
                      }

                      final filteredRates =
                          _filterRates(response.rates);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(25),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 1450,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                CurrencySummary(
                                  baseCurrency:
                                      response.baseCurrency,
                                  totalCurrencies:
                                      response.rates.length,
                                  lastUpdated:
                                      response.lastUpdated,
                                ),
                                const SizedBox(height: 22),
                                CurrencyToolbar(
                                  searchController:
                                      _searchController,
                                  baseCurrencies:
                                      _baseCurrencies,
                                  selectedBaseCurrency:
                                      _selectedBaseCurrency,
                                  onSearchChanged: (value) {
                                    setState(() {});
                                  },
                                  onBaseCurrencyChanged:
                                      _changeBaseCurrency,
                                  onRefresh: _refreshRates,
                                ),
                                const SizedBox(height: 23),
                                Row(
                                  children: [
                                    const Text(
                                      'Available currencies',
                                      style: TextStyle(
                                        color:
                                            Color(0xFF102A56),
                                        fontSize: 22,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${filteredRates.length} results',
                                      style: const TextStyle(
                                        color:
                                            Color(0xFF8290AA),
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                if (filteredRates.isEmpty)
                                  const EmptyCurrencySearch()
                                else
                                  LayoutBuilder(
                                    builder:
                                        (context, constraints) {
                                      final columns =
                                          constraints.maxWidth >=
                                                  1100
                                              ? 4
                                              : constraints.maxWidth >=
                                                      750
                                                  ? 3
                                                  : constraints
                                                              .maxWidth >=
                                                          500
                                                      ? 2
                                                      : 1;

                                      const spacing = 15.0;

                                      final cardWidth =
                                          columns == 1
                                              ? constraints.maxWidth
                                              : (constraints.maxWidth -
                                                      spacing *
                                                          (columns -
                                                              1)) /
                                                  columns;

                                      return Wrap(
                                        spacing: spacing,
                                        runSpacing: spacing,
                                        children:
                                            filteredRates.map(
                                          (entry) {
                                            final currencyName =
                                            _currencyNames[entry.key] ??
                                                '${entry.key} Currency';

                                        return SizedBox(
                                          width: cardWidth,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CurrencyDetailsScreen(
                                                    currencyCode: entry.key,
                                                    currencyName: currencyName,
                                                    initialBaseCurrency: response.baseCurrency,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: CurrencyRateCard(
                                                code: entry.key,
                                                name: currencyName,
                                                rate: entry.value,
                                                baseCurrency: response.baseCurrency,
                                              ),
                                            ),
                                          ),
                                        );
                                          },
                                        ).toList(),
                                      );
                                    },
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

class CurrenciesHeader extends StatelessWidget {
  const CurrenciesHeader({super.key});

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currencies',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Search currencies and compare live exchange rates.',
                  style: TextStyle(
                    color: Color(0xFFD7E4FF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public_rounded,
                  color: Color(0xFF8BE9FF),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Global currencies',
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

class CurrencySummary extends StatelessWidget {
  final String baseCurrency;
  final int totalCurrencies;
  final DateTime lastUpdated;

  const CurrencySummary({
    super.key,
    required this.baseCurrency,
    required this.totalCurrencies,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          CurrencySummaryCard(
            icon: Icons.currency_exchange_rounded,
            title: baseCurrency,
            subtitle: 'Selected base',
            color: const Color(0xFF315CE2),
          ),
          CurrencySummaryCard(
            icon: Icons.public_rounded,
            title: '$totalCurrencies',
            subtitle: 'Available currencies',
            color: const Color(0xFF8069E8),
          ),
          CurrencySummaryCard(
            icon: Icons.schedule_rounded,
            title: _formatDate(lastUpdated),
            subtitle: 'Provider update',
            color: const Color(0xFF21A4D8),
          ),
        ];

        final columns =
            constraints.maxWidth >= 700 ? 3 : 1;
        const spacing = 15.0;

        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth -
                    spacing * (columns - 1)) /
                columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: width,
              child: card,
            );
          }).toList(),
        );
      },
    );
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

    return '$day/$month $hour:$minute';
  }
}

class CurrencySummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const CurrencySummaryCard({
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
            width: 49,
            height: 49,
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
                  overflow: TextOverflow.ellipsis,
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

class CurrencyToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> baseCurrencies;
  final String selectedBaseCurrency;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onBaseCurrencyChanged;
  final VoidCallback onRefresh;

  const CurrencyToolbar({
    super.key,
    required this.searchController,
    required this.baseCurrencies,
    required this.selectedBaseCurrency,
    required this.onSearchChanged,
    required this.onBaseCurrencyChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E9F3),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final searchField = SizedBox(
            width: constraints.maxWidth >= 700
                ? 420
                : constraints.maxWidth,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText:
                    'Search by currency name or code...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF315CE2),
                ),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: const Color(0xFFF4F7FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          );

          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Base:',
                style: TextStyle(
                  color: Color(0xFF71809C),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 115,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedBaseCurrency,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF4F7FC),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: baseCurrencies.map((currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: onBaseCurrencyChanged,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Refresh rates',
                onPressed: onRefresh,
                style: IconButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFEAF0FF),
                  foregroundColor:
                      const Color(0xFF315CE2),
                  padding: const EdgeInsets.all(14),
                ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          );

          if (constraints.maxWidth < 700) {
            return Column(
              children: [
                searchField,
                const SizedBox(height: 14),
                controls,
              ],
            );
          }

          return Row(
            children: [
              searchField,
              const Spacer(),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class CurrencyRateCard extends StatelessWidget {
  final String code;
  final String name;
  final double rate;
  final String baseCurrency;

  const CurrencyRateCard({
    super.key,
    required this.code,
    required this.name,
    required this.rate,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
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
            alignment: Alignment.center,
            child: Text(
              code.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        color: Color(0xFF102A56),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (code == baseCurrency) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'BASE',
                          style: TextStyle(
                            color: Color(0xFF315CE2),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8290AA),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1 $baseCurrency = ${_formatRate(rate)} $code',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF315CE2),
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

class CurrencyLoadingView extends StatelessWidget {
  const CurrencyLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF315CE2),
          ),
          SizedBox(height: 14),
          Text(
            'Loading global exchange rates...',
            style: TextStyle(
              color: Color(0xFF71809C),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const CurrencyErrorView({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFFD1D1),
          ),
        ),
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
              'Unable to load currencies',
              style: TextStyle(
                color: Color(0xFF102A56),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF71809C),
              ),
            ),
            const SizedBox(height: 18),
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

class EmptyCurrencySearch extends StatelessWidget {
  const EmptyCurrencySearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE3E9F3),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Color(0xFF315CE2),
            size: 55,
          ),
          SizedBox(height: 15),
          Text(
            'No matching currency found',
            style: TextStyle(
              color: Color(0xFF102A56),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Try searching with another name or currency code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF71809C),
            ),
          ),
        ],
      ),
    );
  }
}