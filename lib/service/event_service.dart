import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';
import 'package:chrono_pilot/presentation/models/edit_event_request.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:chrono_pilot/service/event_override_service.dart';
import 'package:uuid/uuid.dart';

/// Handles event creation, update, and deletion workflows.
///
/// This service converts form requests into stored `EventModel` rows and also
/// manages the special flow for modifying a single occurrence of a recurring
/// event by creating a replacement event plus an override record.
class EventService {
  final EventsRepository repository;
  final EventOverrideService eventOverrideService;
  final _uuid = const Uuid();

  /// Creates a service that writes to the given repository and override store.
  EventService(this.repository, this.eventOverrideService);

  /// Creates and persists a new event from a form request.
  Future<EventModel> createEvent(CreateEventRequest request) async {
    final id = _uuid.v4();

    final event = _mapToEventModel(id, request);

    await repository.addEvent(event);
    return event;
  }

  /// Updates an existing event or creates a replacement event for an occurrence.
  /// Updates an existing event or creates a replacement event for an occurrence.
  ///
  /// Returns the replacement event id when a modified override is created,
  /// otherwise returns null.
  Future<String?> updateEvent(String id, EditEventRequest request) async {
    final existing = await repository.getEventById(id);

    final updatedEvent = _merge(existing, request.toCreateReq());

    if(request.originalOccurrenceDate == null){
      await repository.updateEvent(updatedEvent);
      return null;
    }else{
      if(request.updateWholeSeries){
        await repository.updateEvent(updatedEvent);
        return null;
      }
      else{
        // Create a replacement single event for this occurrence. Ensure the
        // replacement is a one-time event (not recurring) and does not carry
        // over the recurring rule.
        final origCreate = request.toCreateReq();
        final replacementCreate = CreateEventRequest(
          userId: origCreate.userId,
          title: origCreate.title,
          description: origCreate.description,
          start: origCreate.start,
          end: origCreate.end,
          scheduleType: EventScheduleType.oneTime,
          contentType: origCreate.contentType,
          deadline: origCreate.deadline,
          educationDetails: origCreate.educationDetails,
          educationSubtype: origCreate.educationSubtype,
          recurringRule: null,
          location: origCreate.location,
          imagePath: origCreate.imagePath,
        );

        final replacementEvent = await createEvent(replacementCreate);

        // Create a modified override that points to the replacement event and
        // stores the replacement's start/end times so the timeline can use them.
        await eventOverrideService.createModifiedOverride(
          userId: request.userId,
          recurringEventId: id,
          originalDateTime: request.originalOccurrenceDate!,
          replacementEventId: replacementEvent.id,
          newStartDateTime: replacementEvent.startDateTime,
          newEndDateTime: replacementEvent.endDateTime,
        );
        return replacementEvent.id;
      }

    }
  }

  /// Deletes a stored event row by id.
  Future<void> deleteEvent(String id) async {
    await repository.deleteEvent(id);
  }

  /// Maps a create request into the stored event model shape.
  EventModel _mapToEventModel(String id, CreateEventRequest request) {
    return EventModel(
      id: id,
      userId: request.userId,
      title: request.title,
      description: request.description,
      startDateTime: request.start,
      endDateTime: request.end,
      location: request.location,
      imagePath: request.imagePath,
      scheduleType: request.scheduleType,
      contentType: request.contentType,
      isCompleted: false,
      deadline: request.deadline,
      educationDetails: request.educationDetails,
      educationSubtype: request.educationSubtype,
      recurringRule: request.recurringRule,
    );
  }

  /// Merges an existing stored event with an update request.
  EventModel _merge(EventModel oldEvent, CreateEventRequest request) {
    return EventModel(
      id: oldEvent.id,
      userId: oldEvent.userId,
      title: request.title,
      description: request.description ?? oldEvent.description,
      startDateTime: request.start ?? oldEvent.startDateTime,
      endDateTime: request.end ?? oldEvent.endDateTime,
      location: request.location ?? oldEvent.location,
      imagePath: request.imagePath ?? oldEvent.imagePath,
      scheduleType: request.scheduleType,
      contentType: request.contentType,
      isCompleted: oldEvent.isCompleted,
      deadline: request.deadline ?? oldEvent.deadline,
      educationDetails: request.educationDetails ?? oldEvent.educationDetails,
      educationSubtype: request.educationSubtype ?? oldEvent.educationSubtype,
      recurringRule: request.recurringRule ?? oldEvent.recurringRule,
    );
  }
}