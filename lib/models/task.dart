/// supabaseのtasksテーブル1件に相当するモデル
class Task {
  /// toMapWithoutNullValuesとの兼ね合いでrequiredをつけないようにしてみる
  Task({
    this.id,
    this.title,
    this.completed,
  });

  int? id;
  String? title;
  bool? completed;

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

  /// nullのプロパティを除外したマップを返す
  /// CreateとUpdateを1本化した_createOrUpdateTaskメソッド用
  Map<String, dynamic> toMapWithoutNullValues() {
    Map<String, dynamic> map = toMap();
    map.removeWhere((key, value) => value == null);
    return map;
  }
}