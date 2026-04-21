import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../services/exchange_rate_service.dart';

/// State management for the Tools screens: Currency Converter & Timezone.
///
/// Manages currency conversion state, recent conversion history,
/// and timezone list for the World Clock feature.
class ToolsProvider extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════════════
  // CURRENCY CONVERTER STATE
  // ═══════════════════════════════════════════════════════════════════════════

  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  double _amount = 1000.0;
  double _convertedAmount = 0.0;
  double _rate = 0.0;
  String _lastUpdated = '';
  bool _isConverting = false;
  String? _conversionError;

  String get fromCurrency => _fromCurrency;
  String get toCurrency => _toCurrency;
  double get amount => _amount;
  double get convertedAmount => _convertedAmount;
  double get rate => _rate;
  String get lastUpdated => _lastUpdated;
  bool get isConverting => _isConverting;
  String? get conversionError => _conversionError;

  /// List of recent conversions for history display.
  final List<ConversionRecord> _recentConversions = [];
  List<ConversionRecord> get recentConversions =>
      List.unmodifiable(_recentConversions);

  /// Supported currencies with flag emojis and names.
  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo('USD', '🇺🇸', 'United States Dollar'),
    CurrencyInfo('IDR', '🇮🇩', 'Indonesian Rupiah'),
    CurrencyInfo('EUR', '🇪🇺', 'Euro'),
    CurrencyInfo('GBP', '🇬🇧', 'British Pound'),
    CurrencyInfo('JPY', '🇯🇵', 'Japanese Yen'),
    CurrencyInfo('SGD', '🇸🇬', 'Singapore Dollar'),
    CurrencyInfo('AUD', '🇦🇺', 'Australian Dollar'),
    CurrencyInfo('CAD', '🇨🇦', 'Canadian Dollar'),
    CurrencyInfo('CHF', '🇨🇭', 'Swiss Franc'),
    CurrencyInfo('CNY', '🇨🇳', 'Chinese Yuan'),
    CurrencyInfo('KRW', '🇰🇷', 'South Korean Won'),
    CurrencyInfo('MYR', '🇲🇾', 'Malaysian Ringgit'),
    CurrencyInfo('THB', '🇹🇭', 'Thai Baht'),
    CurrencyInfo('INR', '🇮🇳', 'Indian Rupee'),
    CurrencyInfo('SAR', '🇸🇦', 'Saudi Riyal'),
    CurrencyInfo('AED', '🇦🇪', 'UAE Dirham'),
  ];

  /// Popular conversion pairs for quick access chips.
  static const List<List<String>> popularPairs = [
    ['USD', 'IDR'],
    ['EUR', 'IDR'],
    ['GBP', 'USD'],
    ['JPY', 'IDR'],
  ];

  /// Gets the [CurrencyInfo] for a given currency code.
  static CurrencyInfo getCurrencyInfo(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => CurrencyInfo(code, '🏳️', code),
    );
  }

  /// Sets the amount to convert.
  void setAmount(double value) {
    _amount = value;
    notifyListeners();
  }

  /// Sets the "from" currency.
  void setFromCurrency(String code) {
    _fromCurrency = code;
    notifyListeners();
  }

  /// Sets the "to" currency.
  void setToCurrency(String code) {
    _toCurrency = code;
    notifyListeners();
  }

  /// Swap from/to currencies and re-convert.
  Future<void> swapCurrencies() async {
    final temp = _fromCurrency;
    _fromCurrency = _toCurrency;
    _toCurrency = temp;
    notifyListeners();
    await convert();
  }

  /// Select a popular pair and convert.
  Future<void> selectPair(String from, String to) async {
    _fromCurrency = from;
    _toCurrency = to;
    notifyListeners();
    await convert();
  }

  /// Perform the currency conversion.
  Future<void> convert() async {
    _isConverting = true;
    _conversionError = null;
    notifyListeners();

    try {
      final result = await ExchangeRateService.instance
          .fetchRate(_fromCurrency, _toCurrency);

      _rate = (result['rate'] as num? ?? 0).toDouble();
      _convertedAmount = _amount * _rate;
      _lastUpdated = _formatLastUpdated(result['lastUpdated'] as String? ?? '');

      // Add to recent conversions
      if (_rate > 0) {
        _addRecentConversion();
      }

      _conversionError = null;
    } catch (e) {
      _conversionError = 'Failed to fetch exchange rate';
      debugPrint('[ToolsProvider] Conversion error: $e');
    } finally {
      _isConverting = false;
      notifyListeners();
    }
  }

  /// Clear all recent conversions.
  void clearRecentConversions() {
    _recentConversions.clear();
    notifyListeners();
  }

  void _addRecentConversion() {
    final record = ConversionRecord(
      from: _fromCurrency,
      to: _toCurrency,
      fromAmount: _amount,
      toAmount: _convertedAmount,
      timestamp: DateTime.now(),
    );

    // Remove duplicate if exists
    _recentConversions.removeWhere(
        (r) => r.from == record.from && r.to == record.to);

    // Add to front
    _recentConversions.insert(0, record);

    // Keep only last 10
    if (_recentConversions.length > 10) {
      _recentConversions.removeRange(10, _recentConversions.length);
    }
  }

  String _formatLastUpdated(String raw) {
    if (raw.isEmpty || raw == 'N/A') return 'N/A';
    try {
      // Parse UTC time string like "Mon, 14 Apr 2025 00:00:01 +0000"
      final parsed = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').parse(raw);
      final diff = DateTime.now().difference(parsed);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (_) {
      return raw;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMEZONE / WORLD CLOCK STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary timezone (reference timezone for offset calc).
  String _primaryTimezoneId = 'Asia/Jakarta';
  String get primaryTimezoneId => _primaryTimezoneId;

  /// List of all timezone entries to display in the World Clock.
  final List<TimezoneEntry> _timezones = [
    TimezoneEntry(
      city: 'Jakarta',
      timezoneId: 'Asia/Jakarta',
      abbreviation: 'WIB',
      utcOffsetHours: 7,
    ),
    TimezoneEntry(
      city: 'Makassar',
      timezoneId: 'Asia/Makassar',
      abbreviation: 'WITA',
      utcOffsetHours: 8,
    ),
    TimezoneEntry(
      city: 'Jayapura',
      timezoneId: 'Asia/Jayapura',
      abbreviation: 'WIT',
      utcOffsetHours: 9,
    ),
    TimezoneEntry(
      city: 'Tokyo',
      timezoneId: 'Asia/Tokyo',
      abbreviation: 'JST',
      utcOffsetHours: 9,
    ),
    TimezoneEntry(
      city: 'London',
      timezoneId: 'Europe/London',
      abbreviation: 'BST',
      utcOffsetHours: 1,
    ),
    TimezoneEntry(
      city: 'New York',
      timezoneId: 'America/New_York',
      abbreviation: 'EDT',
      utcOffsetHours: -4,
    ),
  ];

  List<TimezoneEntry> get timezones => List.unmodifiable(_timezones);

  /// Gets the current time in a given timezone by UTC offset.
  DateTime getTimeInTimezone(int utcOffsetHours) {
    final now = DateTime.now().toUtc();
    return now.add(Duration(hours: utcOffsetHours));
  }

  /// Gets the time offset (in hours) relative to primary timezone.
  int getOffsetFromPrimary(TimezoneEntry entry) {
    final primary = _timezones.firstWhere(
      (t) => t.timezoneId == _primaryTimezoneId,
      orElse: () => _timezones.first,
    );
    return entry.utcOffsetHours - primary.utcOffsetHours;
  }

  /// Gets the day label ("TODAY", "YESTERDAY", "TOMORROW") relative to primary TZ.
  String getDayLabel(TimezoneEntry entry) {
    final primary = _timezones.firstWhere(
      (t) => t.timezoneId == _primaryTimezoneId,
      orElse: () => _timezones.first,
    );
    final primaryTime = getTimeInTimezone(primary.utcOffsetHours);
    final entryTime = getTimeInTimezone(entry.utcOffsetHours);

    if (entryTime.day == primaryTime.day) return 'TODAY';
    if (entryTime.day == primaryTime.day - 1) return 'YESTERDAY';
    if (entryTime.day == primaryTime.day + 1) return 'TOMORROW';
    return 'TODAY';
  }

  /// Set primary timezone.
  void setPrimaryTimezone(String timezoneId) {
    _primaryTimezoneId = timezoneId;
    notifyListeners();
  }

  /// Available timezones for the "Add Timezone" dialog.
  static const List<TimezoneEntry> availableTimezones = [
    // Asia
    TimezoneEntry(city: 'Jakarta', timezoneId: 'Asia/Jakarta', abbreviation: 'WIB', utcOffsetHours: 7),
    TimezoneEntry(city: 'Makassar', timezoneId: 'Asia/Makassar', abbreviation: 'WITA', utcOffsetHours: 8),
    TimezoneEntry(city: 'Jayapura', timezoneId: 'Asia/Jayapura', abbreviation: 'WIT', utcOffsetHours: 9),
    TimezoneEntry(city: 'Tokyo', timezoneId: 'Asia/Tokyo', abbreviation: 'JST', utcOffsetHours: 9),
    TimezoneEntry(city: 'Seoul', timezoneId: 'Asia/Seoul', abbreviation: 'KST', utcOffsetHours: 9),
    TimezoneEntry(city: 'Beijing', timezoneId: 'Asia/Shanghai', abbreviation: 'CST', utcOffsetHours: 8),
    TimezoneEntry(city: 'Hong Kong', timezoneId: 'Asia/Hong_Kong', abbreviation: 'HKT', utcOffsetHours: 8),
    TimezoneEntry(city: 'Taipei', timezoneId: 'Asia/Taipei', abbreviation: 'CST', utcOffsetHours: 8),
    TimezoneEntry(city: 'Kuala Lumpur', timezoneId: 'Asia/Kuala_Lumpur', abbreviation: 'MYT', utcOffsetHours: 8),
    TimezoneEntry(city: 'Singapore', timezoneId: 'Asia/Singapore', abbreviation: 'SGT', utcOffsetHours: 8),
    TimezoneEntry(city: 'Bangkok', timezoneId: 'Asia/Bangkok', abbreviation: 'ICT', utcOffsetHours: 7),
    TimezoneEntry(city: 'Dubai', timezoneId: 'Asia/Dubai', abbreviation: 'GST', utcOffsetHours: 4),
    TimezoneEntry(city: 'Riyadh', timezoneId: 'Asia/Riyadh', abbreviation: 'AST', utcOffsetHours: 3),
    TimezoneEntry(city: 'Tehran', timezoneId: 'Asia/Tehran', abbreviation: 'IRST', utcOffsetHours: 3 /* .5 ignored for simplicity or using 3/4 */),
    TimezoneEntry(city: 'Manila', timezoneId: 'Asia/Manila', abbreviation: 'PHT', utcOffsetHours: 8),
    TimezoneEntry(city: 'Ho Chi Minh', timezoneId: 'Asia/Ho_Chi_Minh', abbreviation: 'ICT', utcOffsetHours: 7),
    
    // Europe
    TimezoneEntry(city: 'London', timezoneId: 'Europe/London', abbreviation: 'GMT/BST', utcOffsetHours: 1),
    TimezoneEntry(city: 'Paris', timezoneId: 'Europe/Paris', abbreviation: 'CET', utcOffsetHours: 2),
    TimezoneEntry(city: 'Berlin', timezoneId: 'Europe/Berlin', abbreviation: 'CET', utcOffsetHours: 2),
    TimezoneEntry(city: 'Rome', timezoneId: 'Europe/Rome', abbreviation: 'CET', utcOffsetHours: 2),
    TimezoneEntry(city: 'Madrid', timezoneId: 'Europe/Madrid', abbreviation: 'CET', utcOffsetHours: 2),
    TimezoneEntry(city: 'Amsterdam', timezoneId: 'Europe/Amsterdam', abbreviation: 'CET', utcOffsetHours: 2),
    TimezoneEntry(city: 'Athens', timezoneId: 'Europe/Athens', abbreviation: 'EET', utcOffsetHours: 3),
    TimezoneEntry(city: 'Moscow', timezoneId: 'Europe/Moscow', abbreviation: 'MSK', utcOffsetHours: 3),
    TimezoneEntry(city: 'Istanbul', timezoneId: 'Europe/Istanbul', abbreviation: 'TRT', utcOffsetHours: 3),
    TimezoneEntry(city: 'Stockholm', timezoneId: 'Europe/Stockholm', abbreviation: 'CET', utcOffsetHours: 2),

    // Americas
    TimezoneEntry(city: 'New York', timezoneId: 'America/New_York', abbreviation: 'EDT', utcOffsetHours: -4),
    TimezoneEntry(city: 'Chicago', timezoneId: 'America/Chicago', abbreviation: 'CDT', utcOffsetHours: -5),
    TimezoneEntry(city: 'Denver', timezoneId: 'America/Denver', abbreviation: 'MDT', utcOffsetHours: -6),
    TimezoneEntry(city: 'Los Angeles', timezoneId: 'America/Los_Angeles', abbreviation: 'PDT', utcOffsetHours: -7),
    TimezoneEntry(city: 'Vancouver', timezoneId: 'America/Vancouver', abbreviation: 'PDT', utcOffsetHours: -7),
    TimezoneEntry(city: 'Toronto', timezoneId: 'America/Toronto', abbreviation: 'EDT', utcOffsetHours: -4),
    TimezoneEntry(city: 'Montreal', timezoneId: 'America/Montreal', abbreviation: 'EDT', utcOffsetHours: -4),
    TimezoneEntry(city: 'Mexico City', timezoneId: 'America/Mexico_City', abbreviation: 'CDT', utcOffsetHours: -5),
    TimezoneEntry(city: 'Sao Paulo', timezoneId: 'America/Sao_Paulo', abbreviation: 'BRT', utcOffsetHours: -3),
    TimezoneEntry(city: 'Buenos Aires', timezoneId: 'America/Argentina/Buenos_Aires', abbreviation: 'ART', utcOffsetHours: -3),
    TimezoneEntry(city: 'Santiago', timezoneId: 'America/Santiago', abbreviation: 'CLT', utcOffsetHours: -4),
    TimezoneEntry(city: 'Bogota', timezoneId: 'America/Bogota', abbreviation: 'COT', utcOffsetHours: -5),
    TimezoneEntry(city: 'Lima', timezoneId: 'America/Lima', abbreviation: 'PET', utcOffsetHours: -5),

    // Australia & Pacific
    TimezoneEntry(city: 'Sydney', timezoneId: 'Australia/Sydney', abbreviation: 'AEST', utcOffsetHours: 10),
    TimezoneEntry(city: 'Melbourne', timezoneId: 'Australia/Melbourne', abbreviation: 'AEST', utcOffsetHours: 10),
    TimezoneEntry(city: 'Brisbane', timezoneId: 'Australia/Brisbane', abbreviation: 'AEST', utcOffsetHours: 10),
    TimezoneEntry(city: 'Perth', timezoneId: 'Australia/Perth', abbreviation: 'AWST', utcOffsetHours: 8),
    TimezoneEntry(city: 'Auckland', timezoneId: 'Pacific/Auckland', abbreviation: 'NZST', utcOffsetHours: 12),
    TimezoneEntry(city: 'Fiji', timezoneId: 'Pacific/Fiji', abbreviation: 'FJT', utcOffsetHours: 12),
    TimezoneEntry(city: 'Honolulu', timezoneId: 'Pacific/Honolulu', abbreviation: 'HST', utcOffsetHours: -10),

    // Africa
    TimezoneEntry(city: 'Cairo', timezoneId: 'Africa/Cairo', abbreviation: 'EET', utcOffsetHours: 2),
    TimezoneEntry(city: 'Johannesburg', timezoneId: 'Africa/Johannesburg', abbreviation: 'SAST', utcOffsetHours: 2),
    TimezoneEntry(city: 'Lagos', timezoneId: 'Africa/Lagos', abbreviation: 'WAT', utcOffsetHours: 1),
    TimezoneEntry(city: 'Nairobi', timezoneId: 'Africa/Nairobi', abbreviation: 'EAT', utcOffsetHours: 3),
    TimezoneEntry(city: 'Casablanca', timezoneId: 'Africa/Casablanca', abbreviation: 'WEST', utcOffsetHours: 1),
  ];

  /// Add a timezone to the world clock list.
  void addTimezone(TimezoneEntry entry) {
    if (!_timezones.any((t) => t.timezoneId == entry.timezoneId)) {
      _timezones.add(entry);
      notifyListeners();
    }
  }

  /// Remove a timezone from the world clock list.
  void removeTimezone(String timezoneId) {
    // Don't remove the primary timezone
    if (timezoneId == _primaryTimezoneId) return;
    _timezones.removeWhere((t) => t.timezoneId == timezoneId);
    notifyListeners();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════

/// Information about a supported currency.
class CurrencyInfo {
  final String code;
  final String flag;
  final String name;

  const CurrencyInfo(this.code, this.flag, this.name);
}

/// A record of a past currency conversion.
class ConversionRecord {
  final String from;
  final String to;
  final double fromAmount;
  final double toAmount;
  final DateTime timestamp;

  const ConversionRecord({
    required this.from,
    required this.to,
    required this.fromAmount,
    required this.toAmount,
    required this.timestamp,
  });

  /// Formatted time label for display.
  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      return DateFormat('HH:mm').format(timestamp);
    }
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM dd').format(timestamp);
  }
}

/// Represents a timezone entry for the World Clock.
class TimezoneEntry {
  final String city;
  final String timezoneId;
  final String abbreviation;
  final int utcOffsetHours;

  const TimezoneEntry({
    required this.city,
    required this.timezoneId,
    required this.abbreviation,
    required this.utcOffsetHours,
  });
}
