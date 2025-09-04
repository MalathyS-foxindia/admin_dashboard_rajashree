import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/purchase_model.dart';

class PurchaseProvider with ChangeNotifier {
  final String _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  List<Purchase> _purchases = [];
  List<Purchase> get purchases => _purchases;

  bool isLoading = false;
  String errorMessage = '';

  Map<String, String> _headers() => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  /// ✅ Fetch purchases with vendor + items + product_variants
  Future<void> fetchPurchases() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final url =
          '$_supabaseUrl/rest/v1/purchase?select=*,vendor(*),purchase_items(*,product_variants(*))';

      final response = await http.get(Uri.parse(url), headers: _headers());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _purchases = data.map((e) => Purchase.fromJson(e)).toList();
      } else {
        errorMessage = '❌ Error fetching purchases: ${response.body}';
        debugPrint(errorMessage);
      }
    } catch (e) {
      errorMessage = '❌ Unexpected error: $e';
      debugPrint(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Add Purchase + Items + update stock + vendor transaction
  Future<bool> addPurchase(
      String invoiceNo,
      DateTime invoiceDate,
      int vendorId,
      double totalAmount,
      String? invoiceImage,
      List<Map<String, dynamic>> items,
      ) async {
    try {
      // ✅ Build request body dynamically
      final purchaseBody = {
        'invoice_no': invoiceNo,
        'invoice_date': invoiceDate.toIso8601String(),
        'vendor_id': vendorId,
        'amount': totalAmount,
      };

      if (invoiceImage != null && invoiceImage.isNotEmpty) {
        purchaseBody['invoice_image'] = invoiceImage;
      }

      // 1️⃣ Insert purchase
      final purchaseRes = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/purchase'),
        headers: _headers(),
        body: jsonEncode(purchaseBody),
      );

      if (purchaseRes.statusCode != 201) {
        errorMessage = '❌ Failed to add purchase: ${purchaseRes.body}';
        debugPrint(errorMessage);
        return false;
      }

      final purchaseData = jsonDecode(purchaseRes.body) as List;
      final purchaseId = purchaseData.first['purchase_id'];

      // 2️⃣ Insert purchase items
      for (final item in items) {
        try {
          final itemRes = await http.post(
            Uri.parse('$_supabaseUrl/rest/v1/purchase_items'),
            headers: _headers(),
            body: jsonEncode({
              'purchase_id': purchaseId,
              'variant_id': item['variant'],
              'quantity': item['quantity'],
              'cost_price': item['unitPrice'] *
                  item['quantity'], // ✅ total cost (not unit price only)
            }),
          );

          if (itemRes.statusCode != 201) {
            debugPrint('⚠️ Failed to add item: ${itemRes.body}');
            continue;
          }

          // 3️⃣ Update stock
          final stockRes = await http.get(
            Uri.parse(
                '$_supabaseUrl/rest/v1/product_variants?select=stock&variant_id=eq.${item['variant']}'),
            headers: _headers(),
          );

          if (stockRes.statusCode == 200) {
            final data = jsonDecode(stockRes.body) as List;
            final currentStock =
                (data.isNotEmpty ? (data.first['stock'] as num?) : 0) ?? 0;
            final newStock = currentStock + (item['quantity'] as int);

            final updateRes = await http.patch(
              Uri.parse(
                  '$_supabaseUrl/rest/v1/product_variants?variant_id=eq.${item['variant']}'),
              headers: _headers(),
              body: jsonEncode({'stock': newStock}),
            );

            if (updateRes.statusCode != 204) {
              debugPrint('⚠️ Stock update failed: ${updateRes.body}');
            }
          } else {
            debugPrint('⚠️ Failed to fetch stock: ${stockRes.body}');
          }
        } catch (e) {
          debugPrint('❌ Error inserting item: $e');
        }
      }

      // 4️⃣ Insert vendor transaction
      try {
        final txnRes = await http.post(
          Uri.parse('$_supabaseUrl/rest/v1/vendor_transactions'),
          headers: _headers(),
          body: jsonEncode({
            'vendor_id': vendorId,
            'purchase_id': purchaseId,
            'amount_paid': 0,
            'balance_amount': totalAmount,
            'transaction_date': DateTime.now().toIso8601String(),
          }),
        );

        if (txnRes.statusCode != 201) {
          debugPrint('⚠️ Failed to create vendor transaction: ${txnRes.body}');
        }
      } catch (e) {
        debugPrint('❌ Error creating vendor transaction: $e');
      }

      await fetchPurchases();
      return true;
    } catch (e) {
      errorMessage = '❌ Error adding purchase: $e';
      debugPrint(errorMessage);
      return false;
    }
  }
}
