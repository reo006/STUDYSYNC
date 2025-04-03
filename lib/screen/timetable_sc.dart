import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sougou/database/timetable_db.dart';
import 'timetablecon.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  TimetableScreenState createState() => TimetableScreenState();
}

class TimetableScreenState extends State<TimetableScreen> {
  final List<List<String?>> timetable =
      List.generate(5, (_) => List.filled(4, null));
  final List<String> weekdays = ['月', '火', '水', '木', '金'];
  List<Map<String, String>> templates = [];
  int currentWeekdayIndex = DateTime.now().weekday - 1;
  List<Map<String, dynamic>> todayTimetable = [];

  @override
  void initState() {
    super.initState();
    _loadTimetableFromDB();
  }

  // DBから時間割をロード
  void _loadTimetableFromDB() async {
    final dbData = await TimetableDB().getTimetable();
    setState(() {
      for (var entry in dbData) {
        int day = entry['day'];
        int period = entry['period'];
        timetable[day][period] = '${entry['subject']} (${entry['room']})';
      }
      _updateTodayTimetable();
    });
  }

  // **追加** 今日の時間割を更新する関数
  void _updateTodayTimetable() {
    if (currentWeekdayIndex >= 0 && currentWeekdayIndex < 5) {
      todayTimetable = List.generate(4, (period) {
        return {
          'period': '${period + 1}限',
          'subject': timetable[currentWeekdayIndex][period],
        };
      }).where((item) => item['subject'] != null).toList();
    } else {
      todayTimetable = [];
    }
  }

  void _addSubject(int day, int period) async {
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テンプレートがありません。管理画面で作成してください。')),
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return ListTile(
              title: Text(template['subject']!),
              subtitle: Text(template['room']!),
              onTap: () {
                Navigator.pop(context, template);
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        timetable[day][period] = '${result["subject"]} (${result["room"]})';
        TimetableDB()
            .insertTimetable(day, period, result["subject"]!, result["room"]!);
        _updateTodayTimetable();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate =
        DateFormat('yyyy/MM/dd').format(today); // **修正: formattedDateをUIに使用**

    return Scaffold(
      appBar: AppBar(
        title: const Text('時間割'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openManagementScreen,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Table(
              border: TableBorder.all(color: Colors.grey),
              children: [
                TableRow(
                  children: weekdays
                      .map((day) => Container(
                            height: 40,
                            alignment: Alignment.center,
                            color: const Color.fromARGB(130, 78, 206, 235),
                            child: Text(
                              day,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                ),
                for (int period = 0; period < 4; period++)
                  TableRow(
                    children: [
                      for (int day = 0; day < 5; day++)
                        GestureDetector(
                          onTap: () => _addSubject(day, period),
                          child: Container(
                            height: 80,
                            alignment: Alignment.center,
                            child: Text(
                              timetable[day][period] ?? '未設定',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 1, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '今日の時間割',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
  '$formattedDate　${weekdays[currentWeekdayIndex]}',
  textAlign: TextAlign.center,
  style: const TextStyle(fontSize: 26), // フォントサイズを20に設定
),
                  ...todayTimetable.map((entry) {
  return Text(
    '${entry["period"]}: ${entry["subject"]}',
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 28), // フォントサイズを20に設定
  );
}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openManagementScreen() async {
  final result = await Navigator.push<List<Map<String, String>>>(
    context,
    MaterialPageRoute(
      builder: (context) => TimetableConScreen(existingTemplates: templates), // ✅ existingTemplates を渡す
    ),
  );

  if (result != null) {
    setState(() {
      templates = result;
    });
  }
  }
}
