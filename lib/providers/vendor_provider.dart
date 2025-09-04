import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/vendor_model.dart';
import '../models/vendor_transaction_model.dart';

class VendorProvider with ChangeNotifier {
  final String _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  List<Vendor> _vendors = [];
  List<Vendor> get vendors => _vendors;

  /// cache: vendorId -> transactions list
  final Map<int, List<VendorTransaction>> _transactionsCache = {};
  Map<int, List<VendorTransaction>> get transactionsCache => _transactionsCache;

  /// unpaid invoices: vendorId -> purchases with balance > 0
  final Map<int, List<Map<String, dynamic>>> _unpaidInvoicesCache = {};
  Map<int, List<Map<String, dynamic>>> get unpaidInvoicesCache =>
      _unpaidInvoicesCache;

  bool isLoading = false;
  String errorMessage = '';

  Map<String, String> _headers() => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  /// Fetch Vendors
  Future<void> fetchVendors() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final url = '$_supabaseUrl/rest/v1/vendor?select=*';
      final response = await http.get(Uri.parse(url), headers: _headers());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _vendors = data.map((e) => Vendor.fromJson(e)).toList();
      } else {
        errorMessage = '❌ Error fetching vendors: ${response.body}';
      }
    } catch (e) {
      errorMessage = '❌ Unexpected error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Add Vendor
  Future<bool> addVendor(Vendor vendor) async {
    final url = '$_supabaseUrl/rest/v1/vendor';
    try {
      final payload = vendor.toInsertJson();
      final response =
      await http.post(Uri.parse(url), headers: _headers(), body: jsonEncode(payload));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as List;
        final newVendor = Vendor.fromJson(data.first);
        _vendors.add(newVendor);
        notifyListeners();
        return true;
      } else {
        errorMessage = '❌ Failed to add vendor: ${response.body}';
      }
    } catch (e) {
      errorMessage = '❌ Error adding vendor: $e';
    }
    return false;
  }

  /// Enable / Disable Vendor
  Future<bool> toggleVendorStatus(int vendorId, bool newStatus) async {
    final url = '$_supabaseUrl/rest/v1/vendor?vendor_id=eq.$vendorId';
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers(),
        body: jsonEncode({'is_active': newStatus}),
      );

      if (response.statusCode == 200) {
        final updated = jsonDecode(response.body) as List;
        final updatedVendor = Vendor.fromJson(updated.first);
        final index =
        _vendors.indexWhere((v) => v.vendor_id == updatedVendor.vendor_id);
        if (index != -1) _vendors[index] = updatedVendor;
        notifyListeners();
        return true;
      } else {
        errorMessage = '❌ Failed to update status: ${response.body}';
      }
    } catch (e) {
      errorMessage = '❌ Error updating vendor status: $e';
    }
    return false;
  }

  /// Fetch Vendor Transactions (with cache)
  Future<List<VendorTransaction>> fetchVendorTransactions(
      int vendorId, {
        bool forceRefresh = false,
      }) async {
    if (!forceRefresh && _transactionsCache.containsKey(vendorId)) {
      return _transactionsCache[vendorId]!;
    }

    try {
      final url =
          '$_supabaseUrl/rest/v1/vendor_transactions?vendor_id=eq.$vendorId&select=*';
      final response = await http.get(Uri.parse(url), headers: _headers());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final txns = data.map((e) => VendorTransaction.fromJson(e)).toList();
        _transactionsCache[vendorId] = txns;
        notifyListeners();
        return txns;
      } else {
        debugPrint('❌ Failed to fetch transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching transactions: $e');
    }
    return [];
  }

  /// Add Vendor Transaction (Payment) with comment
  Future<bool> addVendorTransaction(VendorTransaction txn) async {
    final url = '$_supabaseUrl/rest/v1/vendor_transactions';
    try {
      final payload = {
        'vendor_id': txn.vendorId,
        'purchase_id': txn.purchaseId, // ✅ int, nullable
        'amount_paid': txn.amountPaid,
        'balance_amount': txn.balanceAmount,
        'transaction_date': txn.transactionDate,
        'comment': txn.comment,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        await fetchVendorTransactions(txn.vendorId, forceRefresh: true);
        return true;
      } else {
        debugPrint("❌ Failed to add transaction: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error adding transaction: $e");
    }
    return false;
  }



  /// ✅ Fetch unpaid invoices for a vendor (balance > 0)
  Future<List<Map<String, dynamic>>> fetchUnpaidInvoices(int vendorId) async {
    try {
      final url =
          '$_supabaseUrl/rest/v1/purchase?select=purchase_id,invoice_no,amount,vendor_id,vendor(*),purchase_items(*),vendor_transactions(amount_paid,balance_amount)&vendor_id=eq.$vendorId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        // ✅ Process unpaid invoices
        final unpaid = data.map((p) {
          final double total = (p['amount'] as num?)?.toDouble() ?? 0.0;

          // sum paid from vendor_transactions
          final List txns = p['vendor_transactions'] ?? [];
          final double paid = txns.fold<double>(
            0.0,
                (sum, t) => sum + ((t['amount_paid'] as num?)?.toDouble() ?? 0.0),
          );

          final double balance = total - paid;

          return {
            "purchase_id": p['purchase_id'],
            "invoice_no": p['invoice_no'],
            "total": total,
            "paid": paid,
            "balance": balance,
          };
        }).where((inv) => inv["balance"] > 0).toList();

        return unpaid;
      } else {
        debugPrint("❌ Failed to fetch unpaid invoices: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching unpaid invoices: $e");
    }
    return [];
  }

}
