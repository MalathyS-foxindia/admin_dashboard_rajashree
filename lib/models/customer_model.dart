class Customer {
  final int customerId;
  final String? customerName;
  final String? mobileNumber;
  final String? email;
  final String? passwordHash;
  final DateTime? createdAt;
  final String? address;
  final String? state;
  final String? pincode;

  Customer({
    required this.customerId,
    this.customerName,
    this.mobileNumber,
    this.email,
    this.passwordHash,
    this.createdAt,
    this.address,
    this.state,
    this.pincode,
  });

  /// ---- JSON FROM SUPABASE ----
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id'] as int,
      customerName: json['full_name'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      email: json['email'] as String?,
      passwordHash: json['password_hash'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      address: json['address'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
    );
  }

  /// ---- TO JSON ----
  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'mobile_number': mobileNumber,
      'email': email,
      'password_hash': passwordHash,
      'created_at': createdAt?.toIso8601String(),
      'address': address,
      'state': state,
      'pincode': pincode,
    };
  }

  /// ---- COPY WITH ----
  Customer copyWith({
    int? customerId,
    String? customerName,
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
      customerName: customerName ?? this.customerName,
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
