import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:uuid/uuid.dart';

class EventService {
  final EventsRepository repository;
  final _uuid = const Uuid();

  EventService(this.repository);

  Future<EventModel> createEvent(CreateEventRequest request) async {
    final id = _uuid.v4();

    final event = _mapToEventModel(id, request);

    await repository.addEvent(event);
    return event;
  }

  Future<void> updateEvent(String id, CreateEventRequest request) async {
    final existing = await repository.getEventById(id);

    final updatedEvent = _merge(existing, request);

    await repository.updateEvent(updatedEvent);
  }

  Future<void> deleteEvent(String id) async {
    await repository.deleteEvent(id);
  }

  EventModel _mapToEventModel(String id, CreateEventRequest request) {
    return EventModel(
      id: id,
      userId: request.userId,
      title: request.title,
      description: request.description,
      startDateTime: request.start,
      endDateTime: request.end,
      location: request.location,
      scheduleType: request.scheduleType,
      contentType: request.contentType,
      isCompleted: false,
      deadline: request.deadline,
      educationDetails: request.educationDetails,
      educationSubtype: request.educationSubtype,
      recurringRule: request.recurringRule,
    );
  }

  EventModel _merge(EventModel oldEvent, CreateEventRequest request) {
    return EventModel(
      id: oldEvent.id,
      userId: oldEvent.userId,
      title: request.title,
      description: request.description ?? oldEvent.description,
      startDateTime: request.start ?? oldEvent.startDateTime,
      endDateTime: request.end ?? oldEvent.endDateTime,
      location: request.location ?? oldEvent.location,
      imagePath: oldEvent.imagePath,
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