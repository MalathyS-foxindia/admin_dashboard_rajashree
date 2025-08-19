class Vendor {
  final String vendor_id;
  final String name;
  final String address;
  final String contactNumber;
  final String gst;
  Vendor({
    required this.name,
    required this.vendor_id,
    required this.address,  
    required this.contactNumber,
    required this.gst,
  });

  // Factory constructor to create a Vendor object from JSON.
  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      name: json['name'] as String? ?? 'N/A',
      address: json['address'] as String? ?? 'N/A',
      contactNumber: json['contact_number'] as String? ?? 'N/A',
      gst: json['gst'] as String? ?? 'N/A', vendor_id: json['vendor_id'] as String? ?? 'N/A',);
  }
}