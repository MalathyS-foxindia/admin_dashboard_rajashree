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

  Future<void> fetchQueries() async {
    isLoading = true;
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
        errorMessage = "Failed: ${res.body}";
      }
    } catch (e) {
      errorMessage = "Error: $e";
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateStatus(int queryId, String newStatus) async {
    final url = '$_supabaseUrl/rest/v1/queries?query_id=eq.$queryId';
    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (res.statusCode == 200) {
        _queries = _queries.map((q) {
          if (q.queryId == queryId) {
            return QueryModel(
              queryId: q.queryId,
              name: q.name,
              customerId: q.customerId,
              mobileNumber: q.mobileNumber,
              email: q.email,
              message: q.message,
              status: newStatus,
              createdAt: q.createdAt,
            );
          }
          return q;
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Update status failed: $e");
    }
  }
}
