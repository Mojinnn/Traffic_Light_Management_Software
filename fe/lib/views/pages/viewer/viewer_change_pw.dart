import 'package:flutter/material.dart';
import 'package:first_flutter/data/auth_service.dart';// <-- Thêm service gọi API

class ChangePassword extends StatefulWidget {
  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool _isObscure = true;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController controllerOldPassword;
  late TextEditingController controllerNewPassword;
  late TextEditingController controllerRetypePassword;

  @override
  void initState() {
    super.initState();
    controllerOldPassword = TextEditingController();
    controllerNewPassword = TextEditingController();
    controllerRetypePassword = TextEditingController();
  }

  @override
  void dispose() {
    controllerOldPassword.dispose();
    controllerNewPassword.dispose();
    controllerRetypePassword.dispose();
    super.dispose();
  }

  // Validate mật khẩu cũ
  String? validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Vui lòng nhập mật khẩu cũ";
    }
    return null;
  }

  // Validate mật khẩu mới
  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Vui lòng nhập mật khẩu mới";
    }
    if (value.length < 6) {
      return "Mật khẩu phải ít nhất 6 ký tự";
    }
    return null;
  }

  // Validate nhập lại mật khẩu
  String? validateRetypePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Vui lòng nhập lại mật khẩu";
    }
    if (value != controllerNewPassword.text) {
      return "Mật khẩu không khớp";
    }
    return null;
  }

  // API đổi mật khẩu
  Future<void> onChangePassword() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator()),
      );

      try {
        await AuthService.changePassword(
          oldPassword: controllerOldPassword.text,
          newPassword: controllerNewPassword.text,
          retypePassword: controllerRetypePassword.text,
        );

        Navigator.pop(context); // đóng loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đổi mật khẩu thành công!"), backgroundColor: Colors.green),
        );

        Navigator.pop(context); // quay lại trang trước
      } catch (e) {
        Navigator.pop(context); // đóng loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi đổi mật khẩu: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: FractionallySizedBox(
              widthFactor: mediaWidth > 1000 ? 0.5 : 1,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Old Password
                    TextFormField(
                      controller: controllerOldPassword,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        hintText: 'Old Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _isObscure = !_isObscure);
                          },
                        ),
                      ),
                      validator: validateOldPassword,
                    ),
                    SizedBox(height: 10),

                    // New Password
                    TextFormField(
                      controller: controllerNewPassword,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        hintText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _isObscure = !_isObscure);
                          },
                        ),
                      ),
                      validator: validateNewPassword,
                    ),
                    SizedBox(height: 10),

                    // Retype New Password
                    TextFormField(
                      controller: controllerRetypePassword,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        hintText: 'Retype Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _isObscure = !_isObscure);
                          },
                        ),
                      ),
                      validator: validateRetypePassword,
                    ),
                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: onChangePassword,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text("Đổi mật khẩu"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
