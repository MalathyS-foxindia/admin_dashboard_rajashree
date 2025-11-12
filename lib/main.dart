import 'dart:async';
import 'dart:convert';
import 'package:admin_dashboard_rajashree/providers/returns_provider.dart';
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

// Config
import 'package:admin_dashboard_rajashree/models/Env.dart';

/// Supabase configuration
const String supabaseUrl = Env.supabaseUrl;
const String supabaseAnonKey = Env.anonKey;
const Color primaryBlue = Color(0xFF4A90E2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );

  runApp(const MyApp());
}

/// 🟢 CHANGED: Converted to StatefulWidget to handle Supabase deep link recovery
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showResetScreen =
      false; // 🟢 NEW: For showing reset screen on deep link

  @override
  void initState() {
    super.initState();

    // 🟢 Detect password recovery events from Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('🟢 Password recovery event detected from Supabase');
        setState(() => _showResetScreen = true);
      }
    });

    // 🟢 Detect direct deep link on web (hash URL)
    final uri = Uri.base;
    if (uri.fragment.contains('type=recovery') ||
        uri.fragment.contains('access_token')) {
      debugPrint('🟢 Password recovery detected in URL fragment');
      _showResetScreen = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

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
        ChangeNotifierProvider(create: (_) => ReturnsProvider()),
      ],
      child: MaterialApp(
        title: 'Rajashree Fashions Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
          useMaterial3: true,
        ),

        // 🟢 If deep link detected, show reset password screen first
        home: _showResetScreen
            ? const ResetPasswordScreen()
            : const AuthWrapper(),

        routes: {'/forgot-password': (context) => const ForgotPasswordScreen()},

        onGenerateRoute: (settings) {
          if (settings.name == '/reset-password') {
            return MaterialPageRoute(
              builder: (_) => const ResetPasswordScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}

/// ✅ Handles Supabase session restore and redirects appropriately
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Session? _session;
  String? _cachedRole;
  bool _loading = true;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _loadCachedDataAndInit();
  }

  Future<void> _loadCachedDataAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedRole = prefs.getString('cached_role');

    final accessToken = prefs.getString('access_token');
    if (accessToken != null) {
      try {
        await Supabase.instance.client.auth.setSession(accessToken);
        _session = Supabase.instance.client.auth.currentSession;
      } catch (e) {
        debugPrint("Session restore failed: $e");
      }
    }

    // 🔄 Listen to auth changes
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      final event = data.event;

      final prefs = await SharedPreferences.getInstance();

      if (event == AuthChangeEvent.signedIn && session != null) {
        await prefs.setString('access_token', session.accessToken);
      } else if (event == AuthChangeEvent.signedOut) {
        await prefs.remove('access_token');
        await prefs.remove('cached_role');
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ Show dashboard if we already have cached role and valid session
    if (_session != null && _cachedRole != null) {
      return DashboardScreen(role: _cachedRole!);
    }

    // Otherwise, fetch role dynamically
    if (_session != null) {
      return FutureBuilder<String>(
        future: _fetchAndCacheRole(_session!),
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

    // 🧑‍💻 Default: Login screen
    return const LoginScreen();
  }

  Future<String> _fetchAndCacheRole(Session session) async {
    final email = session.user?.email;
    if (email == null) return "Executive";

    final roleResponse = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('email', email)
        .maybeSingle();

    final role = roleResponse?['role'] ?? "Executive";

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_role', role);

    return role;
  }
}
