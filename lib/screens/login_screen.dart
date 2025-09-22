import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:admin_dashboard_rajashree/screens/dashboard_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:admin_dashboard_rajashree/screens/forgot_password_screen.dart'; // Import the forgot password screen

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

  Future<void> _login() async {
    final email = _email.text.trim();
    final pass = _password.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email & password')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;

      final response = await http.get(
        Uri.parse(
            '$supabaseUrl/rest/v1/users?email=eq.$email&select=email,password,role'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty && data.first['password'] == pass) {
         final String role = data.first['role'] ?? "Executive";

          // ✅ Success → Go to Dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DashboardScreen(role: role)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Invalid email or password')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'images/login_bg4.png', // ✅ You need to add this image to your assets folder
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay to improve readability
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
          // Login Form
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 20),
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
                              colors: [Color(0xFF7E57C2), Color(0xFF4A90E2)]),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('images/logo.png',
                                height: 56, width: 56, fit: BoxFit.contain),
                            const SizedBox(height: 10),
                            Text('Rajashree Fashion Admin',
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
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email)),
                            ),
                            const SizedBox(height: 12),
                            /*TextField(
                              controller: _password,
                              obscureText: true,
                              decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock)),
                            ),*/

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
                                    : const Icon(Icons.login),
                                label: const Text('Login'),
                                onPressed: _loading ? null : _login,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text("Forgot Password?"),
                            ),
                          ],
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


/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:admin_dashboard_rajashree/screens/dashboard_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:admin_dashboard_rajashree/screens/forgot_password_screen.dart'; // Import the forgot password screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final email = _email.text.trim();
    final pass = _password.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email & password')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;

      final response = await http.get(
        Uri.parse(
            '$supabaseUrl/rest/v1/users?email=eq.$email&select=email,password'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty && data.first['password'] == pass) {
          // ✅ Success → Go to Dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Invalid email or password')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'images/login_bg3.jpg', // ✅ You need to add this image to your assets folder
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay to improve readability with a brighter look
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2), // Reduced opacity
                    Colors.black.withOpacity(0.4), // Reduced opacity
                  ],
                ),
              ),
            ),
          ),
          // Login Form
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container( // Using Container instead of Card for a borderless look
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85), // Semi-transparent white background
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('images/logo.png',
                          height: 56, width: 56, fit: BoxFit.contain),
                      const SizedBox(height: 10),
                      Text('Rajashree Fashion Admin',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: Colors.black87)), // Changed text color to black
                      const SizedBox(height: 18),
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
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Password',
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
                              : const Icon(Icons.login),
                          label: const Text('Login'),
                          onPressed: _loading ? null : _login,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
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
        ],
      ),
    );
  }
}*/

