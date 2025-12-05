import 'package:first_flutter/data/auth_service.dart';
import 'package:first_flutter/views/admin_widget_tree.dart';
import 'package:first_flutter/views/police_widget_tree.dart';
import 'package:first_flutter/views/viewer_widget_tree.dart';
import 'package:first_flutter/views/widgets/hero_widget.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FractionallySizedBox(
              widthFactor: width > 1000 ? 0.5 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroWidget(title: widget.title),
                  const SizedBox(height: 20),

                  // Email
                  TextField(
                    controller: controllerEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password
                  TextField(
                    controller: controllerPassword,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      hintText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _isObscure = !_isObscure);
                        },
                        icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button Login
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : onPressedLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.title),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------
  // Xử lý login
  // -------------------------
  void onPressedLogin() async {
    final email = controllerEmail.text.trim();
    final pass = controllerPassword.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userInfo = await AuthService.login(email, pass);

    setState(() => _isLoading = false);

    if (userInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong email or password")),
      );
      return;
    }

    // Chọn trang theo role
    Widget nextPage;
    switch (userInfo.role) {
      case "viewer":
        nextPage = ViewerWidgetTree();
        break;
      case "police":
        nextPage = PoliceWidgetTree();
        break;
      case "admin":
        nextPage = AdminWidgetTree();
        break;
      default:
        nextPage = ViewerWidgetTree();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
      (route) => false,
    );
  }
}
