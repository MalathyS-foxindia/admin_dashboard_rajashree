class VendorTransaction {
  final int? transactionId; // ✅ Nullable so DB auto-generates it
  final int vendorId;
  final int? purchaseId; // ✅ int now, nullable
  final double amountPaid;
  final double balanceAmount;
  final String transactionDate;
  final String? comment; // ✅ new field

  VendorTransaction({
    required this.transactionId,
    required this.vendorId,
    this.purchaseId,
    required this.amountPaid,
    required this.balanceAmount,
    required this.transactionDate,
    this.comment,
  });

  factory VendorTransaction.fromJson(Map<String, dynamic> json) {
    return VendorTransaction(
      transactionId: json['transaction_id'] ?? 0,
      vendorId: json['vendor_id'] ?? 0,
      purchaseId: json['purchase_id'] as int?, // ✅ safe cast
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: json['transaction_date'] ?? '',
      comment: json['comment'], // ✅ parse from API
    );
  }
  Map<String, dynamic> toInsertJson() {
    return {
      if (vendorId != 0) 'vendor_id': vendorId,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (amountPaid != null) 'amount_paid': amountPaid,
      if (balanceAmount != null) 'balance_amount': balanceAmount,
      'transaction_date': transactionDate,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}
