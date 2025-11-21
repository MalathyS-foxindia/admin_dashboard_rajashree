// lib/models/queries_model.dart
import 'package:flutter/foundation.dart';

class QueryModel {
  final int queryId;
  final int? customerId;
  final String name;
  final String mobileNumber;
  final String? email; // main email used in UI (query/customer merged)
  final String message;
  final String status; // e.g. Open, In Progress, Resolved, Closed
  final DateTime createdAt;
  final String? priority; // High / Medium / Low / custom
  final String? orderId;
  final String? remarks;

  // ---- Joined / derived fields ----
  final DateTime? orderDate;   // from orders.created_at or RPC alias order_date
  final String? customerEmail; // from customers.email or RPC alias customer_email

  QueryModel({
    required this.queryId,
    this.customerId,
    required this.name,
    required this.mobileNumber,
    this.email,
    required this.message,
    required this.status,
    required this.createdAt,
    this.priority,
    this.orderId,
    this.remarks,
    this.orderDate,
    this.customerEmail,
  });

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      // Helpful log to see raw server data for debugging
      debugPrint('🟢 QueryModel.fromJson RAW → $json');
    }

    // Supabase nested objects (if you ever use joins in select)
    final Map<String, dynamic>? orderJson =
    json['orders'] is Map<String, dynamic>
        ? json['orders'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? customerJson =
    json['customers'] is Map<String, dynamic>
        ? json['customers'] as Map<String, dynamic>
        : null;

    // safe parsing (handles ints/strings/nulls)
    int id;
    if (json['query_id'] is int) {
      id = json['query_id'] as int;
    } else if (json['query_id'] is String) {
      id = int.tryParse(json['query_id']) ?? 0;
    } else {
      id = 0;
    }

    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    final created = json['created_at'] != null
        ? _parseDate(json['created_at'])
        : DateTime.now();

    // Determine priority default: order_id => High else Medium
    String? priority = json['priority']?.toString();
    if (priority == null || priority.trim().isEmpty) {
      priority =
      (json['order_id'] != null && json['order_id'].toString().isNotEmpty)
          ? 'High'
          : 'Medium';
    }

    // 🔵 ORDER DATE HANDLING
    // 1) If nested orders(...) was used
    // 2) Else if RPC returned flat "order_date"
    DateTime? orderDate;
    if (orderJson != null && orderJson['order_date'] != null) {
      orderDate = DateTime.tryParse(orderJson['order_date'].toString());
    } else if (json['order_date'] != null) {
      orderDate = DateTime.tryParse(json['order_date'].toString());
    }

    // 🟣 CUSTOMER EMAIL HANDLING
    // 1) If nested customers(...) was used
    // 2) Else if RPC returned flat "customer_email"
    String? customerEmail;
    if (customerJson != null) {
      customerEmail = customerJson['email']?.toString();
    } else if (json['customer_email'] != null) {
      customerEmail = json['customer_email']?.toString();
    }

    // Base email (from queries table or RPC merged email)
    final String? baseEmail = json['email']?.toString();

    return QueryModel(
      queryId: id,
      customerId: (json['customer_id'] is int)
          ? json['customer_id'] as int
          : (json['customer_id'] is String
          ? int.tryParse(json['customer_id'])
          : null),
      name: json['name']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      // Prefer customerEmail if present, else base email
      email: customerEmail?.isNotEmpty == true
          ? customerEmail
          : (baseEmail?.isNotEmpty == true ? baseEmail : null),
      message: json['message']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'Open'),
      createdAt: created,
      priority: priority,
      orderId: json['order_id']?.toString(),
      remarks: json['remarks']?.toString(),
      orderDate: orderDate,
      customerEmail: customerEmail,
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'customer_id': customerId,
      'name': name,
      'mobile_number': mobileNumber,
      'email': email,
      'message': message,
      'status': status,
      'priority': priority,
      'order_id': orderId,
      'remarks': remarks,
      // NOTE: joined fields (orderDate, customerEmail) are NOT sent on insert
    };
  }

  QueryModel copyWith({
    int? queryId,
    int? customerId,
    String? name,
    String? mobileNumber,
    String? email,
    String? message,
    String? status,
    DateTime? createdAt,
    String? priority,
    String? orderId,
    String? remarks,
    DateTime? orderDate,
    String? customerEmail,
  }) {
    return QueryModel(
      queryId: queryId ?? this.queryId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      orderId: orderId ?? this.orderId,
      remarks: remarks ?? this.remarks,
      orderDate: orderDate ?? this.orderDate,
      customerEmail: customerEmail ?? this.customerEmail,
    );
  }
}
