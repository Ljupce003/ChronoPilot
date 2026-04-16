import 'package:chrono_pilot/domain/enums/event_type.dart';
import 'package:chrono_pilot/domain/enums/override_type.dart';
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/domain/models/event_override_model.dart';
import 'package:chrono_pilot/domain/models/recurring_rule.dart';
import 'package:chrono_pilot/presentation/models/event_view_model.dart';
import 'package:chrono_pilot/repository/events_repository.dart';
import 'package:chrono_pilot/service/event_override_service.dart';

class EventTimelineService {
  final EventsRepository eventsRepository;
  final EventOverrideService overrideService;

  EventTimelineService({
    required this.eventsRepository,
    required this.overrideService,
  });

  Future<List<EventViewModel>> buildViewModelsForRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final normalized = _normalizeRange(rangeStart, rangeEnd);
    final from = normalized.$1;
    final to = normalized.$2;

    final allEvents = await eventsRepository.getAllEvents();
    final recurringEvents = allEvents
        .where((e) => e.type == EventType.recurring && e.recurringRule != null)
        .toList();

    final recurringIds = recurringEvents.map((e) => e.id).toList();
    final overrides = await overrideService.getOverridesForRecurringEventsInRange(
      recurringEventIds: recurringIds,
      rangeStart: from,
      rangeEnd: to,
    );

    final eventsById = {for (final event in allEvents) event.id: event};
    final replacementIds = overrides
        .map((o) => o.replacementEventId)
        .whereType<String>()
        .toSet();

    final baseViewModels = allEvents
        .where((e) => e.type != EventType.recurring && !replacementIds.contains(e.id))
        .map(_mapBaseEvent)
        .whereType<EventViewModel>()
        .where((vm) => _intersects(vm.startDateTime, vm.endDateTime, from, to))
        .toList();

    final overrideByKey = {
      for (final item in overrides)
        _overrideKey(item.recurringEventId, item.originalDateTime): item,
    };

    final recurringViewModels = <EventViewModel>[];
    for (final recurring in recurringEvents) {
      recurringViewModels.addAll(
        _buildRecurringViewModels(
          recurring,
          from,
          to,
          overrideByKey,
          eventsById,
        ),
      );
    }

