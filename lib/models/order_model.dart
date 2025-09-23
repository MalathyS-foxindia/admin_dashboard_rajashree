import 'customer_model.dart';

class Order {
  final String orderId;
  final String? customerId;

  final double totalAmount;
  final String source;
  final double shippingAmount;
  final String paymentMethod;
  final String paymentTransactionId;
  final String orderNote;
  final String name;
  final String shippingAddress;
  final String shippingState;
  final String shippingPincode;
  final String contactNumber;
  

  final String orderDate;
  final String orderStatus;

  // ✅ New fields
  final String? invoiceUrl;
  final String? shipmentStatus;

  // ✅ Embedded customer object
  final Customer? customer;

  Order({
    required this.orderDate,
    required this.orderId,
    this.customerId,
    required this.totalAmount,
    required this.source,
    required this.shippingAmount,
    required this.paymentMethod,
    required this.paymentTransactionId,
    required this.orderNote,
    required this.orderStatus,
    this.invoiceUrl,
    this.shipmentStatus,
    this.customer,
    required this.name,
    required this.shippingAddress,
    required this.shippingState,
    required this.contactNumber,
    required this.shippingPincode
  });

  factory Order.fromJson(Map<String, dynamic> json) {
  String? shipmentStatus;
  if (json['shipment_tracking'] != null &&
      (json['shipment_tracking'] as List).isNotEmpty) {
    shipmentStatus = json['shipment_tracking'][0]['shipping_status']?.toString();
  }

  return Order(
    orderDate: DateTime.parse(json['created_at'])
        .toLocal()
        .toString()
        .split(' ')[0],
    orderId: json['order_id'].toString(),
    customerId: json['customer_id']?.toString(),
    totalAmount: (json['total_amount'] as num).toDouble(),
    source: json['source']?.toString() ?? '',
    shippingAmount: (json['shipping_amount'] as num).toDouble(),
    paymentMethod: json['payment_method']?.toString() ?? '',
    paymentTransactionId: json['payment_transaction_id']?.toString() ?? '',
    orderNote: json['order_note']?.toString() ?? '',
    orderStatus: json['order_status']?.toString() ?? '',
    invoiceUrl: json['invoice_url']?.toString(),
    name: json['name']?.toString() ?? '',
    shippingAddress: json['shipping_address']?.toString() ?? '',
    shippingState: json['shipping_state']?.toString() ?? '',
    shippingPincode: json['shipping_pincode']?.toString() ?? '',
    contactNumber: json['contact_number']?.toString() ?? '',
    shipmentStatus: shipmentStatus,
    customer: json['customers'] != null
        ? Customer.fromJson(json['customers'])
        : null,
  );
}


  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'customer_id': customerId,
      'total_amount': totalAmount,
      'source': source,
      'shipping_amount': shippingAmount,
      'payment_method': paymentMethod,
      'payment_transaction_id': paymentTransactionId,
      'order_note': orderNote,
      'order_status': orderStatus,
      'invoice_url': invoiceUrl,
      'shipment_status': shipmentStatus,
      'name' : name,
      'shipping_address' :shippingAddress,
      'shipping_state' : shippingState,
      'shipping_pincode' : shippingPincode,
      'contact_number' : contactNumber,
      'customers': customer?.toJson(),
    };
  }
}
