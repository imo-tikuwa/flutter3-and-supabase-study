import 'package:flutter3_and_supabase_study/importer.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ログイン'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                ElevatedButton(
                  child: isLoading ? const CircularProgressIndicator() : const Text('Login'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final response = await _loginWithPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      if (response == null || response.user == null || !mounted) {
                        return;
                      }
                      // 以下のpopはmy_home.dart側でログイン状態を見た画面遷移を行っているため不要（というか画面が真っ暗になる原因になるみたい？pushReplacement→popの順番で呼ばれてしまっている？）
                      // Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<AuthResponse?> _loginWithPassword({
    required String email,
    required String password,
  }) async {
    // Show a progress indicator while the login is in progress
    setState(() {
      isLoading = true;
    });
    try {
      // Call the Supabase auth.signInWithPassword method
      return await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      // Show a snackbar with the error message if the login fails
      showErrorSnackBar(context, message: error.message);
    } on Exception catch (e) {
      // Show a snackbar with the error message if the login fails
      showErrorSnackBar(context, message: e.toString());
    } finally {
      // Hide the progress indicator
      setState(() {
        isLoading = false;
      });
    }
    // Return null if the login fails
    return null;
  }
}