    final allViewModels = [...baseViewModels, ...recurringViewModels]
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return allViewModels;
  }

  List<EventViewModel> _buildRecurringViewModels(
    EventModel recurring,
    DateTime rangeStart,
    DateTime rangeEnd,
    Map<String, EventOverride> overrideByKey,
    Map<String, EventModel> eventsById,
  ) {
    final occurrences = _expandOccurrencesInRange(recurring, rangeStart, rangeEnd);
    final result = <EventViewModel>[];

    for (final occurrence in occurrences) {
      final key = _overrideKey(recurring.id, occurrence.originalStart);
      final override = overrideByKey[key];

      if (override == null) {
        result.add(
          _mapRecurringOccurrence(
            recurring,
            occurrenceStart: occurrence.originalStart,
            occurrenceEnd: occurrence.originalEnd,
          ),
        );
        continue;
      }

      if (override.type == OverrideType.cancelled) {
        continue;
      }

      if (override.type == OverrideType.modified) {
        if (override.replacementEventId != null) {
          final replacement = eventsById[override.replacementEventId!];
          if (replacement != null) {
            final replacementVm = _mapReplacementEvent(
              replacement,
              overrideId: override.id,
              recurringEventId: recurring.id,
            );

            if (replacementVm != null &&
                _intersects(
                  replacementVm.startDateTime,
                  replacementVm.endDateTime,
                  rangeStart,
                  rangeEnd,
                )) {
              result.add(replacementVm);
            }
            continue;
          }
        }

        final overriddenStart = override.newStartDateTime ?? occurrence.originalStart;
        var overriddenEnd = override.newEndDateTime ?? occurrence.originalEnd;

        if (!overriddenEnd.isAfter(overriddenStart)) {
          overriddenEnd = overriddenStart.add(const Duration(hours: 1));
        }

        if (_intersects(overriddenStart, overriddenEnd, rangeStart, rangeEnd)) {
          result.add(
            _mapRecurringOccurrence(
              recurring,
              occurrenceStart: overriddenStart,
              occurrenceEnd: overriddenEnd,
              overrideId: override.id,
            ),
          );
        }
      }
    }

    return result;
  }

  EventViewModel? _mapBaseEvent(EventModel event) {
    switch (event.type) {
      case EventType.single:
      case EventType.lecture:
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
          type: event.type,
          location: event.location,
          imagePath: event.imagePath,
          isCompleted: event.type == EventType.todo ? event.isCompleted : null,
          deadline: event.deadline,
          educationDetails: event.educationDetails,
          subtype: event.subtype,
        );
      case EventType.todo:
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
          type: event.type,
          location: event.location,
          imagePath: event.imagePath,
          isCompleted: event.isCompleted,
          deadline: event.deadline,
          educationDetails: event.educationDetails,
          subtype: event.subtype,
        );
      case EventType.recurring:
        return null;
    }
  }

  EventViewModel _mapRecurringOccurrence(
    EventModel recurring, {
    required DateTime occurrenceStart,
    required DateTime occurrenceEnd,
    String? overrideId,
  }) {
    return EventViewModel(
      id: '${recurring.id}@${occurrenceStart.toIso8601String()}',
      userId: recurring.userId,
      title: recurring.title,
      description: recurring.description,
      startDateTime: occurrenceStart,
      endDateTime: occurrenceEnd,
      type: EventType.recurring,
      location: recurring.location,
      imagePath: recurring.imagePath,
      isCompleted: recurring.isCompleted,
      deadline: recurring.deadline,
      educationDetails: recurring.educationDetails,
      subtype: recurring.subtype,
      overrideId: overrideId,
      recurringEventId: recurring.id,
    );
  }

  EventViewModel? _mapReplacementEvent(
    EventModel replacement, {
    required String overrideId,
    required String recurringEventId,
  }) {
    final base = _mapBaseEvent(replacement);
    if (base == null) {
      return null;
    }

    return EventViewModel(
      id: base.id,
      userId: base.userId,
      title: base.title,
      description: base.description,
      startDateTime: base.startDateTime,
      endDateTime: base.endDateTime,
      type: base.type,
      location: base.location,
      imagePath: base.imagePath,
      isCompleted: base.isCompleted,
      deadline: base.deadline,
      educationDetails: base.educationDetails,
      subtype: base.subtype,
      overrideId: overrideId,
      recurringEventId: recurringEventId,
    );
  }

  List<_Occurrence> _expandOccurrencesInRange(
    EventModel event,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final rule = event.recurringRule;
    if (rule == null) {
      return const [];
    }

    final startDay = _maxDate(_stripTime(rule.startDate), _stripTime(rangeStart));
    final endBound = rule.endDate == null ? rangeEnd : _minDate(rangeEnd, rule.endDate!);
    final endDay = _stripTime(endBound);

    if (endDay.isBefore(startDay)) {
      return const [];
    }

    final startTime = _parseHourMinute(rule.startTime);
    final duration = _resolveDuration(event, rule, startTime);

    final occurrences = <_Occurrence>[];
    var day = startDay;
    while (!day.isAfter(endDay)) {
      if (rule.daysOfWeek.contains(day.weekday)) {
        final occurrenceStart = DateTime(
          day.year,
          day.month,
          day.day,
          startTime.$1,
          startTime.$2,
        );
        final occurrenceEnd = occurrenceStart.add(duration);

        if (_intersects(occurrenceStart, occurrenceEnd, rangeStart, rangeEnd)) {
          occurrences.add(
            _Occurrence(
              originalStart: occurrenceStart,
              originalEnd: occurrenceEnd,
            ),
          );
        }
      }

      day = day.add(const Duration(days: 1));
    }

    return occurrences;
  }

  Duration _resolveDuration(
    EventModel event,
    RecurringRule rule,
    (int, int) startTime,
  ) {
    if (event.startDateTime != null && event.endDateTime != null) {
      final delta = event.endDateTime!.difference(event.startDateTime!);
      if (delta.inMinutes > 0) {
        return delta;
      }
    }

    if (rule.endTime != null) {
      final endTime = _parseHourMinute(rule.endTime!);
      final anchor = DateTime(2000, 1, 1, startTime.$1, startTime.$2);
      final endAnchor = DateTime(2000, 1, 1, endTime.$1, endTime.$2);
      final delta = endAnchor.difference(anchor);
      if (delta.inMinutes > 0) {
        return delta;
      }
    }

    return const Duration(hours: 1);
  }

  (DateTime, DateTime) _normalizeRange(DateTime a, DateTime b) {
    if (a.isAfter(b)) {
      return (b, a);
    }
    return (a, b);
  }

  String _overrideKey(String recurringEventId, DateTime originalDateTime) {
    return '$recurringEventId|${originalDateTime.toIso8601String()}';
  }

  DateTime _stripTime(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _maxDate(DateTime a, DateTime b) {
    return a.isAfter(b) ? a : b;
  }

  DateTime _minDate(DateTime a, DateTime b) {
    return a.isBefore(b) ? a : b;
  }

  (int, int) _parseHourMinute(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid HH:mm time format: $value');
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw FormatException('Invalid HH:mm time format: $value');
    }

    return (hour, minute);
  }

  bool _intersects(
    DateTime start,
    DateTime end,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return end.isAfter(rangeStart) && start.isBefore(rangeEnd);
  }
}

class _Occurrence {
  final DateTime originalStart;
  final DateTime originalEnd;

  const _Occurrence({
    required this.originalStart,
    required this.originalEnd,
  });
}

