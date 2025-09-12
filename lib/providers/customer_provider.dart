// lib/providers/customer_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/customer_model.dart';

class CustomerProvider with ChangeNotifier {
  final String _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  bool isLoading = false;
  String errorMessage = '';

  Map<String, String> get _headers => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  Future<void> fetchCustomers() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final url = '$_supabaseUrl/rest/v1/customers?select=*'
          '&order=created_at.desc'; // newest first
      final res = await http.get(Uri.parse(url), headers: _headers);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        _customers = list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        errorMessage = 'Failed to fetch customers: ${res.body}';
      }
    } catch (e) {
      errorMessage = 'Unexpected error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
