class TodoActivity {
  final String title;
  final String date;
  final String emoji;
  bool done;

  TodoActivity({
    required this.title,
    required this.date,
    required this.emoji,
    this.done = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'emoji': emoji,
        'done': done,
      };

  factory TodoActivity.fromJson(Map<String, dynamic> json) => TodoActivity(
        title: json['title'],
        date: json['date'],
        emoji: json['emoji'],
        done: json['done'] ?? false,
      );
}
