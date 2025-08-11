// lib/providers/product_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/products_model.dart';

/// ProductProvider
/// - keeps local List<Product>
/// - exposes isLoading & error states
/// - performs REST calls to Supabase functions & tables (same endpoints you used)
class ProductProvider with ChangeNotifier {
  final String _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  ProductProvider() {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      // developer-friendly error (don't crash in release)
      debugPrint('Warning: Supabase URL or ANON key missing in .env');
    }
  }

  bool isLoading = false;
  String? error;

  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);

  Future<void> fetchProducts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final url = '$_supabaseUrl/functions/v1/get-product-with-variants';
      final resp = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_anonKey'},
      );

      if (resp.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(resp.body);
        _items
          ..clear()
          ..addAll(jsonList.map((j) => Product.fromJson(j as Map<String, dynamic>)));
      } else {
        error = 'Fetch failed: ${resp.statusCode}';
        debugPrint('fetchProducts error: ${resp.body}');
      }
    } catch (e) {
      error = e.toString();
      debugPrint('fetchProducts exception: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Add product using your create-product-with-variants function
  Future<bool> addProduct(Product p) async {
    isLoading = true;
    notifyListeners();
    try {
      final url = '$_supabaseUrl/functions/v1/create-product-with-variants';
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(p.toJson()),
      );

      if (resp.statusCode == 200) {
        // The function presumably returns created product — but to be safe, re-fetch
        await fetchProducts();
        return true;
      } else {
        error = 'Add failed: ${resp.statusCode}';
        debugPrint('addProduct error: ${resp.body}');
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('addProduct exception: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Update product via update-product-with-variants function
  /// Update product via update-product-with-variants function
Future<bool> updateProduct(Product p) async {
  if (p.id == null) {
    error = 'Missing product id';
    return false;
  }
  print(jsonEncode(p.toJson()));
  isLoading = true;
  notifyListeners();
  try {
 print("ProductProvider: Updating product " + jsonEncode(p.toJson()));

    final url = '$_supabaseUrl/functions/v1/update-product-with-variants';
    final resp = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(p.toJson()),
    );

    if (resp.statusCode == 200 || resp.statusCode == 204) {
      await fetchProducts();
      return true;
    } else if (resp.statusCode == 400) {
      // Backend says some variants cannot be deleted
      final Map<String, dynamic> respData = jsonDecode(resp.body);
      if (respData.containsKey('variant_ids')) {
        final ids = (respData['variant_ids'] as List).join(', ');
        error =
            'Cannot delete variants linked to existing orders: $ids';
      } else {
        error = respData['error'] ?? 'Update failed with status 400';
      }
      debugPrint('updateProduct blocked: ${resp.body}');
      return false;
    } else {
      error = 'Update failed: ${resp.statusCode}';
      debugPrint('updateProduct error: ${resp.body}');
      return false;
    }
  } catch (e) {
    error = e.toString();
    debugPrint('updateProduct exception: $e');
    return false;
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

  /// Delete product using the REST table endpoint like you had:
  Future<bool> deleteProduct(String productId) async {
    isLoading = true;
    notifyListeners();
    try {
      final url = '$_supabaseUrl/rest/v1/master_product?product_id=eq.$productId';
      final resp = await http.delete(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      );

      if (resp.statusCode == 204) {
        // remove locally for instant UI update
        _items.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      } else {
        error = 'Delete failed: ${resp.statusCode}';
        debugPrint('deleteProduct error: ${resp.body}');
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('deleteProduct exception: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a variant via REST call (like your deleteVariant function)
  Future<bool> deleteVariant(String variantId) async {
    isLoading = true;
    notifyListeners();
    try {
      final url = '$_supabaseUrl/rest/v1/product_variants?id=eq.$variantId';
      final resp = await http.delete(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
      );

      if (resp.statusCode == 204) {
        // remove variant from local product list
        for (var p in _items) {
          p.variants?.removeWhere((v) => v.id == variantId);
        }
        notifyListeners();
        return true;
      } else {
        error = 'Delete variant failed: ${resp.statusCode}';
        debugPrint('deleteVariant error: ${resp.body}');
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('deleteVariant exception: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
