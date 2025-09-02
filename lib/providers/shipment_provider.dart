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

  /// Fetches shipments from Supabase REST API
  Future<void> fetchShipments() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
      final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception("SUPABASE_URL or SUPABASE_ANON_KEY missing");
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
      } else {
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

  /// Bulk delete shipments by IDs
  Future<void> deleteShipments(List<String> ids) async {
    try {
      final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
      final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception("SUPABASE_URL or SUPABASE_ANON_KEY missing");
      }

      final url = "$supabaseUrl/rest/v1/shipment_tracking";
      final filter = ids.map((id) => 'id.eq.$id').join(',');

      final response = await http.delete(
        Uri.parse('$url?$filter'),
        headers: {
          "apikey": supabaseAnonKey,
          "Authorization": "Bearer $supabaseAnonKey",
        },
      );

      if (response.statusCode == 204) {
        // Remove deleted shipments locally
        _shipments.removeWhere((s) => ids.contains(s.shipmentId));
        notifyListeners();
        if (kDebugMode) {
          print('✅ Deleted ${ids.length} shipments successfully.');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to delete shipments: ${response.statusCode}');
          print('❌ Response: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during deletion: $e');
      }
    }
  }
}
