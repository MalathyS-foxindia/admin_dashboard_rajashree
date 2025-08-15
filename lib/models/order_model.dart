
class Order {
  final String orderId;
  final String? customerId;
  final String customerName;
  final String address;
  final String state;
  final String mobileNumber;
  final double totalAmount;
  final String source;
  final double shippingAmount;
  final String paymentMethod;
  final String paymentTransactionId;
  final String orderNote;
  final bool isGuest;
  final String orderDate;


  Order({
    required this.orderDate,
    required this.orderId,
    this.customerId,
    required this.customerName,
    required this.address,
    required this.state,
    required this.mobileNumber,
    required this.totalAmount,
    required this.source,
    required this.shippingAmount,
    required this.paymentMethod,
    required this.paymentTransactionId,
    required this.orderNote,
    required this.isGuest
  });

  factory Order.fromJson(Map<String, dynamic> json) {
  return Order(
    orderDate: DateTime.parse(json['created_at']).toLocal().toString().split(' ')[0],
    orderId:json['order_id'].toString(),
    customerId: json['customer_id']?.toString(), // 👈 Safe conversion
    customerName: json['customer_name'] ?? '',
    address: json['address'] ?? '',
    state: json['state'] ?? '',
    mobileNumber: json['mobile_number']?.toString() ?? '', // 👈 Convert int to string
    totalAmount: (json['total_amount'] as num).toDouble(),
    source: json['source'] ?? '',
    shippingAmount: (json['shipping_amount'] as num).toDouble(),
    paymentMethod: json['payment_method'] ?? '',
    paymentTransactionId: json['payment_transaction_id']?.toString() ?? '', // 👈 Convert
    orderNote: json['order_note'] ?? '',
    isGuest: json['is_guest'] ?? false
  );
}

}
