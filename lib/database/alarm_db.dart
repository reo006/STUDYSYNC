import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alarm.dart';

class AlarmDatabase {
  static final AlarmDatabase instance = AlarmDatabase._init();
  static Database? _database;

  AlarmDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alarms.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        time TEXT NOT NULL,
        repeatDays TEXT NOT NULL,
        sound TEXT NOT NULL,
        isEnabled INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertAlarm(Alarm alarm) async {
    final db = await instance.database;
    return await db.insert('alarms', alarm.toMap());
  }

  Future<List<Alarm>> getAllAlarms() async {
    final db = await instance.database;
    final result = await db.query('alarms');
    return result.map((json) => Alarm.fromMap(json)).toList();
  }

  Future<int> updateAlarm(Alarm alarm) async {
    final db = await instance.database;
    return await db.update(
      'alarms',
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<int> deleteAlarm(int id) async {
    final db = await instance.database;
    return await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
