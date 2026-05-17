
import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';

class EditEventRequest {
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

  // If editing an occurrence, we need to know WHICH one it was originally
  final DateTime? originalOccurrenceDate;
  final bool updateWholeSeries;

  EditEventRequest({
    required this.title,
    this.description,
    required this.start,
    required this.end,
    required this.userId,
    required this.scheduleType,
    required this.contentType,
    this.deadline,
    this.educationDetails,
    this.educationSubtype,
    this.recurringRule,
    this.location,
    this.originalOccurrenceDate,
    this.updateWholeSeries = false,
  });

  CreateEventRequest toCreateReq(){
    return CreateEventRequest(
        userId: userId,
        title: title,
        description: description,
        start: start,
        end: end,
        scheduleType: scheduleType,
        contentType: contentType,
        deadline: deadline,
        educationDetails: educationDetails,
        educationSubtype: educationSubtype,
        recurringRule: recurringRule,
        location: location,
    );

  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'title': title,
  //     'description': description,
  //     'startDateTime': start.toIso8601String(),
  //     'endDateTime': end.toIso8601String(),
  //     'originalOccurrenceDate': originalOccurrenceDate?.toIso8601String(),
  //     'updateWholeSeries': updateWholeSeries,
  //   };
  // }
}
