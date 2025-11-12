import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/queries_model.dart';
import 'package:admin_dashboard_rajashree/models/Env.dart';

class QueriesProvider with ChangeNotifier {
  final String _supabaseUrl = Env.supabaseUrl ?? '';
  final String _anonKey = Env.anonKey ?? '';

  List<QueryModel> _queries = [];
  List<QueryModel> get queries => _queries;

  bool isLoading = false;
  String errorMessage = '';

  /// 🔹 Fetch all queries
  Future<void> fetchQueries() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final url = '$_supabaseUrl/rest/v1/queries?select=*';
      final res = await http.get(
        Uri.parse(url),
        headers: {'apikey': _anonKey, 'Authorization': 'Bearer $_anonKey'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _queries = data.map((e) => QueryModel.fromJson(e)).toList();
      } else {
        errorMessage = "Failed to fetch data: ${res.body}";
      }
    } catch (e) {
      errorMessage = "Error: $e";
    }

    isLoading = false;
    notifyListeners();
  }

  /// 🔹 Update query status with SnackBar feedback
  Future<void> updateStatus(
    BuildContext context,
    int queryId,
    String newStatus,
  ) async {
    final url = '$_supabaseUrl/rest/v1/queries?query_id=eq.$queryId';

    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (res.statusCode == 204 || res.statusCode == 200) {
        _queries = _queries.map((q) {
          if (q.queryId == queryId) {
            return q.copyWith(status: newStatus);
          }
          return q;
        }).toList();

        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Status updated to "$newStatus"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception("Failed with ${res.body}");
      }
    } catch (e) {
      debugPrint("Update status failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔹 Update query remarks with SnackBar feedback
  Future<void> updateRemarks(
    BuildContext context,
    int queryId,
    String remark,
  ) async {
    final url = '$_supabaseUrl/rest/v1/queries?query_id=eq.$queryId';

    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({'remarks': remark}),
      );

      if (res.statusCode == 204 || res.statusCode == 200) {
        _queries = _queries.map((q) {
          if (q.queryId == queryId) {
            return q.copyWith(remarks: remark);
          }
          return q;
        }).toList();

        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💬 Remarks updated successfully'),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception("Failed with ${res.body}");
      }
    } catch (e) {
      debugPrint("Remarks update failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to update remarks'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
