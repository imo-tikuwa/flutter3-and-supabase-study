import 'package:flutter3_and_supabase_study/importer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final StreamSubscription<AuthState> _authSubscription;

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

    super.initState();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ダッシュボード'),
        actions: [
          // ログアウト
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => {
              supabase.auth.signOut()
            },
          )
        ],
      ),
      body: const Center(
        child: Text('ログイン後TOPページ'),
      ),
    );
  }
}