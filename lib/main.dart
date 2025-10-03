import 'package:admin_dashboard_rajashree/providers/queries_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers
import 'package:admin_dashboard_rajashree/providers/combo_provider.dart';
import 'package:admin_dashboard_rajashree/providers/customer_provider.dart';
import 'package:admin_dashboard_rajashree/providers/purchase_provider.dart';
import 'package:admin_dashboard_rajashree/providers/shipment_provider.dart';
import 'package:admin_dashboard_rajashree/providers/vendor_provider.dart';
import 'package:admin_dashboard_rajashree/providers/order_provider.dart';
import 'package:admin_dashboard_rajashree/providers/product_provider.dart';

// Screens
import 'package:admin_dashboard_rajashree/screens/login_screen.dart';
import 'package:admin_dashboard_rajashree/screens/forgot_password_screen.dart';
import 'package:admin_dashboard_rajashree/screens/reset_password_screen.dart';
import 'package:admin_dashboard_rajashree/screens/dashboard_screen.dart';
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

/// AuthWrapper automatically decides which page to show based on auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Session? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    // Try to restore session from storage
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _session = session;
      _loading = false;
    });

    // Keep listening to sign-in / sign-out events
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        _session = data.session;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session != null) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
