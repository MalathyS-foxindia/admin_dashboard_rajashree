class Vendor {
  final int vendor_id;
  final String name;
  final String address;
  final String contactNumber;
  final String gst;
  final String? email;
  final String? contactPerson;
  final String? paymentTerms;
  final String? bankAccount;
  final String? ifsc;
  final String? panNumber;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt; // ✅ nullable now

  Vendor({
    required this.vendor_id,
    required this.name,
    required this.address,
    required this.contactNumber,
    required this.gst,
    this.email,
    this.contactPerson,
    this.paymentTerms,
    this.bankAccount,
    this.ifsc,
    this.panNumber,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt, // ✅ optional
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      vendor_id: (json['vendor_id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      gst: json['gst'] ?? '',
      email: json['email'],
      contactPerson: json['contact_person'],
      paymentTerms: json['payment_terms'],
      bankAccount: json['bank_account'],
      ifsc: json['ifsc'],
      panNumber: json['pan_number'],
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendor_id,
      'name': name,
      'address': address,
      'contact_number': contactNumber,
      'gst': gst,
      'email': email,
      'contact_person': contactPerson,
      'payment_terms': paymentTerms,
      'bank_account': bankAccount,
      'ifsc': ifsc,
      'pan_number': panNumber,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// ✅ Use this when inserting (exclude auto-generated fields)
extension VendorInsert on Vendor {
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'address': address,
      'contact_number': contactNumber,
      'gst': gst,
      'email': email,
      'contact_person': contactPerson,
      'payment_terms': paymentTerms,
      'bank_account': bankAccount,
      'ifsc': ifsc,
      'pan_number': panNumber,
      'notes': notes,
      'is_active': isActive,
    };
  }
}
