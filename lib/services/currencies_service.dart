import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl =
      'https://open.er-api.com/v6/latest';

  static const String _historicalCdnUrl =
      'https://cdn.jsdelivr.net/npm/'
      '@fawazahmed0/currency-api';

  Future<CurrencyRateResponse> getRates(
    String baseCurrency,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/${baseCurrency.toUpperCase()}',
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to load exchange rates. Please try again.',
        );
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic> ||
          data['result'] != 'success') {
        throw Exception(
          'The exchange-rate provider returned an error.',
        );
      }

      final rawRates = data['rates'];

      if (rawRates is! Map<String, dynamic>) {
        throw Exception(
          'No exchange rates were received.',
        );
      }

      final rates = rawRates.map(
        (currency, value) => MapEntry(
          currency,
          (value as num).toDouble(),
        ),
      );

      return CurrencyRateResponse(
        baseCurrency: data['base_code'] as String,
        rates: rates,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          (data['time_last_update_unix'] as num).toInt() *
              1000,
          isUtc: true,
        ),
      );
    } on FormatException {
      throw Exception(
        'The exchange-rate information could not be read.',
      );
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception(
        'Check your internet connection and try again.',
      );
    }
  }

  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final response = await getRates(fromCurrency);
    final targetRate = response.rates[toCurrency];

    if (targetRate == null) {
      throw Exception(
        '$toCurrency is currently unavailable.',
      );
    }

    return amount * targetRate;
  }

  Future<List<HistoricalRatePoint>> getHistoricalRates({
    required String fromCurrency,
    required String toCurrency,
    int days = 7,
  }) async {
    final from = fromCurrency.toLowerCase();
    final to = toCurrency.toLowerCase();

    final today = DateTime.now();
    final points = <HistoricalRatePoint>[];

    for (int daysAgo = days; daysAgo >= 1; daysAgo--) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: daysAgo));

      try {
        final rate = await _getHistoricalRate(
          date: date,
          fromCurrency: from,
          toCurrency: to,
        );

        points.add(
          HistoricalRatePoint(
            date: date,
            rate: rate,
          ),
        );
      } catch (_) {
        // Skip a date only when the provider
        // has no record for that day.
      }
    }

    if (points.length < 2) {
      throw Exception(
        'Not enough historical rates were received.',
      );
    }

    return points;
  }

  Future<double> _getHistoricalRate({
    required DateTime date,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final dateText = _formatApiDate(date);

    final primaryUri = Uri.parse(
      '$_historicalCdnUrl@$dateText/v1/'
      'currencies/$fromCurrency.json',
    );

    final fallbackUri = Uri.parse(
      'https://$dateText.currency-api.pages.dev/'
      'v1/currencies/$fromCurrency.json',
    );

    http.Response response;

    try {
      response = await http
          .get(primaryUri)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        response = await http
            .get(fallbackUri)
            .timeout(const Duration(seconds: 12));
      }
    } catch (_) {
      response = await http
          .get(fallbackUri)
          .timeout(const Duration(seconds: 12));
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Historical rate unavailable for $dateText.',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Invalid historical-rate response.',
      );
    }

    final currencyRates = data[fromCurrency];

    if (currencyRates is! Map<String, dynamic>) {
      throw Exception(
        'Historical base currency unavailable.',
      );
    }

    final value = currencyRates[toCurrency];

    if (value is! num) {
      throw Exception(
        'Historical target currency unavailable.',
      );
    }

    return value.toDouble();
  }

  static String _formatApiDate(DateTime date) {
    final year = date.year.toString();
    final month =
        date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

class CurrencyRateResponse {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime lastUpdated;

  const CurrencyRateResponse({
    required this.baseCurrency,
    required this.rates,
    required this.lastUpdated,
  });
}

class HistoricalRatePoint {
  final DateTime date;
  final double rate;

  const HistoricalRatePoint({
    required this.date,
    required this.rate,
  });
}