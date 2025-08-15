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

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    const url = 'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/getOrderWithItems';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['orders'] != null) {
        _orders = List<Order>.from(data['orders'].map((e) => Order.fromJson(e)));
      }
    } else {
      debugPrint('Error fetching orders: ${response.body}');
    }

    _isLoading = false;
    notifyListeners();
  }

// Fetch single order detail (items)
  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    final url = 'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/getOrderWithItems?order_id=$orderId';
    final headers = {
       'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}'
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['items'] != null) {
        return (body['items'] as List).map((e) => OrderItem.fromJson(e)).toList();
      }
    } catch (e) {
      print('Order detail fetch error: $e');
    }

    return [];
  }

Future<Map<String, dynamic>?> fetchOrderJson(String orderId) async {
    try {
      print('Fetching JSON for order: $orderId');
       final headers = {
       'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}'
    };
      final response = await http.get(Uri.parse('https://gvsorguincvinuiqtooo.supabase.co/functions/v1/generateinvoice?order_id=$orderId'),headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching order json: $e');
    }
    return null;
  }

  // Upload PDF to Google Drive via your backend edge function
Future<bool> uploadInvoiceToSupabaseStorage(Map<String, dynamic> invoiceData) async {
  try {
    // ✅ Get the Supabase client (already initialized in main.dart)
    final supabase = Supabase.instance.client;

    // ✅ Prepare file bytes
    Uint8List fileBytes;
    if (invoiceData['fileData'] is String) {
      // If Base64 string → decode
      fileBytes = base64Decode(invoiceData['fileData']);
    } else if (invoiceData['fileData'] is Uint8List) {
      // Already Uint8List
      fileBytes = invoiceData['fileData'];
    } else {
      throw Exception("Invalid fileData format — must be Base64 string or Uint8List");
    }


// ✅ Build file path: invoices/{invoice_date}/{fileName}.pdf
final filePath = 'Invoices_${invoiceData['filedate']}/${invoiceData['fileName']}';

    
    // ✅ Upload
    final response = await supabase.storage
        .from('invoices')
        .uploadBinary(filePath, fileBytes, fileOptions: FileOptions(contentType: 'application/pdf'));

    if (response.isEmpty) {
      throw Exception("Failed to upload invoice to Supabase Storage");
    }

    // ✅ Get public URL
    final publicUrl = supabase.storage.from('invoices').getPublicUrl(filePath);
   
    debugPrint('✅ Invoice uploaded: $publicUrl');
     return true;

  } catch (e) {
    debugPrint('❌ Error uploading invoice: $e');
    return false;
  }
}

}