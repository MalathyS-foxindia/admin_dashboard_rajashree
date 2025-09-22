
import 'dart:js_interop';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'customer_model.dart';

class Order {
  final String orderId;
  final String? customerId;

  final double totalAmount;
  final String source;
  final double shippingAmount;
  final String paymentMethod;
  final String paymentTransactionId;
  final String orderNote;

  final String orderDate;
  final String orderStatus;

  // ✅ New fields
  final String? invoiceUrl;
  final String? shipmentStatus;

  // ✅ Embedded customer object
  final Customer? customer;

  Order({
    required this.orderDate,
    required this.orderId,
    this.customerId,
    required this.totalAmount,
    required this.source,
    required this.shippingAmount,
    required this.paymentMethod,
    required this.paymentTransactionId,
    required this.orderNote,
    required this.orderStatus,
    this.invoiceUrl,
    this.shipmentStatus,
    this.customer,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Extract shipment status (from array if present)
    String? shipmentStatus;
    if (json['shipment_tracking'] != null &&
        (json['shipment_tracking'] as List).isNotEmpty) {
      shipmentStatus = json['shipment_tracking'][0]['shipping_status'];
    }

    return Order(
      orderDate: DateTime.parse(json['created_at'])
          .toLocal()
          .toString()
          .split(' ')[0],
      orderId: json['order_id'].toString(),
      customerId: json['customer_id']?.toString(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      source: json['source'] ?? '',
      shippingAmount: (json['shipping_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentTransactionId: json['payment_transaction_id']?.toString() ?? '',
      orderNote: json['order_note'] ?? '',
      orderStatus: json['order_status'] ?? '',
      invoiceUrl: json['invoice_url'],
      shipmentStatus: shipmentStatus,
      // ✅ parse embedded customer if present
      customer: json['customers'] != null
          ? Customer.fromJson(json['customers'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'customer_id': customerId,
      'total_amount': totalAmount,
      'source': source,
      'shipping_amount': shippingAmount,
      'payment_method': paymentMethod,
      'payment_transaction_id': paymentTransactionId,
      'order_note': orderNote,
      'order_status': orderStatus,
      'invoice_url': invoiceUrl,
      'shipment_status': shipmentStatus,
      'customers': customer,
    };
  }
}
