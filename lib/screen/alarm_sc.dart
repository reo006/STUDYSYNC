import 'dart:async'; // タイマーを使用するために追加
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日時フォーマット用
import '../models/alarm.dart';
import '../database/alarm_db.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  AlarmScreenState createState() => AlarmScreenState();
}

class AlarmScreenState extends State<AlarmScreen> {
  List<Alarm> _alarms = [];
  String _currentTime = ""; // ⏰ 現在時刻の文字列

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _updateTime(); // ⏰ 現在時刻を更新
  }

  // 📌 毎秒現在時刻を更新
  void _updateTime() {
    _currentTime = _getCurrentTime(); // 初期値設定
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _currentTime = _getCurrentTime();
      });
    });
  }

  // ⏰ 現在時刻を取得（12時間表記, hh:mm:ss AM/PM）
  String _getCurrentTime() {
    return DateFormat('a hh:mm:ss').format(DateTime.now());
  }

  Future<void> _loadAlarms() async {
  final alarms = await AlarmDatabase.instance.getAllAlarms();
  
  // 📌 時間が早い順にソート（AM 0:00 から PM 11:59 の順）
  alarms.sort((a, b) {
    final aTime = a.time.hour * 60 + a.time.minute; // 時間と分を分単位に変換
    final bTime = b.time.hour * 60 + b.time.minute;
    return aTime.compareTo(bTime);
  });

  setState(() {
    _alarms = alarms;
  });
}

  Future<void> _removeAlarm(int id) async {
    await AlarmDatabase.instance.deleteAlarm(id);
    _loadAlarms();
  }

  // 🗑️ 削除の確認ダイアログを表示
  void _showDeleteConfirmationDialog(int alarmId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("アラーム削除"),
        content: const Text("このアラームを削除しますか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // キャンセル
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () {
              _removeAlarm(alarmId); // アラーム削除
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
    appBar: AppBar(title: const Text('アラーム')),
    body: Column(
      children: [
        // 🕒 ここにデジタル時計を追加
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _currentTime, // 現在時刻を表示
            style: const TextStyle(
              fontSize: 48, // 🔤 フォントサイズを大きくする
              fontWeight: FontWeight.bold, // ✅ 太字
              fontFamily: 'monospace', // デジタル時計風フォント
              color: Colors.blue, // 🎨 文字色を変更
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.grey), // 区切り線
        Expanded(
          child: _alarms.isEmpty
              ? const Center(
                  child: Text(
                    'アラームがありません',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = _alarms[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // ✅ 中央揃え
                          children: [
                            // ⏰ 時間を大きく表示
                            Text(
                              alarm.time.format(context), // hh:mm形式で表示
                              style: const TextStyle(
                                fontSize: 32, // ✅ 時間のフォントサイズを大きく
                                fontWeight: FontWeight.bold, // ✅ 太字
                              ),
                              textAlign: TextAlign.center, // ✅ 中央揃え
                            ),
                            const SizedBox(height: 8), // 間隔を空ける
                            // 📌 アラーム名（タイトル）
                            Text(
                              alarm.name,
                              style: const TextStyle(
                                fontSize: 20, // ✅ タイトルのフォントサイズ
                                fontWeight: FontWeight.bold, // ✅ 太字
                              ),
                              textAlign: TextAlign.center, // ✅ 中央揃え
                            ),
                            const SizedBox(height: 4), // 間隔を空ける
                            // 🔄 繰り返し情報
                            Text(
                              '繰り返し: ${_formatRepeatDays(alarm.repeatDays)}',
                              style: const TextStyle(fontSize: 16), // ✅ 繰り返しのフォントサイズ
                              textAlign: TextAlign.center, // ✅ 中央揃え
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: alarm.isEnabled,
                          onChanged: (value) async {
                            setState(() {
                              alarm.isEnabled = value;
                            });
                            await AlarmDatabase.instance.updateAlarm(alarm);
                          },
                        ),
                        onTap: () => _showAddAlarmDialog(alarm: alarm), // ✅ 1回タップで編集
                        onLongPress: () => _showDeleteConfirmationDialog(alarm.id!), // ✅ 長押しで削除確認
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddAlarmDialog,
      child: const Icon(Icons.add),
    ),
  );
}



Future<void> _showAddAlarmDialog({Alarm? alarm}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: alarm?.name ?? '');
  TimeOfDay selectedTime = alarm?.time ?? TimeOfDay.now();
  List<bool> repeatDays = alarm?.repeatDays ?? List.filled(7, false);
  String selectedSound = alarm?.sound ?? 'default_alarm';
  bool isEnabled = alarm?.isEnabled ?? true;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: Text(alarm == null ? 'アラームを追加' : 'アラームを編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '名前'),
                      validator: (value) =>
                          value == null || value.isEmpty ? '名前を入力してください' : null,
                    ),
                    ListTile(
                      title: Text(selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedTime = picked);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSound,
                      decoration: const InputDecoration(labelText: 'サウンド'), // ✅ サウンドは登録・編集時のみ表示
                      items: ['default_alarm', 'beep', 'chime']
                          .map((sound) => DropdownMenuItem(
                              value: sound, child: Text(sound)))
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedSound = value!;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('有効'),
                        Switch(
                          value: isEnabled,
                          onChanged: (value) {
                            setStateDialog(() {
                              isEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newAlarm = Alarm(
                  name: nameController.text,
                  time: selectedTime,
                  repeatDays: repeatDays,
                  sound: selectedSound, // ✅ データとしては保存する
                  isEnabled: isEnabled,
                );
                alarm == null
                    ? await AlarmDatabase.instance.insertAlarm(newAlarm)
                    : await AlarmDatabase.instance.updateAlarm(newAlarm);
                _loadAlarms();
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
}

  String _formatRepeatDays(List<bool> repeatDays) {
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    List<String> activeDays = [];

    for (int i = 0; i < repeatDays.length; i++) {
      if (repeatDays[i]) activeDays.add(days[i]);
    }

    return activeDays.isEmpty ? 'なし' : activeDays.join(', ');
  }
}
