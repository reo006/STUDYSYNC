import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../database/reminder_db.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  ReminderScreenState createState() => ReminderScreenState();
}

class ReminderScreenState extends State<ReminderScreen> {
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final reminders = await ReminderDatabase.instance.getAllReminders();
    
    setState(() {
      // 📌 直近の予定を先に、残りを優先度順にソート
      _reminders = _sortReminders(reminders);
    });
  }

  Future<void> _removeReminder(int id) async {
    await ReminderDatabase.instance.deleteReminder(id);
    _loadReminders();
  }

  // 📌 リマインダーを並べ替え（直近の予定を最上位、それ以降は優先度順）
  List<Reminder> _sortReminders(List<Reminder> reminders) {
    DateTime now = DateTime.now();
    
    // 📌 直近の予定
    List<Reminder> upcoming = reminders.where((r) => r.date.isAfter(now)).toList();
    upcoming.sort((a, b) => a.date.compareTo(b.date)); // 📌 直近の予定順

    // 📌 直近以外の予定（過去含む）を優先度順に並べる
    List<Reminder> others = reminders.where((r) => r.date.isBefore(now)).toList();
    others.sort((a, b) => _priorityValue(b.priority).compareTo(_priorityValue(a.priority))); // 📌 優先度順

    return [...upcoming, ...others];
  }

  // 🎨 優先度に応じた背景色を取得
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case '高':
        return Colors.red.withOpacity(0.3); // 半透明の赤
      case '普通':
        return Colors.yellow.withOpacity(0.3); // 半透明の黄色
      case '低':
        return Colors.green.withOpacity(0.3); // 半透明の緑
      default:
        return Colors.white; // デフォルトは白
    }
  }

  // 📌 優先度の値（高い方を大きくする）
  int _priorityValue(String priority) {
    switch (priority) {
      case '高':
        return 3;
      case '普通':
        return 2;
      case '低':
        return 1;
      default:
        return 0;
    }
  }

  // 🗑️ 削除の確認ポップアップを表示
  void _showDeleteConfirmationDialog(int reminderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("リマインダー削除"),
        content: const Text("このリマインダーを削除しますか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () {
              _removeReminder(reminderId);
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
      appBar: AppBar(title: const Text('リマインダー')),
      body: _reminders.isEmpty
          ? const Center(
              child: Text(
                'リマインダーがありません',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];

                      return Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            color: _getPriorityColor(reminder.priority), // 🎨 背景色を適用
                            child: ListTile(
                              title: Text(
                                reminder.name,
                                textAlign: TextAlign.center, // ✅ 中央揃え
                                style: const TextStyle(
                                  fontSize: 20, // ✅ 大きめのフォント
                                  fontWeight: FontWeight.bold, // ✅ 太字
                                ),
                              ),
                              subtitle: Text(
                                '日時: ${DateFormat('yyyy/MM/dd HH:mm').format(reminder.date)}\n'
                                '優先度: ${reminder.priority}',
                                textAlign: TextAlign.center, // ✅ 中央揃え
                              ),
                              onTap: () => _showAddReminderDialog(reminder: reminder), // ✅ 1回タップで編集
                              onLongPress: () => _showDeleteConfirmationDialog(reminder.id!), // ✅ 長押しで削除確認
                            ),
                          ),
                          if (index == 0) // 📌 一番上のリマインダーの下に線を追加
                            const Divider(thickness: 2, color: Color.fromARGB(255, 0, 115, 255)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

Future<void> _showAddReminderDialog({Reminder? reminder}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: reminder?.name ?? '');
  DateTime selectedDate = reminder?.date ?? DateTime.now();
  TimeOfDay selectedTime = reminder?.time ?? TimeOfDay.now();
  // ✅ 初期値を修正して、編集時に既存の優先度を考慮する
  String selectedPriority = reminder?.priority ?? '普通'; 

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(reminder == null ? 'リマインダーを追加' : 'リマインダーを編集'),
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
                        decoration: const InputDecoration(labelText: 'タイトル'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'タイトルを入力してください' : null,
                      ),
                      ListTile(
                        title: Text(DateFormat('yyyy/MM/dd').format(selectedDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() => selectedDate = picked);
                          }
                        },
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
                        value: selectedPriority, // ✅ valueをselectedPriorityと紐付け
                        decoration: const InputDecoration(labelText: '優先度'),
                        items: ['低', '普通', '高']
                            .map((priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedPriority = value; // ✅ 変更を確実に反映
                            });
                          }
                        },
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
                  final newReminder = Reminder(
                    name: nameController.text,
                    date: selectedDate,
                    time: selectedTime,
                    priority: selectedPriority, // ✅ 修正: priority の変更を確実に適用
                    repeat: reminder?.repeat ?? 'なし', // ✅ repeatも考慮
                  );

                  if (reminder == null) {
                    await ReminderDatabase.instance.insertReminder(newReminder);
                  } else {
                    // ✅ 既存のIDを維持したまま更新
                    final updatedReminder = Reminder(
                      id: reminder.id,
                      name: newReminder.name,
                      date: newReminder.date,
                      time: newReminder.time,
                      priority: newReminder.priority,
                      repeat: newReminder.repeat,
                    );
                    await ReminderDatabase.instance.updateReminder(updatedReminder);
                  }

                  _loadReminders();

                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    ),
  );
}
}