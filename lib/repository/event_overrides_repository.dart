import 'package:chrono_pilot/domain/models/event_override_model.dart';
import 'package:chrono_pilot/repository/database/events_local_db.dart';
import 'package:chrono_pilot/repository/event_overrides_db_mapper.dart';
import 'package:sqflite/sqflite.dart';

class EventOverridesRepository {
  final EventsLocalDB localDB = EventsLocalDB.instance;

  Future<void> addOverride(EventOverride eventOverride) async {
    final db = await localDB.database;

    await db.insert(
      'event_overrides',
      eventOverrideToDb(eventOverride),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateOverride(EventOverride eventOverride) async {
    final db = await localDB.database;

    return db.update(
      'event_overrides',
      eventOverrideToDb(eventOverride),
      where: 'id = ?',
      whereArgs: [eventOverride.id],
    );
  }

  Future<int> deleteOverride(String overrideId) async {
    final db = await localDB.database;

    return db.delete(
      'event_overrides',
      where: 'id = ?',
      whereArgs: [overrideId],
    );
  }

  Future<EventOverride> getOverrideById(String overrideId) async {
    final db = await localDB.database;

    final res = await db.query(
      'event_overrides',
      where: 'id = ?',
      whereArgs: [overrideId],
      limit: 1,
    );

    if (res.isEmpty) {
      throw Exception('Override with id $overrideId not found');
    }

    return eventOverrideFromDb(res.first);
  }

  Future<List<EventOverride>> getOverridesForRecurringEvent(
    String recurringEventId,
  ) async {
    final db = await localDB.database;

    final res = await db.query(
      'event_overrides',
      where: 'recurringEventId = ?',
      whereArgs: [recurringEventId],
      orderBy: 'originalDateTime ASC',
    );

    return res.map(eventOverrideFromDb).toList();
  }

  Future<List<EventOverride>> getOverridesForRecurringEventsInRange({
    required List<String> recurringEventIds,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (recurringEventIds.isEmpty) {
      return [];
    }

    final db = await localDB.database;
    final placeholders = List.filled(recurringEventIds.length, '?').join(', ');

    final res = await db.query(
      'event_overrides',
      where:
          'recurringEventId IN ($placeholders) AND originalDateTime >= ? AND originalDateTime <= ?',
      whereArgs: [
        ...recurringEventIds,
        rangeStart.toIso8601String(),
        rangeEnd.toIso8601String(),
      ],
      orderBy: 'originalDateTime ASC',
    );

    return res.map(eventOverrideFromDb).toList();
  }
}

