class QueryModel {
  final int queryId;
  final int? customerId;
  final String name;          // ✅ added
  final String mobileNumber;
  final String? email;
  final String message;
  final String status;
  final DateTime createdAt;
  final String? remarks;


  QueryModel({
    required this.queryId,
    required this.customerId,
    required this.name,
    required this.mobileNumber,
    this.email,
    required this.message,
    required this.status,
    required this.createdAt,
    this.remarks,
  });

  QueryModel copyWith({
    int? queryId,
    int? customerId,
    String? name,
    String? mobileNumber,
    String? email,
    String? message,
    String? status,
    DateTime? createdAt,
    String? remarks,
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
      remarks: remarks ?? this.remarks,
    );
  }

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    return QueryModel(
      queryId: json['query_id'],
      customerId: json['customer_id'],
      name: json['name'] ?? '-', // ✅ fallback if null
      mobileNumber: json['mobile_number'],
      email: json['email'],
      message: json['message'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query_id': queryId,
      'customer_id': customerId,
      'name': name,
      'mobile_number': mobileNumber,
      'email': email,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'remarks': remarks,
    };
  }
}
