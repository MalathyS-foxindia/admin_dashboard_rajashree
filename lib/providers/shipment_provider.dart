// lib/providers/shipment_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/shipment.dart';
import 'package:admin_dashboard_rajashree/models/Env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class ShipmentProvider extends ChangeNotifier {
  List<Shipment> _shipments = [];
  bool _isLoading = false;

  List<Shipment> get shipments => _shipments;
  bool get isLoading => _isLoading;

 final SupabaseClient supabase = Supabase.instance.client;
  /// Fetch shipments from Supabase

  Future<void> fetchShipments() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {

      if (kDebugMode) print('⏳ Fetching shipments from API...');

      final supabaseUrl = Env.supabaseUrl;
      final supabaseAnonKey = Env.anonKey;

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
    var apiUrl ="${Env.supabaseUrl}/functions/v1/updateshipmenttracking?order_id=$orderId" ;
    try {
      
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
         
          "Authorization": "Bearer ${Env.anonKey!}",
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
  Future<void> sendShipmentStatus(List<Shipment> shipments) async {
  for (var s in shipments) {
    if (s.orderId == null || s.orderId!.isEmpty) {
      debugPrint("⚠️ Shipment ${s.shipmentId} has invalid orderId, skipping");
      continue;
    }

    try {
      // 1️⃣ Fetch customer_id from orders safely
      final orderRes = await supabase
          .from('orders')
          .select('customer_id')
          .eq('order_id', s.orderId!) // Make sure order_id is TEXT in Supabase
          .maybeSingle();

      if (orderRes == null || orderRes['customer_id'] == null) {
        debugPrint("❌ No customer found for order ${s.orderId}");
        continue;
      }

      final customerId = orderRes['customer_id'];

      // 2️⃣ Fetch customer details safely
      final customerRes = await supabase
          .from('customers')
          .select('mobile_number, full_name')
          .eq('customer_id', customerId)
          .maybeSingle();

      if (customerRes == null || customerRes['mobile_number'] == null) {
        debugPrint("❌ No phone number found for customer $customerId");
        continue;
      }

      final phone = customerRes['mobile_number']!.toString();
      final customerName = customerRes['full_name'] ?? "Customer";

      // 3️⃣ Prepare message data
      final trackingUrl = s.trackingUrl ?? "";
      final trackingNumber = s.trackingNumber ?? "";

      // 4️⃣ Send WhatsApp message and handle API errors
      bool messageSent = false;
      try {
        messageSent = await _sendWhatsAppMessage(
          phone: phone,
          customerName: customerName,
          orderId: s.orderId!,
          trackingUrl: trackingUrl,
          trackingNumber: trackingNumber,
        );
      } catch (e) {
        debugPrint("⚠️ WhatsApp send failed for order ${s.orderId}: $e");
        messageSent = false;
      }

      if (messageSent) {
        debugPrint("✅ Status sent for order ${s.orderId} to $phone");
      } else {
        debugPrint("❌ Failed to send WhatsApp status for order ${s.orderId}");
      }

    } catch (e, stack) {
      debugPrint("⚠️ Error processing shipment ${s.shipmentId} / order ${s.orderId}: $e");
      debugPrint(stack.toString());
      // Continue loop for remaining shipments
    }
  }
}


  /// Helper method to send WhatsApp template via wa-api.cloud
  Future<bool> _sendWhatsAppMessage({
    required String phone,
    required String customerName,
    required String orderId,
    required String trackingUrl,
    required String trackingNumber
  }) async {
    try {
      final url = Uri.parse("https://wa-api.cloud/api/v1/messages");

      final headers = {
        "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlcnZlcjItd2MubGlicm9taS5jbG91ZCIsImF1ZCI6Imh0dHBzOi8vc2VydmVyMi13Yy5saWJyb21pLmNsb3VkIiwiaWF0IjoxNzU5Mjg1MzYzLCJleHAiOjIwNzQ4MTgxNjMsInVzZXJfaWQiOjcwMzEsImNvbXBhbnlfaWQiOjU4NjYsInRva2VuX2lkIjo5MDQ5NywiYWJpbGl0aWVzIjpbInJlYWQiXSwidHlwZSI6ImFjY2Vzc190b2tlbiJ9.iGZrvelGfOj9sB7oQgEUmyoMH48GlFOFU9w_zEvGZd4", // 🔥 Replace with real token
        "Content-Type": "application/json",
      };

      final body = jsonEncode({
        "to": phone,
        "type": "template",
        "template": {
          "name": "shipment_confirm",
          "language": {"code": "en"},
          "components": [
            {
              "type": "body",
              "parameters": [
                {"type": "text", "text": customerName},
                {"type": "text", "text" : orderId},
                {"type": "text", "text": trackingNumber},
                {"type": "text", "text": trackingUrl},
              ]
            }
          ]
        }
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("❌ WhatsApp API error: ${response.statusCode} ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Exception sending WhatsApp message: $e");
      return false;
    }
  }
}
