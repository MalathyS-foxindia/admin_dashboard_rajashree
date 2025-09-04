import 'dart:io';
import 'package:admin_dashboard_rajshree/models/purchase_model.dart';
import 'package:admin_dashboard_rajshree/providers/purchase_provider.dart';
import 'package:admin_dashboard_rajshree/providers/vendor_provider.dart';
import 'package:admin_dashboard_rajshree/providers/product_provider.dart';
//import 'package:admin_dashboard_rajshree/services/file_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final int _pageSize = 10;
  int _currentPage = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Purchase> _filteredPurchases = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PurchaseProvider>(context, listen: false).fetchPurchases();
      Provider.of<VendorProvider>(context, listen: false).fetchVendors();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  void _filterAndPaginateData(List<Purchase> allPurchases) {
    setState(() {
      final lowerCaseQuery = _searchQuery.toLowerCase();
      _filteredPurchases = allPurchases.where((purchase) {
        return purchase.vendordetails.name
            .toLowerCase()
            .contains(lowerCaseQuery) ||
            purchase.invoiceNo.toLowerCase().contains(lowerCaseQuery);
      }).toList();
      _currentPage = 0;
    });
  }

  List<Purchase> get _paginatedPurchases {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    if (startIndex >= _filteredPurchases.length) return [];
    return _filteredPurchases.sublist(
      startIndex,
      endIndex > _filteredPurchases.length ? _filteredPurchases.length : endIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Report'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const AddPurchaseDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text("New Purchase"),
            ),
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Text(provider.errorMessage,
                  style: const TextStyle(color: Colors.red)),
            );
          }
          if (_filteredPurchases.isEmpty && _searchQuery.isEmpty) {
            _filteredPurchases = List.from(provider.purchases);
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by Vendor or Invoice No',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterAndPaginateData(provider.purchases);
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Purchase ID')),
                        DataColumn(label: Text('Invoice No')),
                        DataColumn(label: Text('Vendor Name')),
                        DataColumn(label: Text('Invoice Date')),
                        DataColumn(label: Text('Invoice Image')),
                        DataColumn(label: Text('Total Amount')),
                        DataColumn(label: Text('Item Count')),
                      ],
                      rows: _paginatedPurchases.map((purchase) {
                        return DataRow(cells: [
                          DataCell(Text(purchase.purchaseId.toString())),
                          DataCell(Text(purchase.invoiceNo)),
                          DataCell(Text(purchase.vendordetails.name)),
                          DataCell(Text(
                            purchase.invoiceDate != null
                                ? "${purchase.invoiceDate!.day}-${purchase.invoiceDate!.month}-${purchase.invoiceDate!.year}"
                                : "-",
                          )),
                          DataCell(
                            purchase.invoiceImage != null
                                ? Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Image.network(
                                          purchase.invoiceImage!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    purchase.invoiceImage!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download,
                                      color: Colors.blue),
                                  onPressed: () {
                                  //   FileService.downloadAndSaveImage(
                                  //     context,
                                  //     purchase.invoiceImage!,
                                  //     fileName:
                                  //     "invoice_${purchase.invoiceNo}.jpg",
                                  //   );
                                   },
                                )
                              ],
                            )
                                : const Text("-"),
                          ),
                          DataCell(Text(
                              '₹${purchase.totalAmount.toStringAsFixed(2)}')),
                          DataCell(Text('${purchase.items.length} items')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AddPurchaseDialog extends StatefulWidget {
  const AddPurchaseDialog({super.key});

  @override
  State<AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<AddPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final invoiceNoCtrl = TextEditingController();
  DateTime invoiceDate = DateTime.now();
  int? selectedVendorId;
  String? invoiceImageUrl;
  bool isUploading = false;

  List<Map<String, dynamic>> items = [];

  void _addItemRow() {
    setState(() {
      items.add({
        "variant": null,
        "quantity": 1,
        "unitPrice": 0.0,
      });
    });
  }

  /// ✅ Fixed: works for web + mobile
  Future<void> _pickAndUploadInvoiceImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}";
      final fileBytes = result.files.first.bytes;

      setState(() => isUploading = true);

      try {
        final storage = Supabase.instance.client.storage.from('invoice-images');

        if (fileBytes != null) {
          // ✅ Web (and also works on mobile if using `withData: true`)
          await storage.uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
        } else {
          // ✅ Mobile/Desktop only
          final filePath = result.files.first.path;
          if (filePath != null) {
            final file = File(filePath);
            await storage.upload(
              fileName,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
          } else {
            throw "No file data available";
          }
        }

        final url = storage.getPublicUrl(fileName);
        debugPrint("✅ Uploaded invoice URL: $url");

        setState(() {
          invoiceImageUrl = url;
          isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Invoice image uploaded")),
          );
        }
      } catch (e) {
        setState(() => isUploading = false);
        debugPrint("❌ Upload failed: $e");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Upload failed: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendors = context.watch<VendorProvider>().vendors;
    final products = context.watch<ProductProvider>().items;

    final total = items.fold<double>(
      0.0,
          (sum, item) =>
      sum + ((item["quantity"] ?? 1) * (item["unitPrice"] ?? 0.0)),
    );

    return AlertDialog(
      title: const Text("Add Purchase"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: invoiceNoCtrl,
                decoration: const InputDecoration(labelText: "Invoice No"),
                validator: (v) =>
                v == null || v.isEmpty ? "Enter Invoice No" : null,
              ),
              DropdownButtonFormField<int>(
                value: selectedVendorId,
                hint: const Text("Select Vendor"),
                items: vendors.map((v) {
                  return DropdownMenuItem<int>(
                    value: v.vendor_id,
                    child: Text(v.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedVendorId = val),
                validator: (v) => v == null ? "Select a vendor" : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Invoice Date: "),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: invoiceDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => invoiceDate = picked);
                      }
                    },
                    child: Text(
                        "${invoiceDate.year}-${invoiceDate.month}-${invoiceDate.day}"),
                  )
                ],
              ),
              const Divider(),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : _pickAndUploadInvoiceImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Invoice Image"),
                  ),
                  const SizedBox(width: 12),
                  if (invoiceImageUrl != null)
                    const Icon(Icons.check, color: Colors.green),
                  if (isUploading)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField(
                        value: item["variant"],
                        hint: const Text("Select SKU"),
                        items: products.expand((p) => p.variants ?? []).map((v) {
                          return DropdownMenuItem(
                            value: int.tryParse(v.id ?? "0"),
                            child: Text(v.sku),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => item["variant"] = val),
                        validator: (v) => v == null ? "Select SKU" : null,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item["quantity"].toString(),
                        decoration: const InputDecoration(labelText: "Qty"),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          item["quantity"] = int.tryParse(val) ?? 1;
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item["unitPrice"].toString(),
                        decoration:
                        const InputDecoration(labelText: "Unit Price"),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          item["unitPrice"] = double.tryParse(val) ?? 0.0;
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "₹${((item["quantity"] ?? 1) * (item["unitPrice"] ?? 0.0)).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          items.removeAt(index);
                        });
                      },
                    ),
                  ],
                );
              }).toList(),
              TextButton.icon(
                onPressed: _addItemRow,
                icon: const Icon(Icons.add),
                label: const Text("Add SKU"),
              ),
              const SizedBox(height: 12),
              Text("Total: ₹$total",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final provider = context.read<PurchaseProvider>();
            final success = await provider.addPurchase(
              invoiceNoCtrl.text,
              invoiceDate,
              selectedVendorId!,
              total,
              invoiceImageUrl, // ✅ will not be null now
              items,
            );

            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? "✅ Purchase Added"
                    : "❌ Failed to Add Purchase"),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
