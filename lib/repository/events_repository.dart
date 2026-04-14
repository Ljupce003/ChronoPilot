
import 'package:chrono_pilot/domain/models/event_model.dart';
import 'package:chrono_pilot/repository/database/events_local_db.dart';
import 'package:chrono_pilot/repository/events_db_mapper.dart';
import 'package:sqflite/sqflite.dart';

class EventsRepository {
  final EventsLocalDB localDB = EventsLocalDB.instance;

  Future<void> addEvent(EventModel event) async{
    final db = await localDB.database;
    print("DB INSERT → ${event.id}");
    await db.insert(
        "events",
        event.toJsonEncoded(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateEvent(EventModel event) async {
    final db = await localDB.database;
    print("DB UPDATE → ${event.id}");
    return db.update(
      "events",
      event.toJsonEncoded(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(String eventId) async{
    final db = await localDB.database;
    print("DB DELETE → $eventId");
    return db.delete("events",where: 'id = ?',whereArgs: [eventId]);
  }

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

  Future<List<EventModel>> getAllEvents() async{
    final db = await localDB.database;
    var res = await db.query("events");

    return res.map((row) => fromDb(row)).toList();
  }

}


