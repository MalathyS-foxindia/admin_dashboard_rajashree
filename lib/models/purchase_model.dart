
import 'package:admin_dashboard_rajshree/models/products_model.dart';
import 'package:admin_dashboard_rajshree/models/vendor_model.dart';

class PurchaseItems {
  final String purchaseId;
  final List<Variant> items;
  final int quantity;

  PurchaseItems({
    required this.purchaseId,
    required this.items,
    required this.quantity,
  });

  factory PurchaseItems.fromJson(Map<String, dynamic> json) {
    return PurchaseItems(
      purchaseId: json['purchase_id'] as String? ?? 'N/A',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => Variant.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class Purchase {
  final String purchaseId;
  final Vendor vendordetails;
  final String? vendorId;
  final double totalAmount;
  final List<PurchaseItems> items;

  Purchase({
    required this.purchaseId,
    required this.vendordetails,
    required this.totalAmount,
    required this.items,
    this.vendorId,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    // Parse vendor details safely
    final vendorData = json['vendor_details'] as Map<String, dynamic>?;
    final vendor = vendorData != null
        ? Vendor.fromJson(vendorData)
        : Vendor(name: 'N/A', vendor_id: '', address: '', contactNumber: '', gst: '');

    // Parse purchase items safely
    final purchaseItems = (json['purchase_items'] as List<dynamic>?)
            ?.map((item) => PurchaseItems.fromJson(item))
            .toList() ??
        [];

    return Purchase(
      purchaseId: json['purchase_id'] as String? ?? 'N/A',
      vendordetails: vendor,
      totalAmount:
          json['amount'] is num ? (json['amount'] as num).toDouble() : 0.0,
      items: purchaseItems,
      vendorId: json['vendor_id'] as String?,
    );
  }
}
  Map<String, dynamic> toJson(String purchaseId, Vendor vendordetails, double totalAmount, List<PurchaseItems> items, String? vendorId) {
    return {
      'purchase_id': purchaseId,
      'vendor_details': vendordetails,
      'amount': totalAmount,
      'purchase_items': items.map((item) => item).toList(),
      if (vendorId != null) 'vendor_id': vendorId,
    };
  }

