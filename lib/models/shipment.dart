// lib/models/shipment.dart

import 'package:flutter/foundation.dart';

class Shipment {
  final String? shipmentId;
  final String? orderId;
  final String? trackingNumber;
  final String? shippingProvider;
  final String? trackingUrl;
  final String? shippingStatus;
  final String? remarks;
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Shipment({
    this.shipmentId,
    this.orderId,
    this.trackingNumber,
    this.shippingProvider,
    this.trackingUrl,
    this.shippingStatus,
    this.remarks,
    this.shippedDate,
    this.deliveredDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory to create a Shipment from JSON
  factory Shipment.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('📦 [Shipment.fromJson] Parsing JSON data: $json');
    }

    final shipment = Shipment(
      shipmentId: json['shipment_id']?.toString(),
      orderId: json['order_id']?.toString(),
      trackingNumber: json['tracking_number']?.toString(),
      shippingProvider: json['shipping_provider']?.toString(),
      trackingUrl: json['tracking_url']?.toString(),
      shippingStatus: json['shipping_status']?.toString(),
      remarks: json['remarks']?.toString(),
      shippedDate: _parseDate(json['shipped_date']),
      deliveredDate: _parseDate(json['delivered_date']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );

    if (kDebugMode && shipment.shippedDate == null && json['shipped_date'] != null) {
      print('⚠️ [Shipment.fromJson] Failed to parse shipped_date for order ${shipment.orderId}');
    }

    return shipment;
  }

  /// Convert Shipment object to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'shipment_id': shipmentId,
      'order_id': orderId,
      'tracking_number': trackingNumber,
      'shipping_provider': shippingProvider,
      'tracking_url': trackingUrl,
      'shipping_status': shippingStatus,
      'remarks': remarks,
      // Ensure DATE type is sent as yyyy-MM-dd
      'shipped_date': shippedDate != null ? _formatDateOnly(shippedDate!) : null,
      'delivered_date': deliveredDate != null ? _formatDateOnly(deliveredDate!) : null,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Helper: Parse DATE or TIMESTAMP
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        if (value.length == 10) {
          // yyyy-MM-dd
          return DateTime.parse(value);
        } else {
          // ISO timestamp
          return DateTime.parse(value).toLocal();
        }
      }
      if (value is int) {
        // Epoch timestamp
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to parse date: $value, error: $e");
      }
    }
    return null;
  }

  /// Helper: Format date to yyyy-MM-dd (for DATE columns in Supabase)
  static String _formatDateOnly(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }
}
