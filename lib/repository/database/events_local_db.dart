import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class EventsLocalDB {
  static final EventsLocalDB instance = EventsLocalDB._init();
  static Database? _database;

  EventsLocalDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await _createEventsTable(db);
    await _createEventOverridesTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createEventOverridesTable(db);
    }
  }

  Future<void> _createEventsTable(Database db) async {
    await db.execute('''
    CREATE TABLE events (
      id TEXT PRIMARY KEY,
      userId TEXT,
      title TEXT,
      description TEXT,

      startDateTime TEXT,
      endDateTime TEXT,

      location TEXT,
      imagePath TEXT,

      type TEXT,

      isCompleted INTEGER,
      deadline TEXT,

      lectureDetails TEXT,
      subtype TEXT,

      recurringRule TEXT
    )
  ''');
  }

  Future<void> _createEventOverridesTable(Database db) async {
    await db.execute('''
    CREATE TABLE event_overrides (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      recurringEventId TEXT NOT NULL,
      type TEXT NOT NULL,
      originalDateTime TEXT NOT NULL,
      newStartDateTime TEXT,
      newEndDateTime TEXT,
      note TEXT,
      UNIQUE(recurringEventId, originalDateTime)
    )
  ''');

    await db.execute(
      'CREATE INDEX idx_event_overrides_recurring_original ON event_overrides(recurringEventId, originalDateTime)',
    );
  }
}