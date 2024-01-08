/// supabaseのtasksテーブル1件に相当するモデル
class Task {
  Task({
    required this.id,
    required this.title,
    required this.completed,
  });

  int? id;
  String? title;
  bool completed;

  Task.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      title = map['title'],
      completed = map['completed'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }
}