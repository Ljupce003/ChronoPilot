class HolidayCountry {
  final String countryCode;
  final String name;

  const HolidayCountry({
    required this.countryCode,
    required this.name,
  });

  factory HolidayCountry.fromJson(Map<String, dynamic> json) {
    return HolidayCountry(
      countryCode: (json['countryCode'] ?? '').toString(),
      name: (json['name'] ?? json['commonName'] ?? json['countryName'] ?? '')
          .toString(),
    );
  }

  String get displayLabel {
    if (name.isEmpty) {
      return countryCode;
    }
    return '$name ($countryCode)';
  }
}

