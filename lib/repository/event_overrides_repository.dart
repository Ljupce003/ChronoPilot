import 'package:chrono_pilot/domain/models/event_override_model.dart';
import 'package:chrono_pilot/repository/database/events_local_db.dart';
import 'package:chrono_pilot/repository/event_overrides_db_mapper.dart';
import 'package:sqflite/sqflite.dart';

/// Provides CRUD access to the local `event_overrides` table.
///
/// Overrides are stored separately from events so recurring modifications and
/// cancellations can be tracked independently from the base event rows.
class EventOverridesRepository {
  final EventsLocalDB localDB = EventsLocalDB.instance;

  /// Inserts a new override row.
  Future<void> addOverride(EventOverride eventOverride) async {
    final db = await localDB.database;

    await db.insert(
      'event_overrides',
      eventOverrideToDb(eventOverride),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing override row by its identifier.
  Future<int> updateOverride(EventOverride eventOverride) async {
    final db = await localDB.database;

    return db.update(
      'event_overrides',
      eventOverrideToDb(eventOverride),
      where: 'id = ?',
      whereArgs: [eventOverride.id],
    );
  }

  /// Deletes a single override row by id.
  Future<int> deleteOverride(String overrideId) async {
    final db = await localDB.database;

    return db.delete(
      'event_overrides',
      where: 'id = ?',
      whereArgs: [overrideId],
    );
  }

  /// Loads one override by id and maps it to the domain model.
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

  /// Loads every override that belongs to a specific recurring event.
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

  /// Loads overrides for a set of recurring events within a date range.
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

  /// Loads overrides that reference a particular replacement event.
  Future<List<EventOverride>> getOverridesByReplacementEventId(
    String replacementEventId,
  ) async {
    final db = await localDB.database;

    final res = await db.query(
      'event_overrides',
      where: 'replacementEventId = ?',
      whereArgs: [replacementEventId],
      orderBy: 'originalDateTime DESC',
    );

    return res.map(eventOverrideFromDb).toList();
  }
}

