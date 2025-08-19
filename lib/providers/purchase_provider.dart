import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/purchase_model.dart';
import '../models/vendor_model.dart';


class PurchaseProvider with ChangeNotifier {
  final String _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final String _serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE'] ?? '';

  PurchaseProvider() {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      debugPrint('⚠️ Supabase URL or keys are missing in .env');
    }
  }

  /// State
  bool isLoading = false;
  String? error;


  // Fetches data from the Supabase Edge Function.
  Future<void> _fetchPurchases() async {
   
    // Replace this with your deployed Edge Function URL.
  const String edgeFunctionUrl = 'YOUR_SUPABASE_EDGE_FUNCTION_URL_HERE';

    try {
      final response = await http.get(Uri.parse(edgeFunctionUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Purchase> purchases = data.map((item) => Purchase.fromJson(item)).toList();
      } else {
        error = 'Failed to load purchases: ${response.statusCode}';
      }
    } catch (e) {
     
    } finally {
      
    }
  }
}