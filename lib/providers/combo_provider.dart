// lib/providers/combo_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/combo_model.dart';

class ComboProvider extends ChangeNotifier {
  List<Combo> _combos = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _limit = 10;
  int _offset = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  List<Combo> get combos => _combos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get limit => _limit;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMore;

  final String baseUrl = dotenv.env['SUPABASE_FUNCTION_URL'] ??
      "https://gvsorguincvinuiqtooo.supabase.co";

  final String? apiKey = dotenv.env['SUPABASE_ANON_KEY'];

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Authorization": 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}' ?? "",
      };

  /// ---------- FETCH ----------
  Future<void> fetchCombos({bool reset = false, String? search}) async {
    if (reset) {
      _offset = 0;
      _currentPage = 1;
      _combos.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse(
          "$baseUrl/functions/v1/getCombo?limit=$_limit&offset=$_offset&search=${search ?? ''}");

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        
        final data = jsonDecode(response.body);
        print(data);
        if (data is Map && data.containsKey('combos')) {
          final List<dynamic> combosJson = data['combos'] ?? [];
          final int totalCount = data['total_count'] ?? combosJson.length;

          _combos = combosJson.map((e) => Combo.fromJson(e)).toList();

          _totalPages = (totalCount / _limit).ceil();
          _hasMore = _currentPage < _totalPages;
        } else if (data is List) {
          // fallback if API returns plain list
          _combos = data.map((e) => Combo.fromJson(e)).toList();
          _totalPages = 1;
          _hasMore = false;
        } else {
          _errorMessage = "Unexpected response format";
        }
      } else {
        _errorMessage =
            "Failed to load combos: ${response.statusCode} ${response.body}";
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ---------- PAGINATION ----------
  void nextPage({String? search}) {
    if (_hasMore) {
      _offset += _limit;
      _currentPage++;
      fetchCombos(search: search);
    }
  }

  void previousPage({String? search}) {
    if (_currentPage > 1) {
      _offset -= _limit;
      _currentPage--;
      fetchCombos(search: search);
    }
  }

  void setPageSize(int newLimit, {String? search}) {
    _limit = newLimit;
    fetchCombos(reset: true, search: search);
  }

  /// ---------- ADD ----------
  Future<bool> addCombo(Combo combo) async {
    try {
      final url = Uri.parse("$baseUrl/functions/v1/create-combo-with-items");
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(combo.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchCombos(reset: true);
        return true;
      } else {
        _errorMessage = "Failed to add combo: ${response.body}";
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
    return false;
  }

  /// ---------- UPDATE ----------
  /// ---------- UPDATE ----------
Future<bool> updateCombo(Combo combo) async {
  try {
    final url = Uri.parse("$baseUrl/functions/v1/insert-item-in-combo");
    final response = await http.put(
      url,
      headers: {
        ..._headers,
        "combo-id": combo.comboId.toString(), // 👈 send combo-id
      },
      body: jsonEncode(combo.toJson()),
    );  

    if (response.statusCode == 200) {
      await fetchCombos(reset: true);
      return true;
    } else {
      _errorMessage = "Failed to update combo: ${response.body}";
    }
  } catch (e) {
    _errorMessage = e.toString();
  }
  notifyListeners();
  return false;
}

  /// ---------- TOGGLE ----------
  /// ---------- TOGGLE ----------
Future<void> toggleStatus(int comboId, bool isActive) async {
  try {
    print(comboId);
    final url = Uri.parse(
        "$baseUrl/rest/v1/combo?combo_id=eq.${comboId.toString()}");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "apikey": dotenv.env['SUPABASE_SERVICE_ROLE'] ?? "",
        "Authorization": 'Bearer ${dotenv.env['SUPABASE_SERVICE_ROLE'] ?? ""}',
         "Prefer": "return=representation",
      },
      body: jsonEncode({"is_active": isActive}),
    );

    if (response.statusCode == 200) {
      print(response.body);
      // Supabase returns 204 for successful PATCH
      final index = _combos.indexWhere((c) => c.comboId == comboId);
      if (index != -1) {
        _combos[index] = _combos[index].copyWith(isActive: isActive);
      }
    } else {
      _errorMessage = "Failed to update status: ${response.body}";
    }
  } catch (e) {
    print(e.toString());
    _errorMessage = e.toString();
  }
  notifyListeners();
}

}
