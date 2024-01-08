import 'package:flutter3_and_supabase_study/importer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late User? _user;
  late List<Task> _tasks;
  late final StreamSubscription<AuthState> _authSubscription;
  bool isLoading = false;

  @override
  void initState() {
    // Supabaseの認証状態が変わった時に呼ばれるwatchみたいなやつ
    // ウィジェット内のサインアウトボタン押下後、ログイン状態がサインアウトであることが確認出来たらログイン画面に遷移
    // ※本当はサインアウト時の挙動もmy_home.dart側に押し込めたかったけどうまく行かなかった。。
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage()
          )
        );
      }
    });

    // タスクの一覧を取得
    _fetchTasks();

    super.initState();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: const Text('タスク一覧'),
        actions: [
          // ログアウト
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          )
        ],
      ),
      // タスク新規登録
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Task task = Task(id: null, title: null, completed: false);
          _showEditDialog(context, task, (editedText) async {
            task.title = editedText;
            Task createdTask = await _createOrUpdateTask(task);
            setState(() {
              _tasks.add(createdTask);
            });
          });
        },
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.inversePrimary),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : Container(
        margin: const EdgeInsets.only(top: 10, right: 10, bottom: 5, left: 10),
        child: Column(
          children: [
            const Text('選択でタスクの内容を編集できます'),
            const Text('長押しでタスクを入れ替えられます'),
            const SizedBox(height: 12.0),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  Task task = _tasks[index];
                  return GestureDetector(
                    key: Key('task$index'),
                    onTap: () {
                      _showEditDialog(context, task, (editedText) {
                        setState(() {
                          task.title = editedText;
                          _createOrUpdateTask(task);
                        });
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: index.isOdd ? colorScheme.primary.withOpacity(0.1) : colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.title!,
                            ),
                          ),
                          Row(
                            children: [
                              Switch(
                                value: task.completed,
                                onChanged: (newValue) {
                                  setState(() {
                                    task.completed = newValue;
                                    _createOrUpdateTask(task);
                                  });
                                },
                              ),
                              IconButton(
                                onPressed: () => _showDeleteConfirmDialog(context, task),
                                icon: const Icon(Icons.delete),
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: colorScheme.error,
                                ),
                              )
                            ]
                          )
                        ],
                      ),
                    ),
                  );
                },
                onReorder: (int oldIndex, int newIndex) {
                  if (oldIndex < newIndex) {
                    // removing the item at oldIndex will shorten the list by 1.
                    // 参考：https://tech-rise.net/flutter-about-reorderable-list-view/
                    newIndex -= 1;
                  }

                  if (oldIndex != newIndex) {
                    setState(() {
                      final Task item = _tasks.removeAt(oldIndex);
                      _tasks.insert(newIndex, item);
                      _reorderTasks(_tasks);
                    });
                  }

                },
              )
            )
          ],
        )
      )
    );
  }

  /// タスクの一覧を取得
  Future _fetchTasks() async {
    setState(() {
      isLoading = true;
    });

    // ユーザーを取得
    _user = supabase.auth.currentUser;

    // タスクを取得
    final data = await supabase.from("tasks")
    .select("id, title, completed")
    .eq("user", _user!.id)
    .order("sort_num", ascending: true);

    // Taskモデルのリストに持ち替え
    _tasks = data.map((taskData) => Task.fromMap(taskData)).toList();

    setState(() {
      isLoading = false;
    });
  }

  /// タスクの登録or編集ダイアログを表示
  Future<void> _showEditDialog(BuildContext context, Task task, Function(String) onSave) async {
    final TextEditingController textEditingController = TextEditingController(text: task.title);
    bool isSaveButtonEnabled = task.title?.isNotEmpty ?? false;
    bool isCreate = task.id == null;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('タスクを${isCreate ? '登録' : '編集'}'),
              content: TextFormField(
                controller: textEditingController,
                onChanged: (value) {
                  setState(() {
                    isSaveButtonEnabled = value.isNotEmpty;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  onPressed: !isSaveButtonEnabled ? null : () async {
                    String editedText = textEditingController.text;
                    onSave(editedText);
                    Navigator.of(context).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  /// 1件のタスクを登録or更新
  Future<Task> _createOrUpdateTask(Task task) async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isCreate = task.id == null;
    late Task upsertedTask;

    try {
      late List<Map<String, dynamic>> result;
      if (isCreate) {
        result = await supabase.from('tasks').insert({
          'title': task.title,
          'completed': false
        }).select();
      } else {
        result = await supabase.from('tasks').upsert(task.toMap()).select();
      }
      if (result.isNotEmpty) {
        Fluttertoast.showToast(
          msg: 'タスクを${isCreate ? '登録' : '更新'}しました',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: colorScheme.primary.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0
        );
        upsertedTask = Task.fromMap(result.first);
      }
    } on PostgrestException catch (error) {
      debugPrint(error.message);
    } on Exception catch (e) {
      debugPrint(e.toString());
    }

    return upsertedTask;
  }

  /// タスクの並びを更新
  Future<void> _reorderTasks(List<Task> tasks) async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    try {
      final List<Map<String, dynamic>> upsertData = tasks.asMap().entries.map((entry) {
        return {
          'id': entry.value.id,
          'completed': entry.value.completed,
          'sort_num': entry.key + 1,
        };
      }).toList();
      final result = await supabase.from('tasks').upsert(upsertData).select();
      if (result.isNotEmpty) {
        Fluttertoast.showToast(
          msg: 'タスクの並びを更新しました',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: colorScheme.primary.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    } on PostgrestException catch (error) {
      debugPrint(error.message);
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
  /// タスクの削除確認ダイアログを表示
  Future<void> _showDeleteConfirmDialog(BuildContext context, Task task) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('タスクを削除'),
              content: const Text('タスクを削除します。よろしいですか？'),
              actions: <Widget>[
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  onPressed: () {
                    _deleteTask(task).then((value) => _fetchTasks().then((value) => Navigator.of(context).pop()));
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  /// 1件のタスクを削除する
  Future<void> _deleteTask(Task task) async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    try {
      final result = await supabase.from('tasks').delete().match({'id': task.id}).select();
      if (result.isNotEmpty) {
        Fluttertoast.showToast(
          msg: 'タスクを削除しました',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: colorScheme.primary.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    } on PostgrestException catch (error) {
      debugPrint(error.message);
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}