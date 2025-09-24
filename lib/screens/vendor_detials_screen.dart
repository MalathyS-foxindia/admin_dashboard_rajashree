import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vendor_provider.dart';
import '../models/vendor_transaction_model.dart';

class VendorDetailsScreen extends StatefulWidget {
  final int vendorId;
  const VendorDetailsScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<VendorProvider>().fetchVendorTransactions(widget.vendorId));
  }

  /// 📌 Record Payment Dialog (supports Manual + Invoice-based)
  void _openPaymentDialog() async {
    final _formKey = GlobalKey<FormState>();

    // Controls
    final paidCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    // For invoice-based mode
    int? selectedPurchaseId;
    double invoiceTotal = 0;
    double alreadyPaid = 0;
    double remainingBalance = 0;

    // Fetch unpaid invoices
    final invoices =
    await context.read<VendorProvider>().fetchUnpaidInvoices(widget.vendorId);

    // Toggle mode: false = Manual, true = Invoice-based
    bool useInvoice = invoices.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Record Payment"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔘 Toggle between Manual / Invoice Payment
                  Row(
                    children: [
                      /*Expanded(
                        child: RadioListTile<bool>(
                          value: false,
                          groupValue: useInvoice,
                          title: const Text("Manual"),
                          onChanged: (val) {
                            setState(() {
                              useInvoice = val ?? false;
                              selectedPurchaseId = null;
                              invoiceTotal = 0;
                              alreadyPaid = 0;
                              remainingBalance = 0;
                            });
                          },
                        ),
                      ),*/
                      Expanded(
                        child: RadioListTile<bool>(
                          value: true,
                          groupValue: useInvoice,
                          title: const Text("By Invoice"),
                          onChanged: (val) {
                            setState(() => useInvoice = val ?? true);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 📑 Invoice Dropdown if "By Invoice" selected
                  if (useInvoice)
                    DropdownButtonFormField<int>(
                      value: selectedPurchaseId,
                      hint: const Text("Select Invoice"),
                      items: invoices.map<DropdownMenuItem<int>>((inv) {
                        final invNo = inv['invoice_no']?.toString() ?? "-";
                        final amount =
                            (inv['amount'] as num?)?.toDouble() ?? 0.0;
                        final paid =
                            (inv['paid'] as num?)?.toDouble() ?? 0.0;
                        final bal =
                            (inv['balance'] as num?)?.toDouble() ?? 0.0;
                        return DropdownMenuItem<int>(
                          value: inv['purchase_id'] as int,
                          child: Text("$invNo (₹$bal left)"),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedPurchaseId = val;
                          final inv = invoices.firstWhere(
                                  (i) => i['purchase_id'] == val,
                              orElse: () => {});
                          invoiceTotal =
                              (inv['amount'] as num?)?.toDouble() ?? 0.0;
                          alreadyPaid =
                              (inv['paid'] as num?)?.toDouble() ?? 0.0;
                          remainingBalance =
                              (inv['balance'] as num?)?.toDouble() ?? 0.0;
                        });
                      },
                      validator: (v) {
                        if (useInvoice && v == null) {
                          return "Select invoice";
                        }
                        return null;
                      },
                    ),

                  if (useInvoice && selectedPurchaseId != null) ...[
                    const SizedBox(height: 8),
                    Text("Invoice Total: ₹$invoiceTotal"),
                    Text("Already Paid: ₹$alreadyPaid"),
                    Text("Remaining: ₹$remainingBalance"),
                  ],

                  const SizedBox(height: 12),

                  // 💰 Payment amount
                  TextFormField(
                    controller: paidCtrl,
                    decoration: const InputDecoration(labelText: "Amount Paid"),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                    v == null || v.isEmpty ? "Enter amount" : null,
                    onChanged: (val) {
                      final paid = double.tryParse(val) ?? 0.0;
                      if (useInvoice) {
                        setState(() {
                          remainingBalance = (invoiceTotal - alreadyPaid - paid)
                              .clamp(0, double.infinity);
                        });
                      }
                    },
                  ),

                  if (useInvoice && selectedPurchaseId != null)
                    Text("New Balance: ₹$remainingBalance",
                        style: const TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),

                  // 📝 Comment
                  TextFormField(
                    controller: commentCtrl,
                    decoration:
                    const InputDecoration(labelText: "Comment (optional)"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final txn = VendorTransaction(
                  transactionId: null, // ✅ let DB handle
                  vendorId: widget.vendorId,
                  purchaseId: useInvoice ? selectedPurchaseId : null,
                  amountPaid: double.tryParse(paidCtrl.text) ?? 0.0,
                  balanceAmount: useInvoice ? remainingBalance : 0.0,
                  transactionDate: DateTime.now().toIso8601String(),
                  comment: (commentCtrl.text.trim().isNotEmpty)
                      ? commentCtrl.text.trim()
                      : null,
                );

                final success = await context
                    .read<VendorProvider>()
                    .addVendorTransaction(txn);

                if (!mounted) return;
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? "✅ Payment recorded"
                      : "❌ Failed to record payment"),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context
        .watch<VendorProvider>()
        .vendors
        .firstWhere((v) => v.vendor_id == widget.vendorId);

    return Scaffold(
      appBar: AppBar(
        title: Text(vendor.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _pickDateRange,
          ),
          Switch(
            value: vendor.isActive,
            onChanged: (val) async {
              final success = await context
                  .read<VendorProvider>()
                  .toggleVendorStatus(vendor.vendor_id, val);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success
                    ? "✅ Vendor status updated"
                    : "❌ Failed to update status"),
                backgroundColor: success ? Colors.green : Colors.red,
              ));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPaymentDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<VendorProvider>(
        builder: (ctx, provider, _) {
          final allTxns = provider.transactionsCache[widget.vendorId] ?? [];

          // 🔍 Apply search filter
          var filtered = allTxns.where((t) {
            if (_searchQuery.isEmpty) return true;
            return (t.purchaseId?.toString() ?? "")
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();

          // 📅 Apply date filter
          if (_dateRange != null) {
            filtered = filtered.where((t) {
              final date = DateTime.tryParse(t.transactionDate);
              if (date == null) return false;
              return date.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1))) &&
                  date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }

          final totalPaid =
          filtered.fold<double>(0.0, (sum, t) => sum + (t.amountPaid ?? 0.0));
          final totalBalance = filtered.fold<double>(
              0.0, (sum, t) => sum + (t.balanceAmount ?? 0.0));

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(
                    vendor.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📞 ${vendor.contactNumber}"),
                      if (vendor.gst != null && vendor.gst!.isNotEmpty)
                        Text("GST: ${vendor.gst}"),
                      if (vendor.address.isNotEmpty)
                        Text("📍 ${vendor.address}"),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vendor.isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          color: vendor.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "🕒 ${vendor.updatedAt != null ? vendor.updatedAt!.toLocal().toString().split(' ').first : "-"}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              // 🔍 Search bar
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search by Invoice No",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              // 📊 Summary
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("💰 Paid: ₹$totalPaid",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("📌 Balance: ₹$totalBalance",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("📑 Txns: ${filtered.length}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const Divider(),
              // 📜 Transactions List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text("No Transactions"))
                    : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final txn = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.payment),
                        title: Text(
                          txn.purchaseId != null
                              ? "Invoice: ${txn.purchaseId}"
                              : "Manual Payment",
                        ),
                        subtitle: Text(
                          "Paid: ₹${txn.amountPaid?.toStringAsFixed(2) ?? '0.00'} | "
                              "Balance: ₹${txn.balanceAmount?.toStringAsFixed(2) ?? '0.00'}\n"
                              "📝 ${txn.comment ?? ''}",
                        ),
                        trailing: Text(
                          txn.transactionDate.split("T").first,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
