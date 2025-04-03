import 'package:flutter/material.dart';
import 'package:sougou/screen/alarm_sc.dart';
import 'package:sougou/screen/calendar_sc.dart';
import 'package:sougou/screen/reminder_sc.dart';
import 'package:sougou/screen/timetable_sc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> deleteDatabaseFile() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'alarms.db');

  await deleteDatabase(path);
  print("Database deleted");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await deleteDatabaseFile(); // ✅ データベース削除
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData.dark(), // ダークテーマを適用
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  MainAppState createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  int _selectedIndex = 2; // 初期画面をカレンダーに設定

  final List<Widget> _screens = [
    const AlarmScreen(),
    const CalendarSc(),
    const ReminderScreen(),
    const TimetableScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // ✅ タブが5つ以上ある場合は必須
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(227, 25, 110, 247), // ✅ 選択中のアイコンとラベルを緑に変更
        unselectedItemColor: const Color.fromARGB(43, 109, 234, 213), // ✅ 未選択のアイコンとラベルを淡い緑に変更
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm), label: 'アラーム'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'カレンダー'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'リマインダー'),
          BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: '時間割'),
        ],
      ),
    );
  }
}
