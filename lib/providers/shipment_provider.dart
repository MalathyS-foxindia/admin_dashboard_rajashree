// lib/providers/shipment_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/shipment.dart';

class ShipmentProvider extends ChangeNotifier {
  List<Shipment> _shipments = [];
  bool _isLoading = false;

  List<Shipment> get shipments => _shipments;
  bool get isLoading => _isLoading;

  /// Fetches shipments from Supabase Edge Function / REST API
  Future<void> fetchShipments() async {
    // Only set loading state if not already loading to avoid unnecessary rebuilds
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('⏳ Fetching shipments from API...');
      }

      final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
      final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        if (kDebugMode) {
          print('❌ SUPABASE_URL or SUPABASE_ANON_KEY is not defined in the .env file.');
        }
        throw Exception("Environment variables not found.");
      }

      final url = "$supabaseUrl/rest/v1/shipment_tracking?select=*";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "apikey": supabaseAnonKey,
          "Authorization": "Bearer $supabaseAnonKey",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _shipments = data.map((json) => Shipment.fromJson(json)).toList();
        if (kDebugMode) {
          print('✅ Fetched ${_shipments.length} shipments successfully.');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch shipments: ${response.statusCode}');
          print('❌ Response body: ${response.body}');
        }
        _shipments = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching shipments: $e");
      }
      _shipments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Wrapper for pull-to-refresh
  Future<void> refreshShipments() async {
    await fetchShipments();
  }
}