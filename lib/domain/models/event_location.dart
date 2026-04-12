class EventLocation {
  final String name;
  final double latitude;
  final double longitude;

  EventLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'latitude': latitude, 'longitude': longitude};
  }
}
