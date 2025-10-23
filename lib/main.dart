import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import 'package:admin_dashboard_rajashree/providers/combo_provider.dart';
import 'package:admin_dashboard_rajashree/providers/customer_provider.dart';
import 'package:admin_dashboard_rajashree/providers/order_provider.dart';
import 'package:admin_dashboard_rajashree/providers/product_provider.dart';
import 'package:admin_dashboard_rajashree/providers/purchase_provider.dart';
import 'package:admin_dashboard_rajashree/providers/shipment_provider.dart';
import 'package:admin_dashboard_rajashree/providers/vendor_provider.dart';
import 'package:admin_dashboard_rajashree/providers/queries_provider.dart';

// Screens
import 'package:admin_dashboard_rajashree/screens/login_screen.dart';
import 'package:admin_dashboard_rajashree/screens/dashboard_screen.dart';
import 'package:admin_dashboard_rajashree/screens/forgot_password_screen.dart';
import 'package:admin_dashboard_rajashree/screens/reset_password_screen.dart';
import 'package:admin_dashboard_rajashree/models/Env.dart';

const String supabaseUrl = Env.supabaseUrl;
const String supabaseAnonKey = Env.anonKey;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );

  runApp(const MyApp());
}

const Color primaryBlue = Color(0xFF4A90E2);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider(supabase)),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => ComboProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => QueriesProvider()),
      ],
      child: MaterialApp(
        title: 'Rajashree Fashions Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/forgot-password': (context) => const ForgotPasswordScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/reset-password') {
            final args = settings.arguments as Map<String, dynamic>?;
            final email = args?['email'] as String?;
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: email),
            );
          }
          return null;
        },
      ),
    );
  }
}

/// ✅ AuthWrapper Widget to handle session & role
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Session? _session;
  bool _loading = true;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _initializeSupabaseSession();
  }

  Future<void> _initializeSupabaseSession() async {
    final supabase = Supabase.instance.client;

    // Restore session from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken != null) {
      try {
        await supabase.auth.setSession(accessToken);
        _session = supabase.auth.currentSession;
      } catch (_) {}
    }

    // Listen to auth state changes
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', session.accessToken);
      }

      if (event == AuthChangeEvent.signedOut) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
      }

      if (!mounted) return;
      setState(() => _session = session);
    });

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session != null) {
      return FutureBuilder<String>(
        future: _fetchRole(_session!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final role = snapshot.data!;
          return DashboardScreen(role: role);
        },
      );
    }

    return const LoginScreen();
  }

  Future<String> _fetchRole(Session session) async {
    final userEmail = session.user?.email;
    if (userEmail == null) return "Executive";

    final roleResponse = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('email', userEmail)
        .maybeSingle();

    return roleResponse?['role'] ?? "Executive";
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (!mounted) return;
    setState(() => _session = null);
  }
}
