
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/repository/database/events_local_db.dart';
import 'package:chrono_pilot/repository/events_db_mapper.dart';
import 'package:sqflite/sqflite.dart';

/// Provides CRUD access to the local `events` table.
///
/// This repository is the raw persistence layer used by the event service and
/// timeline builder; it stores the encoded `EventModel` rows without applying
/// any business rules.
class EventsRepository {
  final EventsLocalDB localDB = EventsLocalDB.instance;

  /// Inserts a new event row into the local database.
  Future<void> addEvent(EventModel event) async{
    final db = await localDB.database;

    await db.insert(
        "events",
        event.toJsonEncoded(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  /// Updates an existing event row by its primary key.
  Future<int> updateEvent(EventModel event) async {
    final db = await localDB.database;

    return db.update(
      "events",
      event.toJsonEncoded(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Deletes an event row using its identifier.
  Future<int> deleteEvent(String eventId) async{
    final db = await localDB.database;

    return db.delete("events",where: 'id = ?',whereArgs: [eventId]);
  }

  /// Loads a single event row by id and maps it to an `EventModel`.
  Future<EventModel> getEventById(String eventId) async {
    final db = await localDB.database;

    var res = await db.query(
      "events",
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (res.isEmpty) {
      throw Exception("Event with id $eventId not found");
    }

    return fromDb(res.first);
  }

  /// Loads every stored event row and maps each one to an `EventModel`.
  Future<List<EventModel>> getAllEvents() async{
    final db = await localDB.database;
    var res = await db.query("events");

    return res.map((row) => fromDb(row)).toList();
  }

}


