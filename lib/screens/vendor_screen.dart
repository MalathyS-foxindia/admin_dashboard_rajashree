import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vendor_provider.dart';
import '../models/vendor_model.dart';
import '../screens/vendor_detials_screen.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<VendorProvider>().fetchVendors());
  }

  void _openAddVendorDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final gstCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final contactPersonCtrl = TextEditingController();
    final paymentTermsCtrl = TextEditingController();
    final bankAccountCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final panCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vendor'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Mandatory
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Vendor Name'),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Enter vendor name' : null,
                ),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Enter address' : null,
                ),
                TextFormField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Enter contact number' : null,
                ),

                // ✅ Optional
                TextFormField(
                  controller: gstCtrl,
                  decoration: const InputDecoration(labelText: "GST Number"),
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains("@")) {
                      return "Invalid email";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: contactPersonCtrl,
                  decoration:
                  const InputDecoration(labelText: "Contact Person"),
                ),
                TextFormField(
                  controller: paymentTermsCtrl,
                  decoration:
                  const InputDecoration(labelText: "Payment Terms"),
                ),
                TextFormField(
                  controller: bankAccountCtrl,
                  decoration: const InputDecoration(labelText: "Bank Account"),
                ),
                TextFormField(
                  controller: ifscCtrl,
                  decoration: const InputDecoration(labelText: "IFSC Code"),
                ),
                TextFormField(
                  controller: panCtrl,
                  decoration: const InputDecoration(labelText: "PAN Number"),
                ),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: "Notes"),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final vendor = Vendor(
                  vendor_id: 0,
                  name: nameCtrl.text,
                  address: addressCtrl.text,
                  contactNumber: contactCtrl.text,
                  gst: gstCtrl.text,
                  email: emailCtrl.text,
                  contactPerson: contactPersonCtrl.text,
                  paymentTerms: paymentTermsCtrl.text,
                  bankAccount: bankAccountCtrl.text,
                  ifsc: ifscCtrl.text,
                  panNumber: panCtrl.text,
                  notes: notesCtrl.text,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: null,
                );
                final success =
                await context.read<VendorProvider>().addVendor(vendor);
                if (!mounted) return;

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "✅ Vendor added successfully"
                          : "❌ Failed to add vendor",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorProvider>();

    // ✅ Apply search filter
    final vendors = provider.vendors
        .where((v) =>
        v.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendors"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text("Add New Vendor"),
              onPressed: _openAddVendorDialog,
            ),
          ),
        ],
      ),
    body: Container(
        decoration: const BoxDecoration(
      image: DecorationImage(
      image: AssetImage("images/bg.jpg"), // make sure bg.png is in assets/images
      fit: BoxFit.cover,
      ),
    ),
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by Vendor Name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim()),
            ),
          ),
          Expanded(
            child: vendors.isEmpty
                ? const Center(child: Text("No vendors available"))
                : ListView.builder(
              itemCount: vendors.length,
              itemBuilder: (ctx, i) {
                final vendor = vendors[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      vendor.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📞 ${vendor.contactNumber}"),
                        Text("📍 ${vendor.address}"),
                        Text(
                          "🕒 Updated: ${vendor.updatedAt != null ? vendor.updatedAt!.toLocal().toString().split(' ').first : "-"}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      vendor.isActive
                          ? Icons.check_circle
                          : Icons.block,
                      color: vendor.isActive
                          ? Colors.green
                          : Colors.red,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendorDetailsScreen(
                              vendorId: vendor.vendor_id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
     ),
    );
  }
}
