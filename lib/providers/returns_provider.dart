import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/return_model.dart';
import '../models/return_progress_model.dart';
import '../models/Env.dart';

class ReturnsProvider with ChangeNotifier {
  final String _supabaseUrl = Env.supabaseUrl ?? '';
  final String _anonKey = Env.anonKey ?? '';

  List<ReturnModel> _items = [];
  List<ReturnModel> get items => _items;

  bool isLoading = false;
  String errorMessage = '';

  /// 🟢 Fetch all returns
  Future<void> fetchReturns() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/returns?select=*');
      final res = await http.get(url, headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
      });

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _items = data.map((e) => ReturnModel.fromJson(e)).toList();
      } else {
        errorMessage = 'Failed to fetch returns (${res.statusCode})';
      }
    } catch (e) {
      errorMessage = "⚠️ Error fetching returns: $e";
    }

    isLoading = false;
    notifyListeners();
  }

  // ✅ Add new return
  Future<bool> addReturn(ReturnModel newReturn) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/returns');
      final res = await http.post(
        url,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(newReturn.toJson()),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        await fetchReturns();
        return true;
      } else {
        debugPrint('❌ Failed: ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Add return failed: $e');
      return false;
    }
  }


  /// 🟢 Update returned items
  Future<void> updateReturnedItems(int returnId, String itemsDesc) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/returns?return_id=eq.$returnId');
      final res = await http.patch(
        url,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'returned_items': itemsDesc}),
      );

      if (res.statusCode == 200) {
        final idx = _items.indexWhere((r) => r.returnId == returnId);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(returnedItems: itemsDesc);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Update returned items failed: $e");
    }
  }


  // ✅ Update status
  Future<void> updateStatus(int id, String newStatus) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/returns?return_id=eq.$id');
      final res = await http.patch(
        url,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        final idx = _items.indexWhere((r) => r.returnId == id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(status: newStatus);
          notifyListeners();
        }
      } else {
        debugPrint('❌ Status update failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ Status update failed: $e');
    }
  }

  /// 🟢 Update reason
  Future<void> updateReason(int returnId, String reason) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/returns?return_id=eq.$returnId');
      final res = await http.patch(
        url,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );

      if (res.statusCode == 200) {
        final idx = _items.indexWhere((r) => r.returnId == returnId);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(reason: reason);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Update reason failed: $e");
    }
  }

  /// 🟢 Update refund amount
  Future<void> updateRefundAmount(int returnId, double amount) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/returns?return_id=eq.$returnId');
      final res = await http.patch(
        url,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refund_amount': amount}),
      );

      if (res.statusCode == 200) {
        final idx = _items.indexWhere((r) => r.returnId == returnId);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(refundAmount: amount);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Update refund amount failed: $e");
    }
  }

  // ✅ Edit details (reason, items, status)
  Future<void> updateReturnDetails({
    required int id,
    String? status,
    String? reason,
    String? returnedItems,
  }) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/returns?return_id=eq.$id');
      final res = await http.patch(
        url,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (status != null) 'status': status,
          if (reason != null) 'reason': reason,
          if (returnedItems != null) 'returned_items': returnedItems,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        final idx = _items.indexWhere((r) => r.returnId == id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(
            status: status ?? _items[idx].status,
            reason: reason ?? _items[idx].reason,
            returnedItems: returnedItems ?? _items[idx].returnedItems,
          );
          notifyListeners();
        }
      } else {
        debugPrint('❌ Update failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ Update return failed: $e');
    }
  }

  // ✅ Delete return
  Future<void> deleteReturn(int id) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/returns?return_id=eq.$id');
      final res = await http.delete(url, headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      });

      if (res.statusCode == 200 || res.statusCode == 204) {
        _items.removeWhere((r) => r.returnId == id);
        notifyListeners();
      } else {
        debugPrint('❌ Delete failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
    }
  }

  /// 🟢 Fetch progress notes (optional, for timeline dialog)
  /*Future<List<ReturnProgressModel>> fetchProgress(int returnId) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/return_progress?return_id=eq.$returnId');
      final res = await http.get(url, headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => ReturnProgressModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("⚠️ Fetch progress error: $e");
    }
    return [];
  }*/

  /// 🟢 Add progress note (for tracking updates)
  Future<void> addProgressNote({
    required int returnId,
    String? status,
    String? note,
  }) async {
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/return_progress');
      await http.post(
        url,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'return_id': returnId,
          'status': status,
          'note': note,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('❌ addProgressNote failed: $e');
    }
  }


  /// 🟢 Open "Add Return" dialog (for reuse in UI)
  void openAddReturnDialog(BuildContext context) {
    final form = GlobalKey<FormState>();
    final idCtrl = TextEditingController();
    final orderCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final refundCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();
    DateTime? rDate = DateTime.now();
    String selStatus = 'Requested';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Return Record'),
        content: Form(
          key: form,
          child: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: idCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                    const InputDecoration(labelText: 'Return ID (unique)'),
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter ID' : null,
                  ),
                  TextFormField(
                    controller: orderCtrl,
                    decoration: const InputDecoration(labelText: 'Order ID'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selStatus,
                    items: [
                      for (final s in [
                        'Requested',
                        'Received',
                        'Inspecting',
                        'Approved',
                        'Rejected',
                        'Refund Initiated',
                        'Refunded',
                        'Closed'
                      ])
                        DropdownMenuItem(value: s, child: Text(s))
                    ],
                    onChanged: (v) => selStatus = v ?? 'Requested',
                    decoration:
                    const InputDecoration(labelText: 'Status'),
                  ),
                  TextFormField(
                    controller: reasonCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Reason'),
                  ),
                  TextFormField(
                    controller: itemsCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Returned Items'),
                  ),
                  TextFormField(
                    controller: refundCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                    const InputDecoration(labelText: 'Refund Amount'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final ok = await addReturn(ReturnModel(
                returnId: int.parse(idCtrl.text),
                orderId: orderCtrl.text,
                status: selStatus,
                reason: reasonCtrl.text,
                returnedItems: itemsCtrl.text,
                refundAmount: double.tryParse(refundCtrl.text),
                returnDate: rDate,
                createdAt: DateTime.now(),
              ));
              if (!context.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                  Text(ok ? '✅ Return added' : '❌ Failed to add')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
