import 'dart:async';

import 'package:chrono_pilot/domain/enums/event_content_type.dart';
import 'package:chrono_pilot/domain/enums/event_schedule_type.dart';
import 'package:chrono_pilot/domain/models/education_details.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/presentation/models/create_event_req.dart';
import 'package:chrono_pilot/presentation/models/edit_event_request.dart';
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
  String? _currentUserId;
  bool _showAllUsers = false;

  EventProvider({required this.repository, required this.overridesRepository}) {
    overrideService = EventOverrideService(overridesRepository);
    eventService = EventService(repository,overrideService);
    timelineService = EventTimelineService(
      eventsRepository: repository,
      overrideService: overrideService,
    );

    unawaited(_initialize());
  }

  void setCurrentUserId(String? userId, {bool showAllUsers = false}) {
    _currentUserId = userId;
    _showAllUsers = showAllUsers;
    if (userId != null) {
      unawaited(_initialize());
    }
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
    // Don't seed if not logged in
    if (_currentUserId == null) {
      return;
    }

    final now = DateTime.now();
    final userId = _currentUserId!;

    await eventService.createEvent(
      CreateEventRequest(
        userId: userId,
        title: 'Seed Single Event',
        scheduleType: EventScheduleType.oneTime,
        contentType: EventContentType.ordinary,
        start: now.subtract(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 1)),
      ),
    );

    await eventService.createEvent(
      CreateEventRequest(
        userId: userId,
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
        userId: userId,
        title: 'Seed Todo Event',
        scheduleType: EventScheduleType.oneTime,
        contentType: EventContentType.todo,
        deadline: now.add(const Duration(hours: 4)),
      ),
    );

    // Test overlapping events
    await eventService.createEvent(
      CreateEventRequest(
        userId: userId,
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
        userId: userId,
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
        userId: userId,
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

    try {
      _events = await timelineService.buildViewModelsForRange(
        rangeStart: resolvedStart,
        rangeEnd: resolvedEnd,
      );
    } catch (e, st) {
      // Log error and ensure we don't stay in loading state. Swallow to allow UI
      // to continue and show empty list instead of frozen loader.
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error building timeline view models: $e\n$st');
      }
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent(CreateEventRequest request) async {
    await eventService.createEvent(request);
    await _reloadCurrentRange();
  }

  Future<void> updateEvent(String id, EditEventRequest request) async {
    await eventService.updateEvent(id, request);
    await _reloadCurrentRange();
  }

  Future<void> deleteEvent(String id) async {
    // If deleting a recurring event, first remove any overrides and their
    // replacement events to avoid leaving orphan overrides behind.
    try {
      final event = await repository.getEventById(id);
      if (event.scheduleType == EventScheduleType.recurring) {
        final overrides = await overridesRepository.getOverridesForRecurringEvent(id);
        for (final o in overrides) {
          if (o.replacementEventId != null) {
            await eventService.deleteEvent(o.replacementEventId!);
          }
          await overridesRepository.deleteOverride(o.id);
        }
      } else {
        // If deleting a one-time replacement event that came from a modified
        // override, also delete the override row so the original recurring
        // occurrence becomes visible again.
        final replacementRefs = await overridesRepository
            .getOverridesByReplacementEventId(id);
        for (final o in replacementRefs) {
          await overridesRepository.deleteOverride(o.id);
        }
      }
    } catch (e) {
      // If we can't fetch event or overrides, continue with deletion to avoid
      // leaving UI in an inconsistent state. Log in debug.
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error while cleaning overrides before deleting event $id: $e');
      }
    }

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
    // When the user chooses to remove an override, we should delete the
    // override row entirely and also delete any replacement event that was
    // created for that override. (Use `cancelRecurringOccurrence` to create a
    // cancelled override instead.)
    final existing = await overrideService.getOverrideById(overrideId);

    if (existing.replacementEventId != null) {
      await eventService.deleteEvent(existing.replacementEventId!);
    }

    await overridesRepository.deleteOverride(overrideId);
    await _reloadCurrentRange();
  }

  EventViewModel? getEventViewModelById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<EventModel> getRawEvent(String eventId) async {
    return await repository.getEventById(eventId);
  }

  Future<List<EventModel>> getAllStoredEvents() async {
    return await repository.getAllEvents();
  }

  Future<EventViewModel?> getEventViewModelByIdFromStorage(String eventId) async {
    final cached = getEventViewModelById(eventId);
    if (cached != null) {
      return cached;
    }

    try {
      final event = await repository.getEventById(eventId);
      return _mapStoredEventToViewModel(event);
    } catch (_) {
      return null;
    }
  }

  EventViewModel? _mapStoredEventToViewModel(EventModel event) {
    if (event.scheduleType == EventScheduleType.recurring &&
        event.recurringRule != null) {
      final startTime = _parseHourMinute(event.recurringRule!.startTime);
      final start = DateTime(
        event.recurringRule!.startDate.year,
        event.recurringRule!.startDate.month,
        event.recurringRule!.startDate.day,
        startTime.$1,
        startTime.$2,
      );

      final end = _resolveStoredRecurringEnd(event, start);

      return EventViewModel(
        id: event.id,
        userId: event.userId,
        title: event.title,
        description: event.description,
        startDateTime: start,
        endDateTime: end,
        scheduleType: event.scheduleType,
        contentType: event.contentType,
        location: event.location,
        imagePath: event.imagePath,
        isCompleted: event.isCompleted,
        deadline: event.deadline,
        educationDetails: event.educationDetails,
        educationSubtype: event.educationSubtype,
      );
    }

    switch (event.contentType) {
      case EventContentType.ordinary:
      case EventContentType.education:
      case EventContentType.holiday:
        if (event.startDateTime == null || event.endDateTime == null) {
          return null;
        }

        return EventViewModel(
          id: event.id,
          userId: event.userId,
          title: event.title,
          description: event.description,
          startDateTime: event.startDateTime!,
          endDateTime: event.endDateTime!,
          scheduleType: event.scheduleType,
          contentType: event.contentType,
          location: event.location,
          imagePath: event.imagePath,
          isCompleted: event.contentType == EventContentType.todo
              ? event.isCompleted
              : null,
          deadline: event.deadline,
          educationDetails: event.educationDetails,
          educationSubtype: event.educationSubtype,
        );
      case EventContentType.todo:
        if (event.deadline == null) {
          return null;
        }

        final start = event.deadline!;
        final end = start.add(const Duration(minutes: 30));

        return EventViewModel(
          id: event.id,
          userId: event.userId,
          title: event.title,
          description: event.description,
          startDateTime: start,
          endDateTime: end,
          scheduleType: event.scheduleType,
          contentType: event.contentType,
          location: event.location,
          imagePath: event.imagePath,
          isCompleted: event.isCompleted,
          deadline: event.deadline,
          educationDetails: event.educationDetails,
          educationSubtype: event.educationSubtype,
        );
    }
  }

  DateTime _resolveStoredRecurringEnd(EventModel event, DateTime start) {
    if (event.endDateTime != null && event.endDateTime!.isAfter(start)) {
      return event.endDateTime!;
    }

    final rule = event.recurringRule;
    if (rule?.endTime != null) {
      final endTime = _parseHourMinute(rule!.endTime!);
      final end = DateTime(
        start.year,
        start.month,
        start.day,
        endTime.$1,
        endTime.$2,
      );

      if (end.isAfter(start)) {
        return end;
      }
    }

    return start.add(const Duration(hours: 1));
  }

  (int, int) _parseHourMinute(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return (0, 0);
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour.clamp(0, 23), minute.clamp(0, 59));
  }

  List<EventViewModel> getEventsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _events.where((e) {
      return (_showAllUsers || e.userId == _currentUserId) &&
          e.endDateTime.isAfter(dayStart) &&
          e.startDateTime.isBefore(dayEnd);
    }).toList();
  }

  List<EventViewModel> getEventsForWeek(DateTime startOfWeek, DateTime endOfWeek) {
    return _events.where((e) {
      return (_showAllUsers || e.userId == _currentUserId) &&
          e.endDateTime.isAfter(startOfWeek) &&
          e.startDateTime.isBefore(endOfWeek);
    }).toList();
  }

  List<EventViewModel> getEventsForMonth(int year, int month) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    return _events.where((e) {
      return (_showAllUsers || e.userId == _currentUserId) &&
          e.endDateTime.isAfter(monthStart) &&
          e.startDateTime.isBefore(monthEnd);
    }).toList();
  }

  Future<void> _reloadCurrentRange() async {
    await loadEvents(
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
    );
  }

  Future<void> refreshCurrentRange() async {
    await _reloadCurrentRange();
  }

  EventService get eventServiceRef => eventService;

  List<EventViewModel> getEventsForYear(int year) {
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year + 1, 1, 1);

    return _events.where((e) {
      return (_showAllUsers || e.userId == _currentUserId) &&
          e.endDateTime.isAfter(yearStart) &&
          e.startDateTime.isBefore(yearEnd);
    }).toList();
  }
}
