import 'package:chrono_pilot/domain/enums/education_subtype.dart';
import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/event_location.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/utils/event_classification.dart';

/// Presentation-ready event model used by the calendar and detail screens.
///
/// This model is produced by the timeline service after recurring expansion and
/// override resolution, so the UI can render a concrete event occurrence.
class EventViewModel {
  final String id;
  final String userId;

  final String title;
  final String? description;

  final DateTime startDateTime;
  final DateTime endDateTime;

  final EventScheduleType scheduleType;
  final EventContentType contentType;

  final EventLocation? location;
  final String? imagePath;

  // TO-DO / Task fields
  final bool? isCompleted;
  final DateTime? deadline;

  // Education fields
  final EducationDetails? educationDetails;
  final EducationSubtype? educationSubtype;

  // If event was created from override
  final String? overrideId;

  final String? recurringEventId;

  /// Creates a view model for a visible event occurrence.
  EventViewModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.scheduleType,
    required this.contentType,
    this.description,
    this.location,
    this.imagePath,
    this.isCompleted,
    this.deadline,
    this.educationDetails,
    this.educationSubtype,
    this.overrideId,
    this.recurringEventId,
  });

  /// Human-readable label combining the schedule and content type.
  String get scheduleAndContentText =>
      scheduleAndContentLabel(
        scheduleType: scheduleType,
        contentType: contentType,
      );
}