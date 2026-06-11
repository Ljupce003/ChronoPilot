import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the local SQLite database instance and schema creation.
///
/// The database stores both events and event overrides; it is initialized once
/// and reused across repositories through the singleton `instance`.
class EventsLocalDB {
  static final EventsLocalDB instance = EventsLocalDB._init();
  static Database? _database;

  EventsLocalDB._init();

  /// Returns the opened database, initializing it on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events.db');
    return _database!;
  }

  /// Opens the database file and wires creation/upgrade callbacks.
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the initial tables when the database file is first created.
  Future _createDB(Database db, int version) async {
    await _createEventsTable(db);
    await _createEventOverridesTable(db);
  }

  /// Handles destructive schema upgrades for incompatible old versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS event_overrides');
      await db.execute('DROP TABLE IF EXISTS events');
      await _createEventOverridesTable(db);
      await _createEventsTable(db);
    }
  }

  /// Creates the `events` table used by the app's local event storage.
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

      scheduleType TEXT,
      contentType TEXT,

      isCompleted INTEGER,
      deadline TEXT,

      educationDetails TEXT,
      educationSubtype TEXT,

      recurringRule TEXT
    )
  ''');
  }

  /// Creates the `event_overrides` table and its supporting index.
  Future<void> _createEventOverridesTable(Database db) async {
    await db.execute('''
    CREATE TABLE event_overrides (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      recurringEventId TEXT NOT NULL,
      overrideType TEXT NOT NULL,
      originalDateTime TEXT NOT NULL,
      newStartDateTime TEXT,
      newEndDateTime TEXT,
      replacementEventId TEXT,
      note TEXT,
      UNIQUE(recurringEventId, originalDateTime)
    )
  ''');

    await db.execute(
      'CREATE INDEX idx_event_overrides_recurring_original ON event_overrides(recurringEventId, originalDateTime)',
    );
  }
}