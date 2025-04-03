import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/calendar.dart';

class CalendarDatabase {
  static final CalendarDatabase instance = CalendarDatabase._init();
  static Database? _database;

  CalendarDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'calendar.db');

    // ⚠️【開発中のみ】データベースを削除してリセット
    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 2, // ✅ スキーマを更新（バージョンアップ）
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // ✅ DBのバージョンアップ
    );
  }

  // ✅ 【修正】カラム `endDate` を追加
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE calendar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        allDay BOOLEAN NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT, 
        startTime TEXT,
        endTime TEXT,
        notify BOOLEAN NOT NULL,
        url TEXT,
        memo TEXT,
        color INTEGER NOT NULL
      )
    ''');
  }

  // ✅【修正】スキーマ変更時に `endDate` を追加
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE calendar ADD COLUMN endDate TEXT");
    }
  }

  // ✅ イベントを追加
  Future<int> insertEvent(CalendarEvent event) async {
    final db = await instance.database;
    return await db.insert('calendar', event.toMap());
  }

  // ✅ すべてのイベントを取得
  Future<List<CalendarEvent>> getAllEvents() async {
    final db = await instance.database;
    final result = await db.query('calendar');
    return result.map((json) => CalendarEvent.fromMap(json)).toList();
  }

  // ✅ イベントを更新
  Future<int> updateEvent(CalendarEvent event) async {
    final db = await instance.database;
    return await db.update(
      'calendar',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  // ✅ イベントを削除
  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    return await db.delete(
      'calendar',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
