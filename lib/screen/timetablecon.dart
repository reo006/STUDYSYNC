import 'package:flutter/material.dart';

class TimetableConScreen extends StatefulWidget {
  final List<Map<String, String>> existingTemplates;

  const TimetableConScreen({super.key, required this.existingTemplates}); // ✅ 修正

  @override
  TimetableConScreenState createState() => TimetableConScreenState();
}

class TimetableConScreenState extends State<TimetableConScreen> {
  late List<Map<String, String>> templates;
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    templates = List.from(widget.existingTemplates); // ✅ 既存テンプレートをコピー
  }

  void _addTemplate() {
    if (subjectController.text.isNotEmpty && roomController.text.isNotEmpty) {
      setState(() {
        templates.add({
          'subject': subjectController.text,
          'room': roomController.text,
        });
        subjectController.clear();
        roomController.clear();
      });
    }
  }

  void _removeTemplate(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: const Text('本当に削除しますか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('削除', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  templates.removeAt(index);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('時間割管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, templates); // ✅ 変更を保存して戻る
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, templates); // ✅ 変更を反映して戻る
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: '教科名',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roomController,
              decoration: InputDecoration(
                labelText: '教室名',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addTemplate,
              child: const Text('追加'),
            ),
            const SizedBox(height: 20),
            const Text(
              "登録済みテンプレート",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: templates.isEmpty
                  ? const Center(child: Text("登録されたテンプレートはありません"))
                  : ListView.builder(
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('${templates[index]['subject']}'),
                            subtitle: Text('教室: ${templates[index]['room']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeTemplate(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}