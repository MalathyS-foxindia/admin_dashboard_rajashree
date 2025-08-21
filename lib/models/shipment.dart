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

  factory Shipment.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('📦 [Shipment.fromJson] Parsing JSON data: $json');
    }

    // Check for null or invalid data before parsing
    final String? shipmentId = json['shipment_id']?.toString();
    final String? orderId = json['order_id']?.toString();
    final String? trackingNumber = json['tracking_number']?.toString();
    final String? shippingProvider = json['shipping_provider']?.toString();
    final String? trackingUrl = json['tracking_url']?.toString();
    final String? shippingStatus = json['shipping_status']?.toString();
    final String? remarks = json['remarks']?.toString();

    final DateTime? shippedDate = json['shipped_date'] != null
        ? DateTime.tryParse(json['shipped_date'])
        : null;
    final DateTime? deliveredDate = json['delivered_date'] != null
        ? DateTime.tryParse(json['delivered_date'])
        : null;
    final DateTime? createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null;
    final DateTime? updatedAt = json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'])
        : null;

    if (kDebugMode) {
      if (shippedDate == null) {
        print('⚠️ [Shipment.fromJson] Failed to parse shipped_date for order $orderId');
      }
    }

    return Shipment(
      shipmentId: shipmentId,
      orderId: orderId,
      trackingNumber: trackingNumber,
      shippingProvider: shippingProvider,
      trackingUrl: trackingUrl,
      shippingStatus: shippingStatus,
      remarks: remarks,
      shippedDate: shippedDate,
      deliveredDate: deliveredDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
