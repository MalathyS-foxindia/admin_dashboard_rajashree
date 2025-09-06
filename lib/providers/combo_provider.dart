// lib/providers/combo_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // for API URL + KEY
import '../models/combo_model.dart';

class ComboProvider extends ChangeNotifier {
  List<Combo> _combos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Combo> get combos => _combos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String baseUrl = dotenv.env['SUPABASE_FUNCTION_URL'] ??
      "https://gvsorguincvinuiqtooo.supabase.co/functions/v1";

  final String? apiKey = dotenv.env['SUPABASE_ANON_KEY'];

  /// ---------- FETCH ----------
  Future<void> fetchCombos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse("$baseUrl/getCombo");
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "apikey": apiKey ?? "",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          _combos = data.map((e) => Combo.fromJson(e)).toList().cast<Combo>();
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

  /// ---------- ADD ----------
  Future<bool> addCombo(Combo combo) async {
    try {
      final url = Uri.parse("$baseUrl/create-combo-with-items");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "apikey": apiKey ?? "",
        },
        body: jsonEncode(combo.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchCombos();
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
  Future<bool> updateCombo(Combo combo) async {
    try {
      final url = Uri.parse("$baseUrl/updateCombo");
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "apikey": apiKey ?? "",
        },
        body: jsonEncode(combo.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchCombos();
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

  /// ---------- TOGGLE ACTIVE/INACTIVE ----------
  Future<void> toggleStatus(int comboId, bool isActive) async {
    try {
      final url = Uri.parse("$baseUrl/updateComboStatus");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "apikey": apiKey ?? "",
        },
        body: jsonEncode({
          "combo_id": comboId,
          "is_active": isActive,
        }),
      );

      if (response.statusCode == 200) {
        final index = _combos.indexWhere((c) => c.comboId == comboId);
        if (index != -1) {
          _combos[index] = _combos[index].copyWith(isActive: isActive);
        }
      } else {
        _errorMessage = "Failed to update status: ${response.body}";
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

}