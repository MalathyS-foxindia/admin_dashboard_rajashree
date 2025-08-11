class OrderItem {
  final String? variantId;
  final int quantity;
  final bool isCombo;
  final Map<String, dynamic>? productVariants;

  OrderItem({
    required this.variantId,
    required this.quantity,
    required this.isCombo,
    this.productVariants,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      variantId: json['catalogue_product_id']?.toString(), // ✅ handles both int and string
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0, // ✅ fallback to 0
      isCombo: json['is_combo'] == true || json['is_combo'] == 1, // ✅ support both bool and int (e.g. 0/1)
      productVariants: json['product_variants'],
    );
  }
}
