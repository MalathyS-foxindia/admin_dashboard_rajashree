import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  final SupabaseClient supabase;

  OrderProvider(this.supabase);

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  /// Fetch all orders (with optional search or filter)
  Future<void> fetchOrders({String? search, String? filter}) async {
    _isLoading = true;
    notifyListeners();

    final queryParams = <String, String>{'limit': '1000'};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (filter != null && filter.isNotEmpty) queryParams['filter'] = filter;

    final uri = Uri.https(
      'gvsorguincvinuiqtooo.supabase.co',
      '/functions/v1/getOrderWithItems',
      queryParams,
    );

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['orders'] != null) {
        // Parse with shipment status included
        _orders = List<Order>.from(
          data['orders'].map((e) => Order.fromJson({
                ...e,
                'shipment_status': e['shipment_status'], // ✅ Ensure included
              })),
        );
      }
    } else {
      debugPrint('Error fetching orders: ${response.body}');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch single order detail (items)
  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    final uri = Uri.https(
      'gvsorguincvinuiqtooo.supabase.co',
      '/functions/v1/getOrderWithItems',
      {'orderId': orderId},
    );

    final headers = {
      'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}'
    };

    try {
      final response = await http.get(uri, headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['items'] != null) {
        return (body['items'] as List)
            .map((e) => OrderItem.fromJson(e))
            .toList();
      }
    } catch (e) {
      print('Order detail fetch error: $e');
    }

    return [];
  }

  /// Fetch raw invoice JSON for an order
  Future<Map<String, dynamic>?> fetchOrderJson(String orderId) async {
    try {
      print('Fetching JSON for order: $orderId');
      final headers = {
        'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}'
      };
      final response = await http.get(
        Uri.parse(
            'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/generateinvoice?order_id=$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching order json: $e');
    }
    return null;
  }

  /// Upload PDF invoice to Supabase Storage
  Future<bool> uploadInvoiceToSupabaseStorage(
      Map<String, dynamic> invoiceData) async {
    try {
      final supabase = Supabase.instance.client;

      Uint8List fileBytes;
      if (invoiceData['fileData'] is String) {
        fileBytes = base64Decode(invoiceData['fileData']);
      } else if (invoiceData['fileData'] is Uint8List) {
        fileBytes = invoiceData['fileData'];
      } else {
        throw Exception(
            "Invalid fileData format — must be Base64 string or Uint8List");
      }

      final filePath =
          'Invoices_${invoiceData['filedate']}/${invoiceData['fileName']}';

      final response = await supabase.storage
          .from('invoices')
          .uploadBinary(filePath, fileBytes,
              fileOptions: FileOptions(contentType: 'application/pdf'));

      if (response.isEmpty) {
        throw Exception("Failed to upload invoice to Supabase Storage");
      }

      final publicUrl =
          supabase.storage.from('invoices').getPublicUrl(filePath);

      debugPrint('✅ Invoice uploaded: $publicUrl');
       // ✅ Update the order row with invoice_url
     final updateRes = await supabase
      .from('orders')
      .update({'invoice_url': publicUrl})
      .eq('order_id', invoiceData['orderId'].toString().trim())
      .select(); // return updated rows so we can check

  if (updateRes.isEmpty) {
    throw Exception("No order found with order_id ${invoiceData['orderId']}");
  }
      debugPrint('✅ invoice_url updated in orders table');
    return true;  
    }
    
      catch (e) {
    debugPrint('❌ Error uploading invoice: $e');
    return false;
  }
    
  } 

 }
