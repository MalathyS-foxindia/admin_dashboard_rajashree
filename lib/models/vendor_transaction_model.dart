class VendorTransaction {
  final int transactionId;
  final int vendorId;
  final String purchaseId;
  final double amountPaid;
  final double balanceAmount;
  final String transactionDate;

  VendorTransaction({
    required this.transactionId,
    required this.vendorId,
    required this.purchaseId,
    required this.amountPaid,
    required this.balanceAmount,
    required this.transactionDate,
  });

  factory VendorTransaction.fromJson(Map<String, dynamic> json) {
    return VendorTransaction(
      transactionId: json['transaction_id'] ?? 0,
      vendorId: json['vendor_id'] ?? 0,
      purchaseId: json['purchase_id'] ?? '',
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: json['transaction_date'] ?? '',
    );
  }
}
