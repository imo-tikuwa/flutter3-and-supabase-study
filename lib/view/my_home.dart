import 'package:flutter3_and_supabase_study/importer.dart';

final supabase = Supabase.instance.client;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late User? _user;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    // アプリ起動時にレンダリングするウィジェットを切り替えるためのユーザー情報
    _user = supabase.auth.currentUser;

    // Supabaseの認証状態が変わった時に呼ばれるwatchみたいなやつ
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardPage()
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
    return _user == null
      ? const LoginPage()
      : const DashboardPage();
  }
}