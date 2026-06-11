import 'dart:convert';

import 'package:chrono_pilot/domain/models/holiday_api_models.dart';
import 'package:http/http.dart' as http;

class HolidayApiService {
  static const String _baseUrl = 'https://date.nager.at/api/v3';

  Future<List<AvailableCountryModel>> getAvailableCountries() async {
    final response = await http.get(Uri.parse('$_baseUrl/AvailableCountries'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load available countries (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => AvailableCountryModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayLabel.compareTo(b.displayLabel));
  }

  Future<List<PublicHolidayModel>> getPublicHolidays({
    required int year,
    required String countryCode,
  }) async {
    final response = await http.get(Uri.parse('$_baseUrl/PublicHolidays/$year/$countryCode'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load holidays (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => PublicHolidayModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

