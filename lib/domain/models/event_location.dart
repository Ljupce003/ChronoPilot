/// Location metadata attached to an event.
class EventLocation {
  final String name;
  final double latitude;
  final double longitude;

  /// Creates a location payload.
  EventLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Creates a location payload from JSON.
  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  /// Serializes the location payload to JSON.
  Map<String, dynamic> toJson() {
    return {'name': name, 'latitude': latitude, 'longitude': longitude};
  }
}
