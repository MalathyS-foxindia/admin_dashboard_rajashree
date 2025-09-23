
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env'); // Load env vars

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

const Color primaryBlue = Color(0xFF4A90E2);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(
            create: (_) => OrderProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider( create: (_) => ShipmentProvider()),
        ChangeNotifierProvider( create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => ComboProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),

      ],
      child: MaterialApp(
        title: 'Rajashree Fashions Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
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
