import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/queries_model.dart';
import '../models/Env.dart';

class QueriesProvider with ChangeNotifier {
  final String _supabaseUrl = Env.supabaseUrl ?? '';
  final String _anonKey = Env.anonKey ?? '';

  List<QueryModel> _queries = [];
  List<QueryModel> get queries => _queries;

  bool isLoading = false;
  String errorMessage = '';

  // simple cache
  Map<String, dynamic>? _cachedOrder;
  String? _cachedOrderId;

  Map<String, String> get _headers => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
  };

  // ----------------------------------------------------------------------
  // FETCH QUERIES (RPC)
  // ----------------------------------------------------------------------
  Future<void> fetchQueries() async {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      errorMessage = 'Supabase config missing.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final url = '$_supabaseUrl/rest/v1/rpc/get_queries_full';

      final res = await http.post(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({}), // required for RPC
      );

      if (res.statusCode != 200) {
        errorMessage = 'Failed: ${res.body}';
        _queries = [];
      } else {
        final List raw = jsonDecode(res.body);

        _queries = raw.map((e) {
          final q = QueryModel.fromJson(e);
          return q.copyWith(email: q.customerEmail ?? q.email);
        }).toList();

        debugPrint("🟢 Queries loaded → ${_queries.length}");
      }
    } catch (e, st) {
      errorMessage = 'Exception: $e';
      debugPrint('❌ fetchQueries RPC error: $e\n$st');
    }

    isLoading = false;
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // ADD QUERY
  // ----------------------------------------------------------------------
  Future<bool> addQuery(QueryModel q) async {
    final url = '$_supabaseUrl/rest/v1/queries';

    final data = q.toJsonForInsert();
    data['priority'] ??= q.orderId != null ? "High" : "Medium";

    debugPrint("🟡 ADD QUERY BODY → $data");

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          ..._headers,
          "Prefer": "return=representation",
        },
        body: jsonEncode(data),
      );

      debugPrint("🟣 ADD RESPONSE → ${res.statusCode}");
      debugPrint("🟣 ADD BODY → ${res.body}");

      if (res.statusCode == 201) {
        final List items = jsonDecode(res.body);
        final added = QueryModel.fromJson(items.first);

        _queries.insert(0, added);
        notifyListeners();
        return true;
      }
    } catch (e, st) {
      debugPrint("❌ Add Query Exception → $e\n$st");
    }

    return false;
  }

  // ----------------------------------------------------------------------
  // UPDATE STATUS
  // ----------------------------------------------------------------------
  Future<bool> updateStatus(int id, String newStatus) async {
    final url = '$_supabaseUrl/rest/v1/queries?query_id=eq.$id';

    debugPrint('🟡 updateStatus() → id=$id newStatus=$newStatus');

    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (res.statusCode == 200) {
        final idx = _queries.indexWhere((q) => q.queryId == id);
        if (idx != -1) {
          _queries[idx] = _queries[idx].copyWith(status: newStatus);
          notifyListeners();
        }
        return true;
      }

      debugPrint("❌ updateStatus failed → ${res.body}");
    } catch (e, st) {
      debugPrint("❌ updateStatus Exception → $e\n$st");
    }

    return false;
  }

  // ----------------------------------------------------------------------
  // UPDATE MESSAGE
  // ----------------------------------------------------------------------
  Future<bool> updateMessage(int id, String msg) async {
    final url = '$_supabaseUrl/rest/v1/queries?query_id=eq.$id';

    debugPrint("🟡 UPDATE MESSAGE → $id");

    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: jsonEncode({'message': msg}),
      );

      if (res.statusCode == 200) {
        final idx = _queries.indexWhere((q) => q.queryId == id);
        if (idx != -1) {
          _queries[idx] = _queries[idx].copyWith(message: msg);
          notifyListeners();
        }
        return true;
      }

      debugPrint("❌ updateMessage failed → ${res.body}");
    } catch (e, st) {
      debugPrint("❌ updateMessage Exception → $e\n$st");
    }

    return false;
  }

  // ----------------------------------------------------------------------
  // UPDATE REMARKS
  // ----------------------------------------------------------------------
  Future<bool> updateRemarks(int id, String remarks) async {
    final url = '$_supabaseUrl/rest/v1/queries?query_id=eq.$id';

    debugPrint("🟡 UPDATE REMARKS → $id");

    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: jsonEncode({'remarks': remarks}),
      );

      if (res.statusCode == 200) {
        final idx = _queries.indexWhere((q) => q.queryId == id);
        if (idx != -1) {
          _queries[idx] = _queries[idx].copyWith(remarks: remarks);
          notifyListeners();
        }
        return true;
      }

      debugPrint("❌ updateRemarks failed → ${res.body}");
    } catch (e, st) {
      debugPrint("❌ updateRemarks Exception → $e\n$st");
    }

    return false;
  }

  // ----------------------------------------------------------------------
  // DELETE QUERY
  // ----------------------------------------------------------------------
  Future<bool> deleteQuery(int id) async {
    final url = '$_supabaseUrl/rest/v1/queries?query_id=eq.$id';

    debugPrint("🔴 DELETE QUERY → $id");

    try {
      final res = await http.delete(Uri.parse(url), headers: _headers);

      if (res.statusCode == 204) {
        _queries.removeWhere((e) => e.queryId == id);
        notifyListeners();
        return true;
      }

      debugPrint("❌ deleteQuery failed → ${res.body}");
    } catch (e, st) {
      debugPrint("❌ deleteQuery Exception → $e\n$st");
    }

    return false;
  }

  // ----------------------------------------------------------------------
  // FETCH FULL ORDER DETAILS (order + customer)
  // ----------------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchOrderDetails(String orderId) async {
    if (_cachedOrderId == orderId && _cachedOrder != null) {
      debugPrint("🟢 ORDER DETAILS from CACHE → $orderId");
      return _cachedOrder;
    }

    final url = '$_supabaseUrl/rest/v1/orders?order_id=ilike.$orderId&select=*';

    debugPrint("🔵 FETCH ORDER DETAILS → $url");

    try {
      final res = await http.get(Uri.parse(url), headers: _headers);

      debugPrint("🟣 ORDER STATUS → ${res.statusCode}");
      debugPrint("🟣 ORDER BODY → ${res.body}");

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        if (data.isNotEmpty) {
          final order = data.first;

          // Load customer
          Map<String, dynamic>? customer;

          if (order['customer_id'] != null) {
            final custRes = await http.get(
              Uri.parse(
                '$_supabaseUrl/rest/v1/customers?customer_id=eq.${order['customer_id']}&select=customer_id,mobile_number,email',
              ),
              headers: _headers,
            );

            if (custRes.statusCode == 200) {
              final List custData = jsonDecode(custRes.body);
              if (custData.isNotEmpty) customer = custData.first;
            }
          }

          _cachedOrderId = orderId;
          _cachedOrder = {
            'order': order,
            'customer': customer,
          };

          return _cachedOrder;
        }
      }
    } catch (e, st) {
      debugPrint("❌ fetchOrderDetails Exception → $e\n$st");
    }

    return null;
  }

  // ----------------------------------------------------------------------
  // FETCH ORDER ITEMS (product_variants join)
  // ----------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    final url =
        '$_supabaseUrl/rest/v1/order_items?order_id=eq.$orderId&select=quantity,product_variants(sku,variant_name,saleprice)';

    debugPrint("🔵 FETCH ORDER ITEMS → $url");

    try {
      final res = await http.get(Uri.parse(url), headers: _headers);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e, st) {
      debugPrint("❌ fetchOrderItems Exception → $e\n$st");
    }

    return [];
  }
}
