import 'package:flutter/material.dart';

import '../../services/currencies_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final CurrencyService _currencyService = CurrencyService();

  final TextEditingController _searchController =
      TextEditingController();

  late Future<List<LiveMarketRate>> _marketRates;

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Currencies',
    'Economy',
    'Central Banks',
    'Market Updates',
  ];

  final List<MarketNews> _newsItems = [
    const MarketNews(
      title: 'Dollar remains central to global currency trading',
      summary:
          'Currency traders continue to monitor inflation, employment '
          'and interest-rate expectations across major economies.',
      category: 'Currencies',
      source: 'CurrenSee Insights',
      date: 'Market insight',
      icon: Icons.attach_money_rounded,
      color: Color(0xFF315CE2),
    ),
    const MarketNews(
      title: 'Pound responds to changing European market conditions',
      summary:
          'Sterling movements are often influenced by economic growth, '
          'inflation expectations and general investor sentiment.',
      category: 'Market Updates',
      source: 'CurrenSee Insights',
      date: 'Market insight',
      icon: Icons.currency_pound_rounded,
      color: Color(0xFF8069E8),
    ),
    const MarketNews(
      title: 'Central banks remain important to currency investors',
      summary:
          'Policy decisions and interest-rate announcements can strongly '
          'influence the direction of major currency pairs.',
      category: 'Central Banks',
      source: 'CurrenSee Insights',
      date: 'Market insight',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF21A4D8),
    ),
    const MarketNews(
      title: 'Euro markets reflect regional economic expectations',
      summary:
          'The euro can react to regional growth figures, inflation data '
          'and monetary-policy decisions.',
      category: 'Economy',
      source: 'CurrenSee Insights',
      date: 'Market insight',
      icon: Icons.euro_rounded,
      color: Color(0xFFFF7A59),
    ),
    const MarketNews(
      title: 'Emerging currencies attract global market attention',
      summary:
          'Emerging-market currencies may provide opportunities while '
          'also carrying increased volatility and economic risk.',
      category: 'Currencies',
      source: 'CurrenSee Insights',
      date: 'Market insight',
      icon: Icons.public_rounded,
      color: Color(0xFF21B6C9),
    ),
    const MarketNews(
      title: 'Economic reports can cause exchange-rate movement',
      summary:
          'Employment reports, inflation figures and policy statements '
          'are closely monitored by global currency traders.',
      category: 'Economy',
      source: 'CurrenSee Insights',
      date: 'Market insight',
      icon: Icons.insights_rounded,
      color: Color(0xFFE39B32),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _marketRates = _loadMarketRates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<LiveMarketRate>> _loadMarketRates() async {
    final responses = await Future.wait([
      _currencyService.getRates('USD'),
      _currencyService.getRates('GBP'),
      _currencyService.getRates('EUR'),
    ]);

    final usdRates = responses[0];
    final gbpRates = responses[1];
    final eurRates = responses[2];

    final usdNgn = usdRates.rates['NGN'];
    final usdJpy = usdRates.rates['JPY'];
    final gbpUsd = gbpRates.rates['USD'];
    final eurUsd = eurRates.rates['USD'];

    if (usdNgn == null ||
        usdJpy == null ||
        gbpUsd == null ||
        eurUsd == null) {
      throw Exception(
        'Some market rates are currently unavailable.',
      );
    }

    return [
      LiveMarketRate(
        pair: 'USD / NGN',
        value: usdNgn,
        symbol: '\$',
        color: const Color(0xFF315CE2),
        lastUpdated: usdRates.lastUpdated,
      ),
      LiveMarketRate(
        pair: 'GBP / USD',
        value: gbpUsd,
        symbol: '£',
        color: const Color(0xFF8069E8),
        lastUpdated: gbpRates.lastUpdated,
      ),
      LiveMarketRate(
        pair: 'EUR / USD',
        value: eurUsd,
        symbol: '€',
        color: const Color(0xFFFF7A59),
        lastUpdated: eurRates.lastUpdated,
      ),
      LiveMarketRate(
        pair: 'USD / JPY',
        value: usdJpy,
        symbol: '¥',
        color: const Color(0xFF21B6C9),
        lastUpdated: usdRates.lastUpdated,
      ),
    ];
  }

  void _refreshMarketRates() {
    setState(() {
      _marketRates = _loadMarketRates();
    });
  }

  List<MarketNews> get _filteredNews {
    final query = _searchController.text.trim().toLowerCase();

    return _newsItems.where((news) {
      final matchesCategory = _selectedCategory == 'All' ||
          news.category == _selectedCategory;

      final matchesSearch = query.isEmpty ||
          news.title.toLowerCase().contains(query) ||
          news.summary.toLowerCase().contains(query) ||
          news.source.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNews = _filteredNews;

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
              const NewsHeader(),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1450,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LiveMarketOverview(
                              marketRates: _marketRates,
                              onRefresh: _refreshMarketRates,
                            ),
                            const SizedBox(height: 26),
                            NewsToolbar(
                              searchController: _searchController,
                              categories: _categories,
                              selectedCategory: _selectedCategory,
                              onSearchChanged: (value) {
                                setState(() {});
                              },
                              onCategorySelected: (category) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Text(
                                  'Currency market insights',
                                  style: TextStyle(
                                    color: Color(0xFF102A56),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${filteredNews.length} insights',
                                  style: const TextStyle(
                                    color: Color(0xFF8290AA),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (filteredNews.isEmpty)
                              const EmptyNews()
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns =
                                      constraints.maxWidth >= 1050
                                          ? 3
                                          : constraints.maxWidth >= 700
                                              ? 2
                                              : 1;

                                  const spacing = 18.0;

                                  final cardWidth = columns == 1
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth -
                                              spacing *
                                                  (columns - 1)) /
                                          columns;

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children:
                                        filteredNews.map((news) {
                                      return SizedBox(
                                        width: cardWidth,
                                        child: NewsCard(
                                          news: news,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                          ],
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

class NewsHeader extends StatelessWidget {
  const NewsHeader({super.key});

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
                  'Market news',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Follow live exchange rates and market insights.',
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
                  Icons.circle,
                  color: Color(0xFF8BE9FF),
                  size: 10,
                ),
                SizedBox(width: 8),
                Text(
                  'Live rates',
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

class LiveMarketOverview extends StatelessWidget {
  final Future<List<LiveMarketRate>> marketRates;
  final VoidCallback onRefresh;

  const LiveMarketOverview({
    super.key,
    required this.marketRates,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LiveMarketRate>>(
      future: marketRates,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 145,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE3E9F3),
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF315CE2),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Loading live exchange rates...',
                    style: TextStyle(
                      color: Color(0xFF71809C),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD1D1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: Color(0xFFE5484D),
                  size: 35,
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unable to load market rates',
                        style: TextStyle(
                          color: Color(0xFF102A56),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Check your connection and try again.',
                        style: TextStyle(
                          color: Color(0xFF71809C),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Retry',
                  onPressed: onRefresh,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF0FF),
                    foregroundColor: const Color(0xFF315CE2),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          );
        }

        final rates = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 4
                : constraints.maxWidth >= 650
                    ? 2
                    : 1;

            const spacing = 15.0;

            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth -
                        spacing * (columns - 1)) /
                    columns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Live exchange rates',
                      style: TextStyle(
                        color: Color(0xFF102A56),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh rates',
                      onPressed: onRefresh,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF0FF),
                        foregroundColor: const Color(0xFF315CE2),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: rates.map((rate) {
                    return SizedBox(
                      width: width,
                      child: LiveMarketCard(rate: rate),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class LiveMarketCard extends StatelessWidget {
  final LiveMarketRate rate;

  const LiveMarketCard({
    super.key,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: rate.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              rate.symbol,
              style: TextStyle(
                color: rate.color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rate.pair,
                  style: const TextStyle(
                    color: Color(0xFF8290AA),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRate(rate.value),
                  style: const TextStyle(
                    color: Color(0xFF102A56),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated ${_formatTime(rate.lastUpdated)}',
                  style: const TextStyle(
                    color: Color(0xFF1FA97A),
                    fontSize: 11,
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

    return value.toStringAsFixed(4);
  }

  static String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class NewsToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;

  const NewsToolbar({
    super.key,
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
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
          final searchBox = SizedBox(
            width: constraints.maxWidth >= 850
                ? 340
                : constraints.maxWidth,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search market insights...',
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

          final filters = Wrap(
            spacing: 9,
            runSpacing: 9,
            children: categories.map((category) {
              final selected = selectedCategory == category;

              return ChoiceChip(
                label: Text(category),
                selected: selected,
                selectedColor: const Color(0xFF315CE2),
                backgroundColor: const Color(0xFFF4F7FC),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF315CE2)
                      : const Color(0xFFE3E9F3),
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF71809C),
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) {
                  onCategorySelected(category);
                },
              );
            }).toList(),
          );

          if (constraints.maxWidth < 850) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchBox,
                const SizedBox(height: 15),
                filters,
              ],
            );
          }

          return Row(
            children: [
              searchBox,
              const SizedBox(width: 20),
              Expanded(child: filters),
            ],
          );
        },
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final MarketNews news;

  const NewsCard({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: news.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  news.icon,
                  color: news.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  news.category,
                  style: const TextStyle(
                    color: Color(0xFF315CE2),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            news.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF102A56),
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 82,
            child: Text(
              news.summary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF71809C),
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
          const Divider(
            height: 18,
            color: Color(0xFFE5EAF3),
          ),
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFF9AA7BC),
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  news.source,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF71809C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                news.date,
                style: const TextStyle(
                  color: Color(0xFF9AA7BC),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyNews extends StatelessWidget {
  const EmptyNews({super.key});

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
            'No matching insights found',
            style: TextStyle(
              color: Color(0xFF102A56),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Try another keyword or select a different category.',
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

class LiveMarketRate {
  final String pair;
  final double value;
  final String symbol;
  final Color color;
  final DateTime lastUpdated;

  const LiveMarketRate({
    required this.pair,
    required this.value,
    required this.symbol,
    required this.color,
    required this.lastUpdated,
  });
}

class MarketNews {
  final String title;
  final String summary;
  final String category;
  final String source;
  final String date;
  final IconData icon;
  final Color color;

  const MarketNews({
    required this.title,
    required this.summary,
    required this.category,
    required this.source,
    required this.date,
    required this.icon,
    required this.color,
  });
}