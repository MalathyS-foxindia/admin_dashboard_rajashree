// lib/main.dart

import 'package:admin_dashboard_rajshree/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/order_provider.dart';

import 'providers/product_provider.dart';
import 'screens/orders_screen.dart';
import  'screens/products_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env'); // Load environment variables
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
        // This is where you create and provide your ProductProvider
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider(Supabase.instance.client)),
        // Add any other providers your app needs here
      ],
      child: MaterialApp(
        title: 'Rajshree Fashions Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}