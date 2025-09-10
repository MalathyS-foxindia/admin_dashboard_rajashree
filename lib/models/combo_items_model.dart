import 'products_model.dart';

class ComboItem {
  final int comboId;
  final int? comboItemId; // nullable
  final int quantityPerCombo;
  final String? variantId;
  final Variant? productVariants;

  const ComboItem({
    required this.comboId,
    this.comboItemId,
    required this.quantityPerCombo,
    required this.variantId,
   this.productVariants,
  });

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    return ComboItem(
      comboId: _asInt(json['combo_id']),
      comboItemId: json['combo_item_id'] != null
          ? _asInt(json['combo_item_id'])
          : null,
      quantityPerCombo: _asInt(json['quantity_per_combo']),
      variantId: json['variant_id']?.toString(), // ✅ safe String conversion
      productVariants: Variant.fromJson(
        (json['product_variants'] as Map<String, dynamic>? ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'combo_id': comboId,
        'combo_item_id': comboItemId,
        'quantity_per_combo': quantityPerCombo,
        'variant_id': variantId
      };

  ComboItem copyWith({
    int? comboId,
    int? comboItemId,
    int? quantityPerCombo,
    String? variantId,
    Variant? productVariants
  }) {
    return ComboItem(
      comboId: comboId ?? this.comboId,
      comboItemId: comboItemId ?? this.comboItemId,
      quantityPerCombo: quantityPerCombo ?? this.quantityPerCombo,
      variantId: variantId ?? this.variantId,
       productVariants: productVariants ?? this.productVariants
    );
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
