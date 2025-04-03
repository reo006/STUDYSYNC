import 'package:flutter/material.dart';

class CalendarEvent {
  int? id;
  String title;
  bool allDay;
  DateTime startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool notify;
  String? url;
  String? memo;
  Color color;

  CalendarEvent({
    this.id,
    required this.title,
    this.allDay = false,
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.notify = false,
    this.url,
    this.memo,
    this.color = Colors.blue,
  });

  // ✅ マップに変換（データベース保存用）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'allDay': allDay ? 1 : 0,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(), // ✅ 修正: `endDate` を追加
      'startTime':
          startTime != null ? '${startTime!.hour}:${startTime!.minute}' : null,
      'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
      'notify': notify ? 1 : 0,
      'url': url,
      'memo': memo,
      'color': color.value,
    };
  }

  // ✅ マップから復元（データベースから取得用）
  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'],
      title: map['title'],
      allDay: map['allDay'] == 1,
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      startTime: _parseTime(map['startTime']),
      endTime: _parseTime(map['endTime']),
      notify: map['notify'] == 1,
      url: map['url'],
      memo: map['memo'],
      color: Color(map['color']),
    );
  }

  static TimeOfDay? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
