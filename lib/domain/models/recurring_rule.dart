/// Recurrence definition for a repeating event.
///
/// Stores the selected weekdays, starting date, optional end date, and time
/// bounds used by the timeline expansion service.
class RecurringRule {
  final List<int> daysOfWeek; // 1=Mon ... 7=Sun

  final DateTime startDate;
  final DateTime? endDate;

  final String startTime; // "HH:mm"
  final String? endTime;

  /// Creates a recurrence rule.
  RecurringRule({
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    required this.startTime,
    this.endTime,
  });

  /// Creates a recurrence rule from a decoded JSON map.
  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    return RecurringRule(
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      startDate: DateTime.parse(json['startDate']),
      endDate:
      json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  /// Serializes the recurrence rule to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'daysOfWeek': daysOfWeek,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}