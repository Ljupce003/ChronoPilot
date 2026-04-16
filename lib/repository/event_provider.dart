import 'package:chrono_pilot/domain/enums/event_type.dart';
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

  EventProvider({required this.repository, required this.overridesRepository}) {
    eventService = EventService(repository);
    overrideService = EventOverrideService(overridesRepository);
    timelineService = EventTimelineService(
      eventsRepository: repository,
      overrideService: overrideService,
    );
  }

  List<EventViewModel> _events = [];
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  List<EventViewModel> get events => List.unmodifiable(_events);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

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
    if (replacementEventRequest.type == EventType.recurring) {
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