import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_dashboard_rajashree/models/Env.dart';
import '../models/products_model.dart';

class ProductProvider with ChangeNotifier {
  final String _supabaseUrl = Env.supabaseUrl ?? '';
  final String _anonKey = Env.anonKey ?? '';
  final supabase = Supabase.instance.client;
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

  // 🟩 NEW: Maintain subcategories list
  final List<String> _subcategories = [];
  List<String> get subcategories => List.unmodifiable(_subcategories); // 🟩 NEW

  int _page = 1;
  int _limit = 10;
  int _total = 0;

  int get currentPage => _page;
  int get limit => _limit;
  int get totalItems => _total;
  int get totalPages => (_total / _limit).ceil();
  bool get hasMore => _page < totalPages;

  List<Variant> _allVariants = [];
  List<Variant> get variants => _allVariants;

  /// ---------------------------
  /// SETTERS
  /// ---------------------------
  void setPageSize(int size, {String? search, int? category}) {
    _limit = size;
    _page = 1;
    fetchProducts(reset: true, search: search, category_id: category);
  }

  void nextPage({String? search, int? category}) {
    if (hasMore) {
      _page++;
      fetchProducts(reset: true, search: search, category_id: category);
    }
  }

  void previousPage({String? search, int? category}) {
    if (_page > 1) {
      _page--;
      fetchProducts(reset: true, search: search, category_id: category);
    }
  }

  List<String> subcategorieslist = [];
  Future<void> fetchSubcategories() async {
    final res = await supabase.from('subcategories').select('name');
    subcategorieslist = (res as List).map((s) => s['name'].toString()).toList();
    notifyListeners();
  }

  /// ---------------------------
  /// FETCH PRODUCTS
  /// ---------------------------
  Future<void> fetchProducts({
    bool reset = false,
    String? search,
    int? category_id,
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
        if (category_id != null) 'category': category_id,
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

        // 🟩 Update category & subcategory lists (only on reset)
        if (reset) {
          _categories // 🟩 NEW
            ..clear()
            ..addAll(
              newProducts
                  .map(
                    (p) => p.subcategoryName ?? '',
                  ) //need logic to fetch category name
                  .where((s) => s.isNotEmpty)
                  .toSet()
                  .toList(),
            );
          _subcategories // 🟩 NEW
            ..clear()
            ..addAll(
              newProducts
                  .map((p) => p.subcategoryName ?? '')
                  .where((s) => s.isNotEmpty)
                  .toSet()
                  .toList(),
            );
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
        body: jsonEncode(p.toJson()), // 🟩 includes subcategory fields now
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

  List<Map<String, dynamic>> categoriesWithSubs = [];

  Future<void> fetchCategoriesWithSubcategories() async {
    try {
      const url =
          'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/getCategories';
      // 👆 replace this with your actual REST endpoint or view name

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_anonKey', // 👈 same key for anon access
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic>? list;

        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic>) {
          // handle wrapped response like { categories: [...] } or { data: [...] }
          list = data['categories'] ?? data['data'];
        }

        if (list != null) {
          categoriesWithSubs = List<Map<String, dynamic>>.from(list);
          print('Fetched categories with subcategories: $categoriesWithSubs');
          notifyListeners();
        } else {
          print('⚠️ No valid list found in response: $data');
        }
      }
    } catch (e, st) {
      print('❌ fetchCategoriesWithSubcategories error: $e');
      print(st);
    }
  }

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

      // maybeSingle() returns null when there's no row
      if (existingRes == null) {
        error = "Variant not found";
        notifyListeners();
        return false;
      }

      // existingRes is expected to be a Map-like object
      final int existingStock = (existingRes['stock'] ?? 0) is int
          ? existingRes['stock']
          : (existingRes['stock'] ?? 0).toInt();

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

      // updateRes may be a list of rows; treat empty result as failure
      if (updateRes == null || (updateRes is List && updateRes.isEmpty)) {
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
        body: jsonEncode(p.toJson()), // 🟩 includes subcategoryId/name
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
}
