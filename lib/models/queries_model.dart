class QueryModel {
  final int queryId;
  final int? customerId;
  final String name;          // ✅ added
  final String mobileNumber;
  final String? email;
  final String message;
  final String status;
  final DateTime createdAt;

  QueryModel({
    required this.queryId,
    this.customerId,
    required this.name,       // ✅ required
    required this.mobileNumber,
    this.email,
    required this.message,
    required this.status,
    required this.createdAt,
  });

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
    };
  }
}
