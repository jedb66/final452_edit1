import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'todo_list_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  _EmailLoginScreenState createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLoggedInEmail();
  }

  void _loadLoggedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('logged_in_email');
    if (email != null) {
      _emailController.text = email;
    }
  }

  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegExp.hasMatch(email);
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final prefs = await SharedPreferences.getInstance();
      final userDataRaw = prefs.getString('user_credentials') ?? '{}';
      final Map<String, String> users =
          Map<String, String>.from(json.decode(userDataRaw));

      // ✅ เช็กว่าเป็น admin แต่รหัสผ่านไม่ถูกต้อง
      if (email == 'admin@gmail.com' && password != '123456789') {
        _showError('Admin password incorrect');
        return;
      }

      if (users.containsKey(email)) {
        if (users[email] == password) {
          await prefs.setString('logged_in_email', email);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TodoListScreen(userEmail: email),
            ),
          );
        } else {
          _showError('Incorrect password');
        }
      } else {
        // ✅ ไม่อนุญาตให้สมัครเป็น admin
        if (email == 'admin@gmail.com') {
          _showError('Admin account cannot be registered');
          return;
        }

        // สมัครผู้ใช้ใหม่
        users[email] = password;
        await prefs.setString('user_credentials', json.encode(users));
        await prefs.setString('logged_in_email', email);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TodoListScreen(userEmail: email),
          ),
        );
      }
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_email');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out')),
    );
    _emailController.clear();
    _passwordController.clear();
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login/Register'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Login or Register with Email',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !isValidEmail(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 24.0,
                  ),
                  child: Text('Continue', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
