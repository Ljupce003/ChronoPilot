import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';

class CreateEventRequest {
  final String userId;
  final String title;
  final String? description;

  final DateTime? start;
  final DateTime? end;

  final EventScheduleType scheduleType;
  final EventContentType contentType;

  // optional inputs
  final DateTime? deadline;
  final EducationDetails? educationDetails;
  final EducationSubtype? educationSubtype;
  final RecurringRule? recurringRule;
  final EventLocation? location;

  CreateEventRequest({
    required this.userId,
    required this.title,
    this.scheduleType = EventScheduleType.oneTime,
    this.contentType = EventContentType.ordinary,
    this.description,
    this.start,
    this.end,
    this.deadline,
    this.educationDetails,
    this.educationSubtype,
    this.recurringRule,
    this.location,
  });
}