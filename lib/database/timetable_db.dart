import 'package:sqflite/sqflite.dart';
import 'package:sougou/database/database_helper.dart';

class TimetableDB {
  Future<void> insertTimetable(
      int day, int period, String subject, String room) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'timetable',
      {'day': day, 'period': period, 'subject': subject, 'room': room},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTimetable() async {
    final db = await DatabaseHelper().database;
    return await db.query('timetable');
  }

  Future<void> deleteTimetable(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTimetable() async {
    final db = await DatabaseHelper().database;
    await db.delete('timetable');
  }
}
