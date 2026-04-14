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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
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
}