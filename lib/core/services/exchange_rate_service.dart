import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import 'local_cache_service.dart';

/// Service for fetching currency exchange rates from ExchangeRate-API.
///
/// Uses v6.exchangerate-api.com with the API key from [AppConstants].
/// Caches the latest rates in Hive via [LocalCacheService] for
/// offline fallback and reduced API calls.
class ExchangeRateService {
  ExchangeRateService._();
  static final ExchangeRateService instance = ExchangeRateService._();

  /// Fetch the exchange rate from [from] to [to] currency.
  ///
  /// Returns a map with keys: `rate`, `from`, `to`, `lastUpdated`.
  /// Falls back to cached data on network failure.
  Future<Map<String, dynamic>> fetchRate(String from, String to) async {
    try {
      final url = '${AppConstants.exchangeRateBaseUrl}/pair/$from/$to';
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: AppConstants.apiTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] == 'success') {
          final result = {
            'rate': (data['conversion_rate'] as num).toDouble(),
            'from': from,
            'to': to,
            'lastUpdated': data['time_last_update_utc'] ?? '',
          };

          // Cache the result
          await _cacheRate(from, to, result);
          return result;
        }
      }

      // Fallback to cache on non-success
      return await _getCachedRate(from, to);
    } catch (e) {
      debugPrint('[ExchangeRate] Error fetching rate: $e');
      // Network error → use cache
      return await _getCachedRate(from, to);
    }
  }

  /// Fetch all exchange rates for a [base] currency.
  ///
  /// Returns a map with keys: `rates` (Map<String, double>), `base`, `lastUpdated`.
  Future<Map<String, dynamic>> fetchAllRates(String base) async {
    try {
      final url = '${AppConstants.exchangeRateBaseUrl}/latest/$base';
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: AppConstants.apiTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] == 'success') {
          final Map<String, dynamic> rawRates = data['conversion_rates'] ?? {};
          final rates = rawRates.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );

          final result = {
            'rates': rates,
            'base': base,
            'lastUpdated': data['time_last_update_utc'] ?? '',
          };

          // Cache all rates
          await _cacheAllRates(base, result);
          return result;
        }
      }

      return await _getCachedAllRates(base);
    } catch (e) {
      debugPrint('[ExchangeRate] Error fetching all rates: $e');
      return await _getCachedAllRates(base);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHING — uses LocalCacheService's generic put/get with settingsBox
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _cacheRate(
      String from, String to, Map<String, dynamic> data) async {
    try {
      final cache = LocalCacheService.instance;
      await cache.put(
          LocalCacheService.settingsBox, 'rate_${from}_$to', data);
    } catch (_) {
      // Silently fail caching
    }
  }

  Future<Map<String, dynamic>> _getCachedRate(String from, String to) async {
    try {
      final cache = LocalCacheService.instance;
      final cached =
          cache.get(LocalCacheService.settingsBox, 'rate_${from}_$to');
      if (cached != null) {
        return cached;
      }
    } catch (_) {
      // Cache miss
    }
    return {'rate': 0.0, 'from': from, 'to': to, 'lastUpdated': 'N/A'};
  }

  Future<void> _cacheAllRates(
      String base, Map<String, dynamic> data) async {
    try {
      final cache = LocalCacheService.instance;
      // Store rates as JSON string since the map is too nested for direct storage
      await cache.put(LocalCacheService.settingsBox, 'allrates_$base', {
        'ratesJson': json.encode(data['rates']),
        'base': data['base'],
        'lastUpdated': data['lastUpdated'],
      });
    } catch (_) {
      // Silently fail caching
    }
  }

  Future<Map<String, dynamic>> _getCachedAllRates(String base) async {
    try {
      final cache = LocalCacheService.instance;
      final cached =
          cache.get(LocalCacheService.settingsBox, 'allrates_$base');
      if (cached != null && cached['ratesJson'] != null) {
        final rawRates =
            json.decode(cached['ratesJson'] as String) as Map<String, dynamic>;
        final rates = rawRates.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        return {
          'rates': rates,
          'base': cached['base'] ?? base,
          'lastUpdated': cached['lastUpdated'] ?? 'N/A',
        };
      }
    } catch (_) {
      // Cache miss
    }
    return {
      'rates': <String, double>{},
      'base': base,
      'lastUpdated': 'N/A',
    };
  }
}
