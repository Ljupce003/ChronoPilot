import 'dart:async';

import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';
import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/event_overrides_repository.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:chrono_pilot/service/event_override_service.dart';
import 'package:chrono_pilot/service/event_service.dart';
import 'package:chrono_pilot/service/event_timeline_service.dart';
import 'package:flutter/foundation.dart';

class EventProvider extends ChangeNotifier {
  final EventsRepository repository;
  final EventOverridesRepository overridesRepository;

  late final EventService eventService;
  late final EventOverrideService overrideService;
  late final EventTimelineService timelineService;
  bool _initialized = false;

  EventProvider({required this.repository, required this.overridesRepository}) {
    eventService = EventService(repository);
    overrideService = EventOverrideService(overridesRepository);
    timelineService = EventTimelineService(
      eventsRepository: repository,
      overrideService: overrideService,
    );

    unawaited(_initialize());
  }

  List<EventViewModel> _events = [];
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  List<EventViewModel> get events => List.unmodifiable(_events);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _seedIfNeeded();
    await loadEvents();
  }

  Future<void> _seedIfNeeded() async {
    final existing = await repository.getAllEvents();
    if (existing.isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    await eventService.createEvent(
      CreateEventRequest(
        userId: 'seed-user',
        title: 'Seed Single Event',
        scheduleType: EventScheduleType.oneTime,
        contentType: EventContentType.ordinary,
        start: now.subtract(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 1)),
      ),
    );

    await eventService.createEvent(
      CreateEventRequest(
        userId: 'seed-user',
        title: 'Seed Education Event',
        scheduleType: EventScheduleType.oneTime,
        contentType: EventContentType.education,
        start: now.add(const Duration(hours: 2)),
        end: now.add(const Duration(hours: 3)),
        educationDetails: EducationDetails(
          courseName: 'Course 1',
          professor: 'Professor 1',
          room: 'Room 1',
          studyProgramCode: 'SP1',
        ),
      ),
    );

    await eventService.createEvent(
      CreateEventRequest(
        userId: 'seed-user',
        title: 'Seed Todo Event',
        scheduleType: EventScheduleType.oneTime,
        contentType: EventContentType.todo,
        deadline: now.add(const Duration(hours: 4)),
      ),
    );

    // Test overlapping events
    await eventService.createEvent(
      CreateEventRequest(
        userId: 'seed-user',
        title: 'Overlapping Event 1',
        scheduleType: EventScheduleType.oneTime,
        contentType: EventContentType.ordinary,
        start: now.add(const Duration(minutes: 30)),
        end: now.add(const Duration(hours: 1, minutes: 30)),
      ),
    );

    // Test same-time event (starts at same time as Seed Single Event)
    await eventService.createEvent(
      CreateEventRequest(
        userId: 'seed-user',
        title: 'Same-Time Event',
        scheduleType: EventScheduleType.oneTime,
        contentType: EventContentType.ordinary,
        start: now.subtract(const Duration(hours: 1)),
        end: now.add(const Duration(minutes: 30)),
      ),
    );

    // Test partial overlap
    await eventService.createEvent(
      CreateEventRequest(
        userId: 'seed-user',
        title: 'Partial Overlap Event',
        scheduleType: EventScheduleType.oneTime,
        contentType: EventContentType.todo,
        start: now.add(const Duration(minutes: 15)),
        end: now.add(const Duration(hours: 2)),
      ),
    );
  }

  Future<void> loadEvents({DateTime? rangeStart, DateTime? rangeEnd}) async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final resolvedStart = rangeStart ?? DateTime(now.year, now.month, 1);
    final resolvedEnd = rangeEnd ?? DateTime(now.year, now.month + 1, 1);

    _rangeStart = resolvedStart;
    _rangeEnd = resolvedEnd;

    _events = await timelineService.buildViewModelsForRange(
      rangeStart: resolvedStart,
      rangeEnd: resolvedEnd,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createEvent(CreateEventRequest request) async {
    await eventService.createEvent(request);
    await _reloadCurrentRange();
  }

  Future<void> updateEvent(String id, CreateEventRequest request) async {
    await eventService.updateEvent(id, request);
    await _reloadCurrentRange();
  }

  Future<void> deleteEvent(String id) async {
    await eventService.deleteEvent(id);
    await _reloadCurrentRange();
  }

  Future<void> cancelRecurringOccurrence({
    required String userId,
    required String recurringEventId,
    required DateTime originalDateTime,
    String? note,
  }) async {
    await overrideService.createCancelledOverride(
      userId: userId,
      recurringEventId: recurringEventId,
      originalDateTime: originalDateTime,
      note: note,
    );

    await _reloadCurrentRange();
  }

  Future<void> modifyRecurringOccurrence({
    required String userId,
    required String recurringEventId,
    required DateTime originalDateTime,
    required CreateEventRequest replacementEventRequest,
    String? note,
  }) async {
    if (replacementEventRequest.scheduleType == EventScheduleType.recurring) {
      throw ArgumentError('Replacement event cannot be recurring.');
    }

    final replacementEvent = await eventService.createEvent(replacementEventRequest);

    await overrideService.createModifiedOverride(
      userId: userId,
      recurringEventId: recurringEventId,
      originalDateTime: originalDateTime,
      replacementEventId: replacementEvent.id,
      newStartDateTime: replacementEvent.startDateTime,
      newEndDateTime: replacementEvent.endDateTime,
      note: note,
    );

    await _reloadCurrentRange();
  }

  Future<void> removeRecurringOverride(String overrideId, {String? note}) async {
    final existing = await overrideService.getOverrideById(overrideId);

    if (existing.replacementEventId != null) {
      await eventService.deleteEvent(existing.replacementEventId!);
    }

    await overrideService.markOverrideAsCancelled(overrideId, note: note);
    await _reloadCurrentRange();
  }

  List<EventViewModel> getEventsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _events.where((e) {
      return e.endDateTime.isAfter(dayStart) && e.startDateTime.isBefore(dayEnd);
    }).toList();
  }

  List<EventViewModel> getEventsForWeek(DateTime startOfWeek, DateTime endOfWeek) {
    return _events.where((e) {
      return e.endDateTime.isAfter(startOfWeek) && e.startDateTime.isBefore(endOfWeek);
    }).toList();
  }

  List<EventViewModel> getEventsForMonth(int year, int month) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    return _events.where((e) {
      return e.endDateTime.isAfter(monthStart) && e.startDateTime.isBefore(monthEnd);
    }).toList();
  }

  Future<void> _reloadCurrentRange() async {
    await loadEvents(
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
    );
  }
}
