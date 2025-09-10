import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/products_model.dart';

class ProductProvider with ChangeNotifier {
  final String _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String _anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  ProductProvider() {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      debugPrint('⚠️ Supabase URL or keys are missing in .env');
    }
  }

  /// ---------------------------
  /// STATE
  /// ---------------------------
  bool isLoading = false;
  String? error;

  final List<Product> _items = [];
  List<Product> get items => List.unmodifiable(_items);

  final List<String> _categories = [];
  List<String> get categories => List.unmodifiable(_categories);

  int _page = 1;
  int _limit = 10;
  int _total = 0;

  int get currentPage => _page;
  int get limit => _limit;
  int get totalItems => _total;
  int get totalPages => (_total / _limit).ceil();
  bool get hasMore => _page < totalPages;

  /// ---------------------------
  /// VARIANTS
  /// ---------------------------
  List<Variant> _allVariants = [];
  List<Variant> get variants => _allVariants;

  /// ---------------------------
  /// SETTERS
  /// ---------------------------
  void setPageSize(int size, {String? search, String? category}) {
    _limit = size;
    _page = 1;
    fetchProducts(reset: true, search: search, category: category);
  }

  void nextPage({String? search, String? category}) {
    if (hasMore) {
      _page++;
      fetchProducts(reset: true, search: search, category: category);
    }
  }

  void previousPage({String? search, String? category}) {
    if (_page > 1) {
      _page--;
      fetchProducts(reset: true, search: search, category: category);
    }
  }

  /// ---------------------------
  /// FETCH PRODUCTS
  /// ---------------------------
  Future<void> fetchProducts({
    bool reset = false,
    String? search,
    String? category,
  }) async {
    if (isLoading) return;

    if (reset) {
      _items.clear();
      error = null;
      notifyListeners();
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

      debugPrint('📡 Fetching products: $uri');

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

        final List<dynamic> jsonList = data['data'] ?? [];
        final newProducts = jsonList
            .map((j) => Product.fromJson(j as Map<String, dynamic>))
            .toList();

        _total = data['total'] ?? newProducts.length;

        _items
          ..clear()
          ..addAll(newProducts);

        // 🔹 Update categories (first load only)
        if (reset) {
          _categories
            ..clear()
            ..addAll(newProducts
                .map((p) => p.category ?? '')
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList());
        }

        // 🔹 Collect all variants
        _allVariants = newProducts
    .expand<Variant>((p) => p.variants ?? <Variant>[])
    .toList();

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

  /// ---------------------------
  /// CREATE
  /// ---------------------------
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

  /// ---------------------------
  /// UPDATE PRODUCT
  /// ---------------------------
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

  /// ---------------------------
  /// TOGGLE VARIANT ACTIVE/INACTIVE
  /// ---------------------------
  Future<bool> updateVariantStatus(String variantId, bool isActive) async {
    try {
      final url =
          '$_supabaseUrl/rest/v1/product_variants?variant_id=eq.$variantId';
      final resp = await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({'is_Active': isActive}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        for (var product in _items) {
          final idx = product.variants?.indexWhere((v) => v.id == variantId) ?? -1;
          if (idx != -1) {
            product.variants![idx] =
                product.variants![idx].copyWith(isActive: isActive);

            final allInactive = product.variants!.every((v) => v.isActive == false);
            product.isActive = !allInactive;
            break;
          }
        }
        notifyListeners();
        return true;
      } else {
        error = 'Update variant failed (${resp.statusCode}): ${resp.body}';
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('❌ updateVariantStatus exception: $e');
      return false;
    }
  }

  /// ---------------------------
  /// ADJUST VARIANT STOCK
  /// ---------------------------
  Future<bool> adjustVariantStock({
    required String? variantId,
    required int stock,
    required String reason,
  }) async {
    if (variantId == null) return false;

    try {
      final supabase = Supabase.instance.client;

      // 🔹 Step 1: Get existing stock
      final existingRes = await supabase
          .from('product_variants')
          .select('stock')
          .eq('variant_id', variantId)
          .maybeSingle();

      if (existingRes == null) {
        error = "Variant not found";
        notifyListeners();
        return false;
      }

      final int existingStock = existingRes['stock'] ?? 0;

      // 🔹 Step 2: Calculate difference
      final int diff = stock - existingStock;
      if (diff == 0) {
        error = "No stock change detected";
        notifyListeners();
        return false;
      }

      final String changeType = diff > 0 ? "IN" : "OUT";

      // 🔹 Step 3: Update product_variant
      final updateRes = await supabase
          .from('product_variants')
          .update({'stock': stock})
          .eq('variant_id', variantId)
          .select();

      if (updateRes.isEmpty) {
        error = "Failed to update stock";
        notifyListeners();
        return false;
      }

      // 🔹 Step 4: Insert into stock_ledger
      await supabase.from('stock_ledger').insert({
        'variant_id': variantId,
        'change_type': changeType,
        'quantity': diff.abs(),
        'reference_type': 'Manual Adjustment',
        'reference_id': variantId,
        'note': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
