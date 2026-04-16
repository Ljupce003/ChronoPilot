import 'package:chrono_pilot/domain/enums/override_type.dart';
import 'package:chrono_pilot/domain/models/event_override_model.dart';
import 'package:chrono_pilot/repository/event_overrides_repository.dart';
import 'package:uuid/uuid.dart';

class EventOverrideService {
  final EventOverridesRepository repository;
  final _uuid = const Uuid();

  EventOverrideService(this.repository);

  Future<EventOverride> createCancelledOverride({
    required String userId,
    required String recurringEventId,
    required DateTime originalDateTime,
    String? note,
  }) async {
    final eventOverride = EventOverride(
      id: _uuid.v4(),
      userId: userId,
      recurringEventId: recurringEventId,
      type: OverrideType.cancelled,
      originalDateTime: originalDateTime,
      note: note,
    );

    await repository.addOverride(eventOverride);
    return eventOverride;
  }

  Future<EventOverride> createModifiedOverride({
    required String userId,
    required String recurringEventId,
    required DateTime originalDateTime,
    DateTime? newStartDateTime,
    DateTime? newEndDateTime,
    String? note,
  }) async {
    if (newStartDateTime == null && newEndDateTime == null && note == null) {
      throw ArgumentError(
        'Modified override must include at least one changed field.',
      );
    }

    final eventOverride = EventOverride(
      id: _uuid.v4(),
      userId: userId,
      recurringEventId: recurringEventId,
      type: OverrideType.modified,
      originalDateTime: originalDateTime,
      newStartDateTime: newStartDateTime,
      newEndDateTime: newEndDateTime,
      note: note,
    );

    await repository.addOverride(eventOverride);
    return eventOverride;
  }

  Future<void> deleteOverride(String overrideId) async {
    await repository.deleteOverride(overrideId);
  }

  Future<List<EventOverride>> getOverridesForRecurringEventsInRange({
    required List<String> recurringEventIds,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    return repository.getOverridesForRecurringEventsInRange(
      recurringEventIds: recurringEventIds,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }
}

