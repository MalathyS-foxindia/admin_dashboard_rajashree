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
      debugPrint('⚠️ Supabase URL or keys are missing in .env');
    }
  }

  bool isLoading = false;
  String? error;

  final List<Product> _items = [];
  List<Product> get items => List.unmodifiable(_items);

  final List<String> _categories = [];
  List<String> get categories => List.unmodifiable(_categories);

  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  /// Fetch products with pagination, search, category filter
  Future<void> fetchProducts({
    bool reset = false,
    String? search,
    String? category,
  }) async {
    if (isLoading && !reset) return;
    if (!_hasMore && !reset) return;

    if (reset) {
      _page = 1;
      _items.clear();
      _categories.clear();
      _hasMore = true;
      error = null;
    }

    isLoading = true;
    notifyListeners();

    try {
      final queryParams = {
        'page': _page.toString(),
        'limit': _limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      };

      final uri = Uri.parse(
        '$_supabaseUrl/functions/v1/get-product-with-variants',
      ).replace(queryParameters: queryParams);

      debugPrint('📡 Fetching products from: $uri');

      final resp = await http.get(
        uri,
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        // Backend response: use "data" key for products
        final List<dynamic> jsonList = data['data'] ?? [];

        final newProducts = jsonList
            .map((j) => Product.fromJson(j as Map<String, dynamic>))
            .toList();

        if (reset) {
          final productCategories = newProducts
              .map((p) => p.category ?? '')
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();
          _categories.addAll(productCategories);
        }

        _items.addAll(newProducts);

        // check if more pages exist
        final int total = data['total'] ?? 0;
        if (total > 0) {
          _hasMore = _items.length < total;
        } else {
          _hasMore = newProducts.isNotEmpty;
        }

        if (_hasMore) _page++;
      } else {
        error = 'Fetch failed (${resp.statusCode}): ${resp.body}';
        debugPrint('❌ fetchProducts error: ${resp.body}');
      }
    } catch (e) {
      error = e.toString();
      debugPrint('❌ fetchProducts exception: $e');
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
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(p.toJson()),
      );

      if (resp.statusCode == 200) {
        await fetchProducts(reset: true);
        return true;
      } else {
        error = 'Add failed (${resp.statusCode}): ${resp.body}';
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('❌ addProduct exception: $e');
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
          'apikey': _anonKey,
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
          error = 'Variants linked to existing orders: $ids';
        } else {
          error = respData['error'] ?? 'Update failed with status 400';
        }
        return false;
      } else {
        error = 'Update failed (${resp.statusCode}): ${resp.body}';
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('❌ updateProduct exception: $e');
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
      final url =
          '$_supabaseUrl/rest/v1/master_product?product_id=eq.$productId';
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
        error = 'Delete failed (${resp.statusCode}): ${resp.body}';
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('❌ deleteProduct exception: $e');
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
        error = 'Delete variant failed (${resp.statusCode}): ${resp.body}';
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('❌ deleteVariant exception: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
