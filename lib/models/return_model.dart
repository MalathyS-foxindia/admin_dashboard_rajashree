import 'dart:convert';

class ReturnModel {
  final int returnId;
  final String? orderId;
  final DateTime? returnDate;
  final String status;
  final String? reason;
  final String? returnedItems; // ✅ newly added
  final double? refundAmount;
  final DateTime createdAt;

  ReturnModel({
    required this.returnId,
    this.orderId,
    this.returnDate,
    required this.status,
    this.reason,
    this.returnedItems,
    this.refundAmount,
    required this.createdAt,
  });

  /// ✅ From JSON (Supabase → Flutter)
  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    return ReturnModel(
      returnId: json['return_id'] is int
          ? json['return_id']
          : int.tryParse(json['return_id'].toString()) ?? 0,
      orderId: json['order_id']?.toString(),
      returnDate: json['return_date'] != null
          ? DateTime.tryParse(json['return_date'])
          : null,
      status: json['status']?.toString() ?? 'Requested',
      reason: json['reason']?.toString(),
      returnedItems: json['returned_items']?.toString(),
      refundAmount: json['refund_amount'] != null
          ? double.tryParse(json['refund_amount'].toString())
          : null,
      createdAt: (json['created_at'] != null &&
          json['created_at'].toString().isNotEmpty)
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// ✅ To JSON (Flutter → Supabase)
  Map<String, dynamic> toJson() {
    return {
      'return_id': returnId,
      'order_id': orderId,
      'return_date': returnDate?.toIso8601String(),
      'status': status,
      'reason': reason,
      'returned_items': returnedItems,
      'refund_amount': refundAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// ✅ Helper to duplicate with modified fields (used in provider)
  ReturnModel copyWith({
    int? returnId,
    String? orderId,
    DateTime? returnDate,
    String? status,
    String? reason,
    String? returnedItems,
    double? refundAmount,
    DateTime? createdAt,
  }) {
    return ReturnModel(
      returnId: returnId ?? this.returnId,
      orderId: orderId ?? this.orderId,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      returnedItems: returnedItems ?? this.returnedItems,
      refundAmount: refundAmount ?? this.refundAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// ✅ Encode/Decode helper (optional)
  static List<ReturnModel> listFromJson(String jsonStr) {
    final List<dynamic> data = json.decode(jsonStr);
    return data.map((e) => ReturnModel.fromJson(e)).toList();
  }

  static String listToJson(List<ReturnModel> list) {
    return json.encode(list.map((e) => e.toJson()).toList());
  }
}
