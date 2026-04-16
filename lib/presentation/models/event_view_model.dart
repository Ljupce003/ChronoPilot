
import 'package:chrono_pilot/domain/enums/event_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_type.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';

class EventViewModel {

  final String id;
  final String userId;

  final String title;
  final String? description;

  final DateTime startDateTime;
  final DateTime endDateTime;

  final EventType type;

  final EventLocation? location;
  final String? imagePath;

  // TO-DO / Task fields
  final bool? isCompleted;
  final DateTime? deadline;

  // Lecture fields
  final EducationDetails? educationDetails;
  final EventSubtype? subtype;

  // If event was created from override
  final String? overrideId;

  final String? recurringEventId;

  EventViewModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.type,

    this.description,

    this.location,
    this.imagePath,

    this.isCompleted,
    this.deadline,
    this.educationDetails,
    this.subtype,

    this.overrideId,
    this.recurringEventId
  });
}