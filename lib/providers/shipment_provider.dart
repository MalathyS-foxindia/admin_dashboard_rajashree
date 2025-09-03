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


  /// Fetch shipments from Supabase

  Future<void> fetchShipments() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {

      if (kDebugMode) print('⏳ Fetching shipments from API...');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
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

        if (kDebugMode) print('✅ Fetched ${_shipments.length} shipments.');

      } else {
        _shipments = [];
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching shipments: $e");
      _shipments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshShipments() async {
    await fetchShipments();
  }


  Future<void> updateTrackingNumber(String orderId, String newTracking, String provider,bool isinline) async {
    var apiUrl ="${dotenv.env['SUPABASE_URL']}/functions/v1/updateshipmenttracking?order_id=$orderId" ;
    try {
      if(provider=="India Post")
      {
        newTracking="Yet to update";
      }
      if(isinline)
      {
        apiUrl+="&inline=true";
      }
      else
      {
        apiUrl+="&inline=false";
      }
      final response = await http.patch(
        Uri.parse(
            apiUrl
        ),
        headers: {
         
          "Authorization": "Bearer ${dotenv.env['SUPABASE_ANON_KEY']!}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"tracking_number": newTracking, "shipping_provider": provider}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print(response.body);
        throw Exception("API update failed: ${response.body}");
      }

      final data = json.decode(response.body);

      // Update local list with fresh response data
      final index = _shipments.indexWhere((s) => s.orderId == orderId);
      if (index != -1) {
        _shipments[index] = Shipment(
          shipmentId: _shipments[index].shipmentId,
          orderId: _shipments[index].orderId,
          trackingNumber: data['tracking_number'] ?? _shipments[index].trackingNumber,
          shippingProvider: data['shipping_provider'] ?? _shipments[index].shippingProvider,
          trackingUrl: data['tracking_url'] ?? _shipments[index].trackingUrl,
          shippingStatus: data['shipping_status'] ?? _shipments[index].shippingStatus,
          remarks: _shipments[index].remarks,
          shippedDate: data['shipped_date'] != null
              ? DateTime.tryParse(data['shipped_date'])
              : _shipments[index].shippedDate,
          deliveredDate: _shipments[index].deliveredDate,
          createdAt: _shipments[index].createdAt,
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
    } catch (e,stack) {
      print(e);
      print(stack);
      rethrow;

    }
  }
}
