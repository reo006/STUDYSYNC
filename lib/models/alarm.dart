import 'package:flutter/material.dart';

class Alarm {
  int? id;
  String name;
  TimeOfDay time;
  List<bool> repeatDays;
  String sound;
  bool isEnabled;

  Alarm({
    this.id,
    required this.name,
    required this.time,
    required this.repeatDays,
    required this.sound,
    required this.isEnabled,
  });

  // データベースへ保存するためのマッピング
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'time': '${time.hour}:${time.minute}', // 'HH:mm' 形式で保存
      'repeatDays': repeatDays
          .map((e) => e ? 'true' : 'false')
          .join(','), // List<bool> → String に変換
      'sound': sound,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  // データベースから取得したマップを `Alarm` オブジェクトに変換
  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      name: map['name'] ?? 'Unnamed Alarm',
      time: _parseTime(map['time']),
      repeatDays: (map['repeatDays'] as String)
          .split(',')
          .map((e) => e == 'true')
          .toList(), // 🔹 String → List<bool> に変換
      sound: map['sound'] ?? 'default_alarm',
      isEnabled: map['isEnabled'] == 1,
    );
  }

  // 'HH:mm' の形式から `TimeOfDay` に変換
  static TimeOfDay _parseTime(String timeString) {
    List<String> parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
