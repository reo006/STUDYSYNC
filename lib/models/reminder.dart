import 'package:flutter/material.dart';

class Reminder {
  int? id;
  String name;
  DateTime date;
  TimeOfDay time;
  String repeat;
  String priority;

  Reminder({
    this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.repeat,
    required this.priority,
  });

  // DB への保存用マップ
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'repeat': repeat,
      'priority': priority,
    };
  }

  // DB からのデータをオブジェクト化
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      name: map['name'],
      date: DateTime.parse(map['date']),
      time: _parseTime(map['time']),
      repeat: map['repeat'],
      priority: map['priority'],
    );
  }

  // 'HH:mm' 形式を `TimeOfDay` に変換
  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
