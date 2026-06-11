class AvailableCountryModel {
  final String countryCode;
  final String name;

  const AvailableCountryModel({
    required this.countryCode,
    required this.name,
  });

  factory AvailableCountryModel.fromJson(Map<String, dynamic> json) {
    return AvailableCountryModel(
      countryCode: (json['countryCode'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  String get displayLabel => name.isEmpty ? countryCode : '$name ($countryCode)';
}

class PublicHolidayModel {
  final DateTime date;
  final String localName;
  final String name;
  final String countryCode;
  final bool global;
  final List<String> counties;
  final int? launchYear;
  final List<String> types;

  const PublicHolidayModel({
    required this.date,
    required this.localName,
    required this.name,
    required this.countryCode,
    required this.global,
    required this.counties,
    required this.launchYear,
    required this.types,
  });

  factory PublicHolidayModel.fromJson(Map<String, dynamic> json) {
    return PublicHolidayModel(
      date: DateTime.parse((json['date'] ?? '').toString()),
      localName: (json['localName'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      countryCode: (json['countryCode'] ?? '').toString(),
      global: json['global'] == true,
      counties: (json['counties'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      launchYear: json['launchYear'] == null ? null : int.tryParse(json['launchYear'].toString()),
      types: (json['types'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

