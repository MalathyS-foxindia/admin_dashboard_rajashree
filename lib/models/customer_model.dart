// lib/models/customer_model.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Customer {
  final int customerId;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String? address;
  final String? state; // from public.state enum
  final DateTime createdAt;
  final String? pincode;
  final String? passwordHash;

  Customer({
    required this.customerId,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.createdAt,
    this.address,
    this.state,

    this.pincode,
    this.passwordHash,

  });

  /// ---- FROM JSON ----
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: (json['customer_id'] as num?)?.toInt() ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      mobileNumber: (json['mobile_number'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      address: json['address']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      passwordHash: json['password_hash']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// ---- TO JSON ----
  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'email': email,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'address': address,
      'state': state,
      'pincode': pincode,
    };
  }

  /// ---- COPY WITH ----
  Customer copyWith({
    int? customerId,
    String? fullName,
    String? mobileNumber,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
    String? address,
    String? state,
    String? pincode,
  }) {
    return Customer(
      customerId: customerId ?? this.customerId,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
    );
  }
}
