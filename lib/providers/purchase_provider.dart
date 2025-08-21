import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/purchase_model.dart';

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
  List<Purchase> _purchases = [];
  List<Purchase> get purchases => _purchases;

  bool isLoading = false;
  String errorMessage = '';

  /// Fetches purchase data from the Supabase Edge Function
  Future<void> fetchPurchases() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      const url =
          'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/getpurchasedetails';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['purchases'] != null) {
          _purchases = List<Purchase>.from(
            data['purchases'].map((e) => Purchase.fromJson(e)),
          );
        }
      } else {
        errorMessage = 'Error fetching purchases: ${response.body}';
        debugPrint(errorMessage);
      }
    } catch (e) {
      errorMessage = 'Unexpected error: $e';
      debugPrint(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
