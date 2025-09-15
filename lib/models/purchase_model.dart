import 'package:admin_dashboard_rajashree/models/products_model.dart';
import 'package:admin_dashboard_rajashree/models/vendor_model.dart';

class PurchaseItem {
  final int purchaseItemId;
  final int purchaseId;
  final int variantId;
  final int quantity;
  final double costPrice;
  final Variant? variant; // joined product_variants info

  PurchaseItem({
    required this.purchaseItemId,
    required this.purchaseId,
    required this.variantId,
    required this.quantity,
    required this.costPrice,
    this.variant,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      purchaseItemId: (json['purchase_item_id'] as num?)?.toInt() ?? 0,
      purchaseId: (json['purchase_id'] as num?)?.toInt() ?? 0,
      variantId: (json['variant_id'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      variant: json['product_variants'] != null
          ? Variant.fromJson(json['product_variants'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchase_id': purchaseId,
      'variant_id': variantId,
      'quantity': quantity,
      'cost_price': costPrice,
    };
  }
}

class Purchase {
  final int purchaseId;
  final String invoiceNo;
  final DateTime invoiceDate;
  final String? invoiceImage;
  final int vendorId;
  final Vendor vendordetails;
  final double totalAmount;
  final DateTime? purchaseDate;
  final List<PurchaseItem> items;

  Purchase({
    required this.purchaseId,
    required this.invoiceNo,
    required this.invoiceDate,
    this.invoiceImage,
    required this.vendorId,
    required this.vendordetails,
    required this.totalAmount,
    this.purchaseDate,
    required this.items,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final vendorData = json['vendor'] as Map<String, dynamic>?;

    final vendor = vendorData != null
        ? Vendor.fromJson(vendorData)
        : Vendor(
      vendor_id: 0,
      name: 'N/A',
      address: '',
      contactNumber: '',
      gst: '',
      createdAt: DateTime.now(),
      updatedAt: null,
    );

    final itemsData = json['purchase_items'] as List<dynamic>?;

    return Purchase(
      purchaseId: (json['purchase_id'] as num?)?.toInt() ?? 0,
      invoiceNo: json['invoice_no'] ?? '',
      invoiceDate: DateTime.tryParse(json['invoice_date'].toString()) ??
          DateTime.now(),
      invoiceImage: json['invoice_image'],
      vendorId: (json['vendor_id'] as num?)?.toInt() ?? 0,
      vendordetails: vendor,
      totalAmount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString())
          : null,
      items: itemsData != null
          ? itemsData.map((e) => PurchaseItem.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_no': invoiceNo,
      'invoice_date': invoiceDate.toIso8601String(),
      'invoice_image': invoiceImage,
      'vendor_id': vendorId,
      'amount': totalAmount,
      'purchase_date': purchaseDate?.toIso8601String(),
    };
  }
}
