// lib/models/combo_model.dart
import 'dart:convert';
import 'combo_items_model.dart';

class Combo {
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final int comboQuantity; // number of pieces/items advertised in the combo
  final int price;         // ₹ in paise? (here: using the integer you provide)
  final int comboId;
  final String sku;
  final bool isActive;
  final List<ComboItem> items;

  const Combo({
    required this.name,
    this.description,
    this.imageUrl,
    this.createdAt,
    required this.comboQuantity,
    required this.price,
    required this.comboId,
    required this.sku,
    required this.isActive,
    required this.items,
  });

  /// Factory for empty combo (safe defaults)
  factory Combo.empty() {
    return const Combo(
      comboId: 0,
      sku: '',
      name: '',
      description: '',
      price: 0,
      comboQuantity: 0,
      isActive: true,
      items: [],
    );
  }

  /// Parse a single Combo from JSON (Map)
  factory Combo.fromJson(Map<String, dynamic> json) {
    return Combo(
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: _asDateTime(json['created_at']),
      comboQuantity: _asInt(json['combo_quantity']),
      price: _asInt(json['price']),
      comboId: _asInt(json['combo_id']),
      sku: (json['sku'] ?? '') as String,
      isActive: _asBool(json['is_active']),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ComboItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert Combo back to JSON (Map)
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'created_at': createdAt?.toIso8601String(),
        'combo_quantity': comboQuantity,
        'price': price,
        'combo_id': comboId,
        'sku': sku,
        'is_active': isActive,
        'items': items.map((e) => e.toJson()).toList(),
      };

  /// Handy helpers
  int get totalDistinctItems => items.length;

  /// Sum of quantity_per_combo across items (how many units needed for one combo)
  int get totalUnitsRequiredForOneCombo =>
      items.fold(0, (sum, it) => sum + it.quantityPerCombo);

  /// CopyWith for updates
  Combo copyWith({
    String? name,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    int? comboQuantity,
    int? price,
    int? comboId,
    String? sku,
    bool? isActive,
    List<ComboItem>? items,
  }) {
    return Combo(
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      comboQuantity: comboQuantity ?? this.comboQuantity,
      price: price ?? this.price,
      comboId: comboId ?? this.comboId,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      items: items ?? this.items,
    );
  }

  /// Parse a JSON array string -> List<Combo>
  static List<Combo> listFromJsonString(String jsonStr) {
    final data = jsonDecode(jsonStr);
    if (data is List) {
      return data.map((e) => Combo.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }
}

/// ---------- helpers ----------
int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

num _asNum(dynamic v, [num fallback = 0]) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? fallback;
  return fallback;
}

bool _asBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

DateTime? _asDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}
