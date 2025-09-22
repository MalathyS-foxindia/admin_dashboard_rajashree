// lib/models/customer_model.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Customer {
  final int customerId;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String? address;
  final String? state; // from public.state enum
  final String? pinCode;
  final DateTime createdAt;

  Customer({
    required this.customerId,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.createdAt,
    this.address,
    this.state,
    this.pinCode
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: (json['customer_id'] as num?)?.toInt() ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      mobileNumber: (json['mobile_number'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      address: json['address']?.toString(),
      state: json['state']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
