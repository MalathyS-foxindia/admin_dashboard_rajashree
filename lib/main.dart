import 'package:admin_dashboard_rajshree/providers/purchase_provider.dart';
import 'package:admin_dashboard_rajshree/providers/shipment_provider.dart';
import 'package:admin_dashboard_rajshree/providers/vendor_provider.dart';
import 'package:admin_dashboard_rajshree/screens/login_screen.dart';
import 'package:admin_dashboard_rajshree/screens/forgot_password_screen.dart';
import 'package:admin_dashboard_rajshree/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/order_provider.dart';
import 'providers/product_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env'); // Load env vars

  // ✅ Initialize Supabase before creating any providers
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

const Color primaryBlue = Color(0xFF7E57C2);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
      ],
      child: MaterialApp(
        title: 'Rajshree Fashions Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
          useMaterial3: true,
        ),

        // ✅ Define named routes here
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(email: '',),
        },
      ),
    );
  }
}
