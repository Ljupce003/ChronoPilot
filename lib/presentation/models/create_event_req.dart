import 'package:chrono_pilot/domain/enums/event_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_type.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/lecture_details.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';

class CreateEventRequest {
  final String userId;
  final String title;
  final String? description;

  final DateTime? start;
  final DateTime? end;

  final EventType type;

  // optional inputs
  final DateTime? deadline;
  final LectureDetails? lectureDetails;
  final EventSubtype? subtype;
  final RecurringRule? recurringRule;
  final EventLocation? location;

  CreateEventRequest({
    required this.userId,
    required this.title,
    required this.type,
    this.description,
    this.start,
    this.end,
    this.deadline,
    this.lectureDetails,
    this.subtype,
    this.recurringRule,
    this.location,
  });
}