import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_dashboard_rajashree/screens/dashboard_screen.dart';
import 'package:admin_dashboard_rajashree/screens/forgot_password_screen.dart';

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
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      if (session != null) {
        // Save session in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('supabase_session', jsonEncode(session.toJson()));

        // Fetch user role
        final roleResponse = await supabase
            .from('users')
            .select('role')
            .eq('email', email)
            .maybeSingle();

        final String role = roleResponse?['role'] ?? "Executive";
        print('User role: $role');

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen(role: role)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Invalid email or password')),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
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
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const ForgotPasswordScreen()),
                            );
                          },
                          child: const Text("Forgot Password?"),
                        ),
                      ],
                    ),
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