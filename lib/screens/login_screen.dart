import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_dashboard_rajashree/screens/dashboard_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:admin_dashboard_rajashree/screens/forgot_password_screen.dart';
import "../models/Env.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email & password')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final supabaseUrl = Env.supabaseUrl;
      final anonKey = Env.anonKey;

      print('🔵 [LOGIN] URL: $supabaseUrl/rest/v1/users?email=eq.$email');

      final response = await http.get(
        Uri.parse(
            '$supabaseUrl/rest/v1/users?email=eq.$email&select=email,password,role'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      );

      print('🟢 [LOGIN] Status: ${response.statusCode}');
      print('🟢 [LOGIN] Content-Type: ${response.headers['content-type']}');
      print('🟢 [LOGIN] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('🟢 [LOGIN] Parsed data: $data');

        if (data.isNotEmpty && data.first['password'] == pass) {
          final String role = data.first['role'] ?? "Executive";
          print('✅ [LOGIN] Success! Role: $role');

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DashboardScreen(role: role)),
          );
        } else {
          print('🔴 [LOGIN] Invalid credentials');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Invalid email or password')),
          );
        }
      } else {
        print('🔴 [LOGIN] Failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Invalid email or password')),
        );
      }
    } catch (e) {
      print('🔴 [LOGIN] Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // Restore previous session
 Future<void> _restoreSession() async {
  final prefs = await SharedPreferences.getInstance();
  final savedSession = prefs.getString('supabase_session');
  if (savedSession == null) return;

  try {
    final sessionMap = jsonDecode(savedSession);
    final session = Session.fromJson(sessionMap);

    if (session != null) {
      // ✅ Set session with the full Session object
     final accessToken = prefs.getString('access_token');
if (accessToken != null) {
  await Supabase.instance.client.auth.setSession(accessToken);
}
      // Fetch role safely
      final userEmail = session!.user?.email;
      String role = "Executive";

      if (userEmail != null) {
        final roleResponse = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('email', userEmail)
            .maybeSingle();
        role = roleResponse?['role'] ?? "Executive";
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(role: role)),
      );
    }
  } catch (e) {
    print("Session restore failed: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg4.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/logo.png',
                            height: 56, width: 56, fit: BoxFit.contain),
                        const SizedBox(height: 10),
                        Text(
                          'Rajashree Fashion Admin',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
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
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.login),
                            label: const Text('Login'),
                            onPressed: _loading ? null : _login,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
