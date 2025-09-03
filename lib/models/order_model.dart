
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
  final String orderStatus;

  // ✅ New fields from response
  final String? invoiceUrl;
  final String? shipmentStatus;

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
    required this.isGuest,
    required this.orderStatus,
    this.invoiceUrl,
    this.shipmentStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Get shipment status from array (if any)
    String? shipmentStatus;
    if (json['shipment_tracking'] != null &&
        (json['shipment_tracking'] as List).isNotEmpty) {
      shipmentStatus = json['shipment_tracking'][0]['shipping_status'];
    }

    return Order(
      orderDate: DateTime.parse(json['created_at'])
          .toLocal()
          .toString()
          .split(' ')[0],
      orderId: json['order_id'].toString(),
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name'] ?? '',
      address: json['address'] ?? '',
      state: json['State'] ?? '', // note: capital 'S' from your response
      mobileNumber: json['mobile_number']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num).toDouble(),
      source: json['source'] ?? '',
      shippingAmount: (json['shipping_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentTransactionId: json['payment_transaction_id']?.toString() ?? '',
      orderNote: json['order_note'] ?? '',
      isGuest: json['is_guest'] ?? false,
      orderStatus: json['order_status'] ?? '',
      invoiceUrl: json['invoice_url'],
      shipmentStatus: shipmentStatus,
    );
  }
}
