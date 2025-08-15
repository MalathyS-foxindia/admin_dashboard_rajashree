// lib/providers/product_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/products_model.dart';

class ProductProvider with ChangeNotifier {
  final String _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final String _serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE'] ?? '';

  ProductProvider() {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      debugPrint('Warning: Supabase URL or ANON key missing in .env');
    }
  }

  bool isLoading = false;
  String? error;

  final List<Product> _items = [];
  List<Product> get items => List.unmodifiable(_items);

  final List<String> _categories = [];
  List<String> get categories => List.unmodifiable(_categories);

  int _page = 1;
  final int _limit = 5;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  /// Fetch products with pagination, search, category filter
  Future<void> fetchProducts({
    bool reset = false,
    String? search,
    String? category,
  }) async {
    if (reset) {
      _page = 1;
      _items.clear();
      _hasMore = true;
      notifyListeners();
    }

    if (!_hasMore && !reset) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final queryParams = {
        'page': _page.toString(),
        'limit': _limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      };

      final uri = Uri.parse('$_supabaseUrl/functions/v1/get-product-with-variants')
          .replace(queryParameters: queryParams);

      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_anonKey'},
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List<dynamic> jsonList = data['products'] ?? [];
        final List<String> cats = List<String>.from(data['categories'] ?? []);

        if (reset) {
          _categories
            ..clear()
            ..addAll(cats);
        }

        _items.addAll(jsonList.map((j) => Product.fromJson(j as Map<String, dynamic>)));
        _hasMore = jsonList.length == _limit;
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

  /// Load next page
  Future<void> fetchMoreProducts({
    String? search,
    String? category,
  }) async {
    if (!_hasMore || isLoading) return;
    _page++;
    await fetchProducts(search: search, category: category);
  }

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
        await fetchProducts(reset: true);
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

  Future<bool> updateProduct(Product p) async {
    if (p.id == null) {
      error = 'Missing product id';
      return false;
    }
    isLoading = true;
    notifyListeners();
    try {
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
        await fetchProducts(reset: true);
        return true;
      } else if (resp.statusCode == 400) {
        final Map<String, dynamic> respData = jsonDecode(resp.body);
        if (respData.containsKey('variant_id')) {
          final ids = (respData['variant_id'] as List).join(', ');
          error = 'Cannot delete variants linked to existing orders: $ids';
        } else {
          error = respData['error'] ?? 'Update failed with status 400';
        }
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

  Future<bool> deleteProduct(String productId) async {
    isLoading = true;
    notifyListeners();
    try {
      final url = '$_supabaseUrl/rest/v1/master_product?product_id=eq.${int.parse(productId)}';
      final resp = await http.delete(
        Uri.parse(url),
        headers: {
          'apikey': _serviceRoleKey,
          'Authorization': 'Bearer $_serviceRoleKey',
        },
      );

      if (resp.statusCode == 204) {
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

  Future<bool> deleteVariant(String variantId) async {
    isLoading = true;
    notifyListeners();
    try {
      final url = '$_supabaseUrl/rest/v1/product_variants?id=eq.$variantId';
      final resp = await http.delete(
        Uri.parse(url),
        headers: {
          'apikey': _serviceRoleKey,
          'Authorization': 'Bearer $_serviceRoleKey',
        },
      );

      if (resp.statusCode == 204) {
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
