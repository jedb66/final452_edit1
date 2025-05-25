import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/todo_activity.dart';
import 'email_login_screen.dart';

class TodoListScreen extends StatefulWidget {
  final String userEmail;
  final int userId;
  final List? initialTodos;
  const TodoListScreen({
    super.key,
    required this.userEmail,
    required this.userId,
    this.initialTodos,
  });
  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<TodoActivity> _activities = [];
  final _titleController = TextEditingController();
  final _emojis = ['😊', '😢', '😡', '😴', '🤩', '😌', '😎', '🥳', '🤔', '😭'];
  String _emoji = '😊';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialTodos != null) {
      _activities = widget.initialTodos!
          .map((e) => TodoActivity.fromJson(e))
          .toList()
          .cast<TodoActivity>();
      setState(() {});
    } else {
      _fetchTodos();
    }
  }

  Future<void> _fetchTodos() async {
    final url = Uri.parse('http://localhost:3000/users/${widget.userId}/todos');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _activities = data
              .map((e) => TodoActivity.fromJson(e))
              .toList()
              .cast<TodoActivity>();
        });
      } else {
        setState(() => _activities = []);
      }
    } catch (e) {
      setState(() => _activities = []);
    }
  }

  void _add() {
    if (_titleController.text.trim().isEmpty) return;
    setState(() {
      _activities.add(TodoActivity(
        title: _titleController.text.trim(),
        date: _date.toIso8601String().split('T').first,
        emoji: _emoji,
      ));
      _titleController.clear();
      _date = DateTime.now();
      _emoji = '😊';
    });
  }

  void _toggle(int i, bool? v) {
    if (v == null) return;
    setState(() => _activities[i].done = v);
  }

  String _formatDate(String d) {
    final dt = DateTime.tryParse(d);
    return dt != null
        ? "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}"
        : d;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Widget _buildInputRow() {
    return Row(children: [
      Expanded(
        flex: 3,
        child: GestureDetector(
          onTap: _pickDate,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder()),
              controller: TextEditingController(
                  text: _formatDate(_date.toIso8601String().split('T').first)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 4,
        child: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
              labelText: 'Title', border: OutlineInputBorder()),
          maxLength: 50,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: DropdownButtonFormField<String>(
          value: _emoji,
          decoration: const InputDecoration(
              labelText: 'Mood', border: OutlineInputBorder()),
          items: _emojis
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 22))))
              .toList(),
          onChanged: (v) => v != null ? setState(() => _emoji = v) : null,
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton(onPressed: _add, child: const Text('+ Save')),
    ]);
  }

  Widget _buildList() {
    if (_activities.isEmpty) {
      return const Center(
          child: Text('No activities yet. Add one above!',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _activities.length,
      itemBuilder: (_, i) {
        final a = _activities[i];
        return Card(
          color: a.done ? Colors.green[100] : null,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Checkbox(value: a.done, onChanged: (v) => _toggle(i, v)),
            title: Text('${a.emoji}  ${a.title}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: a.done ? TextDecoration.lineThrough : null)),
            subtitle: Text('Date: ${_formatDate(a.date)}'),
          ),
        );
      },
    );
  }

  void _logout() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => EmailLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo for ${widget.userEmail}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildInputRow(),
          const SizedBox(height: 16),
          Expanded(child: _buildList()),
        ]),
      ),
    );
  }
}
