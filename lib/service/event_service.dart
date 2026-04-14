import 'package:chrono_pilot/domain/enums/event_type.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';

import 'package:uuid/uuid.dart';
import 'package:chrono_pilot/repository/events_repository.dart';

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

  EventModel _mapToEventModel(String id, CreateEventRequest r) {
    switch (r.type) {

    // --------------------
    // NORMAL EVENT
    // --------------------
      case EventType.single:
        return EventModel(
          id: id,
          userId: r.userId,
          title: r.title,
          description: r.description,
          startDateTime: r.start,
          endDateTime: r.end,
          location: r.location,
          type: EventType.single,
        );

    // --------------------
    // TODO / TASK
    // --------------------
      case EventType.todo:
        return EventModel(
          id: id,
          userId: r.userId,
          title: r.title,
          description: r.description,
          isCompleted: false,
          deadline: r.deadline,
          type: EventType.todo,
        );

    // --------------------
    // LECTURE
    // --------------------
      case EventType.lecture:
        return EventModel(
          id: id,
          userId: r.userId,
          title: r.title,
          startDateTime: r.start,
          endDateTime: r.end,
          lectureDetails: r.lectureDetails,
          subtype: r.subtype,
          location: r.location,
          type: EventType.lecture,
        );

    // --------------------
    // RECURRING
    // --------------------
      case EventType.recurring:
        return EventModel(
          id: id,
          userId: r.userId,
          title: r.title,
          startDateTime: r.start,
          endDateTime: r.end,
          recurringRule: r.recurringRule,
          location: r.location,
          type: EventType.recurring,
        );
    }
  }

  EventModel _merge(EventModel old, CreateEventRequest r) {
    return EventModel(
      id: old.id,
      userId: old.userId,

      title: r.title,
      description: r.description ?? old.description,

      startDateTime: r.start ?? old.startDateTime,
      endDateTime: r.end ?? old.endDateTime,

      location: r.location ?? old.location,
      imagePath: old.imagePath,

      type: r.type,

      isCompleted: old.isCompleted,
      deadline: r.deadline ?? old.deadline,

      lectureDetails: r.lectureDetails ?? old.lectureDetails,
      subtype: r.subtype ?? old.subtype,

      recurringRule: r.recurringRule ?? old.recurringRule,
    );
  }
}