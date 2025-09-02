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

  void _openPaymentDialog() {
    final _formKey = GlobalKey<FormState>();
    final purchaseIdCtrl = TextEditingController();
    final paidCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Payment"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Purchase ID optional now
              TextFormField(
                controller: purchaseIdCtrl,
                decoration: const InputDecoration(labelText: "Purchase ID (optional)"),
              ),
              TextFormField(
                controller: paidCtrl,
                decoration: const InputDecoration(labelText: "Amount Paid"),
                keyboardType: TextInputType.number,
                validator: (v) =>
                v == null || v.isEmpty ? "Enter amount" : null,
              ),
              TextFormField(
                controller: balanceCtrl,
                decoration: const InputDecoration(labelText: "Balance Amount (optional)"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final txn = VendorTransaction(
                  transactionId: 0,
                  vendorId: widget.vendorId,
                  purchaseId: purchaseIdCtrl.text, // can be empty
                  amountPaid: double.tryParse(paidCtrl.text) ?? 0,
                  balanceAmount: double.tryParse(balanceCtrl.text) ?? 0,
                  transactionDate: DateTime.now().toIso8601String(),
                );
                final success =
                await context.read<VendorProvider>().addVendorTransaction(txn);

                if (!mounted) return;
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? "✅ Transaction recorded"
                      : "❌ Failed to record transaction"),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text("Save"),
          )
        ],
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
            return t.purchaseId
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();

          // 📅 Apply date filter
          if (_dateRange != null) {
            filtered = filtered.where((t) {
              final date = DateTime.tryParse(t.transactionDate);
              if (date == null) return false;
              return date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                  date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
            }).toList();
          }

          final totalPaid =
          filtered.fold(0.0, (sum, t) => sum + t.amountPaid);
          final totalBalance =
          filtered.fold(0.0, (sum, t) => sum + t.balanceAmount);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(vendor.name),
                  subtitle: Text(
                      "📞 ${vendor.contactNumber}\nGST: ${vendor.gst}\n📍 ${vendor.address}"),
                  trailing: Text(
                    vendor.isActive ? "Active" : "Inactive",
                    style: TextStyle(
                      color: vendor.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // 🔍 Search bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search by Purchase ID",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("💰 Paid: ₹$totalPaid"),
                    Text("📌 Balance: ₹$totalBalance"),
                    Text("📑 Transactions: ${filtered.length}"),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text("No Transactions"))
                    : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final txn = filtered[i];
                    return ListTile(
                      leading: const Icon(Icons.payment),
                      title: Text(
                        txn.purchaseId.isNotEmpty
                            ? "Purchase ID: ${txn.purchaseId}"
                            : "Manual Payment",
                      ),
                      subtitle: Text(
                          "Paid: ₹${txn.amountPaid} | Balance: ₹${txn.balanceAmount}"),
                      trailing: Text(
                        txn.transactionDate.split("T").first,
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
