// lib/screens/forgot_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _newPwdCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    final newPwd = _newPwdCtrl.text.trim();

    if (email.isEmpty || newPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email & new password")),
      );
      return;
    }
    debugPrint("📩 ForgotPassword submitted: $email");
    Navigator.pushNamed(context, '/reset-password', arguments: {'email': email});

    setState(() => _loading = true);

    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;

      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/users?email=eq.$email'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': newPwd}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Password updated! Please login.")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: const BoxDecoration(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                          gradient: LinearGradient(
                            colors: [Color(0xFF7E57C2), Color(0xFF4A90E2)],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('images/logo.png',
                                height: 56,
                                width: 56,
                                fit: BoxFit.contain),
                            const SizedBox(height: 10),
                            Text('Reset Password',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPwdCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                  labelText: 'New Password',
                                  prefixIcon: Icon(Icons.lock)),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.tonalIcon(
                                icon: _loading
                                    ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                    : const Icon(Icons.refresh),
                                label: const Text('Reset Password'),
                                onPressed: _loading ? null : _resetPassword,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
