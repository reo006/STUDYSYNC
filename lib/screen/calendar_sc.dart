import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar.dart';
import '../database/calendar_db.dart';

class CalendarSc extends StatefulWidget {
  const CalendarSc({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarSc> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await CalendarDatabase.instance.getAllEvents();
    if (mounted) {
      setState(() {
        _events = events;
      });
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) => isSameDay(event.startDate, day)).toList();
  }

  void _addOrUpdateEvent({CalendarEvent? event, required DateTime selectedDay}) {
    final titleController = TextEditingController(text: event?.title ?? '');
    final memoController = TextEditingController(text: event?.memo ?? '');
    bool notify = event?.notify ?? false;
    bool allDay = event?.allDay ?? false;
    TimeOfDay startTime = event?.startTime ?? TimeOfDay.now();
    TimeOfDay endTime = event?.endTime ?? TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(event == null ? "予定を追加" : "予定を編集"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "タイトル"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("終日"),
                      Switch(
                        value: allDay,
                        onChanged: (value) {
                          setStateDialog(() {
                            allDay = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (!allDay) ...[
                    ListTile(
                      title: Text("開始時間: ${startTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (pickedTime != null) {
                          setStateDialog(() {
                            startTime = pickedTime;
                            // 終了時間が開始時間よりも前にならないように調整
                            if (endTime.hour < startTime.hour || (endTime.hour == startTime.hour && endTime.minute < startTime.minute)) {
                              endTime = TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute);
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text("終了時間: ${endTime.format(context)}"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (pickedTime != null) {
                          setStateDialog(() {
                            // 終了時間が開始時間よりも前の場合、開始時間と同じにする
                            if (pickedTime.hour < startTime.hour || (pickedTime.hour == startTime.hour && pickedTime.minute < startTime.minute)) {
                              endTime = startTime;
                            } else {
                              endTime = pickedTime;
                            }
                          });
                        }
                      },
                    ),
                  ],
                  TextField(
                    controller: memoController,
                    decoration: const InputDecoration(labelText: "メモ"),
                    maxLines: 3,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("通知"),
                      Switch(
                        value: notify,
                        onChanged: (value) {
                          setStateDialog(() {
                            notify = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("キャンセル"),
              ),
              TextButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    final newEvent = CalendarEvent(
                      id: event?.id,
                      title: titleController.text,
                      startDate: selectedDay,
                      allDay: allDay,
                      startTime: allDay ? null : startTime,
                      endTime: allDay ? null : endTime,
                      memo: memoController.text.isNotEmpty ? memoController.text : null,
                      notify: notify,
                    );

                    if (event == null) {
                      await CalendarDatabase.instance.insertEvent(newEvent);
                    } else {
                      await CalendarDatabase.instance.updateEvent(newEvent);
                    }

                    if (mounted) {
                      await _loadEvents();
                      setState(() {});
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(event == null ? "追加" : "保存"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteEvent(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("予定を削除"),
        content: Text("「${event.title}」を削除しますか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () async {
              await CalendarDatabase.instance.deleteEvent(event.id!);
              if (mounted) {
                await _loadEvents();
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text("削除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final event = _getEventsForDay(_selectedDay!)[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(event.allDay
                        ? "終日"
                        : "開始: ${event.startTime?.format(context) ?? "未設定"} / 終了: ${event.endTime?.format(context) ?? "未設定"}"),
                    onTap: () => _addOrUpdateEvent(event: event, selectedDay: _selectedDay!),
                    onLongPress: () => _confirmDeleteEvent(event),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateEvent(selectedDay: _selectedDay!),
        child: const Icon(Icons.add),
      ),
    );
  }
}