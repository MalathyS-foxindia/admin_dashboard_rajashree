// lib/screens/queries_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/queries_model.dart';
import '../providers/queries_provider.dart';
import '../services/excel_service.dart';
import '../providers/order_provider.dart';


class QueriesScreen extends StatefulWidget {
  final String role; // Admin / Manager / Executive

  const QueriesScreen({Key? key, this.role = 'Executive'}) : super(key: key);

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _verticalCtrl = ScrollController();
  final ScrollController _horizontalCtrl = ScrollController();

  int _rowsPerPage = 10;
  int _currentPage = 0;
  final Set<int> _selected = {};

  bool get isAdmin =>
      (widget.role.toLowerCase().trim() == "admin");

  bool get isManager =>
      (widget.role.toLowerCase().trim() == "manager");


  @override
  void initState() {
    super.initState();
    debugPrint("👑 ROLE PASSED TO SCREEN → ${widget.role}");
    debugPrint("🔍 isAdmin=${isAdmin}, isManager=${isManager}");
    Future.microtask(
          () => context.read<QueriesProvider>().fetchQueries(),
    );
  }

  @override
  void dispose() {
    _verticalCtrl.dispose();
    _horizontalCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ------------------------------
  // FILTERING LOGIC
  // ------------------------------
  List<QueryModel> _filtered(List<QueryModel> all) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return all;

    return all.where((e) {
      final email = (e.customerEmail ?? e.email ?? '').toLowerCase();
      return e.name.toLowerCase().contains(q) ||
          e.mobileNumber.contains(q) ||
          email.contains(q) ||
          e.status.toLowerCase().contains(q) ||
          (e.orderId ?? '').toLowerCase().contains(q) ||
          e.message.toLowerCase().contains(q);
    }).toList();
  }

  /// Normalize whatever comes from DB ("open", "Open", "OPEN") to a nice label
  String _statusLabel(String raw) {
    final s = raw.trim().toLowerCase();
    switch (s) {
      case 'in progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'open':
      default:
        return 'Open';
    }
  }

  // ------------------------------
  // STATUS COLORS
  // ------------------------------
  Color _statusColor(String s) {
    final normalized = _statusLabel(s);
    switch (normalized.toLowerCase()) {
      case 'open':
        return Colors.redAccent;
      case 'in progress':
        return Colors.orangeAccent;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  // ------------------------------
  // EXPORT SELECTED
  // ------------------------------
  Future<void> _exportSelected() async {
    final provider = context.read<QueriesProvider>();
    final selectedRows =
    provider.queries.where((q) => _selected.contains(q.queryId)).toList();

    if (selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rows selected')),
      );
      return;
    }

    final ok = await ExcelService.exportQueriesToExcel(selectedRows);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported successfully')),
      );
    }
  }

  // ------------------------------
  // DELETE SELECTED
  // ------------------------------
  Future<void> _deleteSelected() async {
    if (!isAdmin || _selected.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text(
          'Are you sure you want to delete ${_selected.length} queries?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final prov = context.read<QueriesProvider>();
    for (final id in _selected.toList()) {
      await prov.deleteQuery(id);
    }

    setState(() => _selected.clear());
  }

  // ------------------------------
  // COPY HELPER
  // ------------------------------
  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $value')),
    );
  }

  // ------------------------------
  // REMARK EDITOR
  // ------------------------------
  Future<void> _showRemarkEditor(QueryModel q) async {
    final ctrl = TextEditingController(text: q.remarks ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Remark #${q.queryId}'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              await context
                  .read<QueriesProvider>()
                  .updateRemarks(q.queryId, ctrl.text.trim());
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // VIEW DIALOG
  // ------------------------------
  Future<void> _showViewDialog(QueryModel q) async {
    final email = q.customerEmail ?? q.email ?? '-';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Query #${q.queryId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${q.name}'),
              const SizedBox(height: 6),
              Text('Mobile: ${q.mobileNumber}'),
              const SizedBox(height: 6),
              Text('Email: $email'),
              const SizedBox(height: 12),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(q.message),
              const SizedBox(height: 12),
              const Text(
                'Remarks:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(q.remarks ?? '-'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // ADD DIALOG
  // ------------------------------
  Future<void> _openAddDialog() async {
    final name = TextEditingController();
    final mobile = TextEditingController();
    final email = TextEditingController();
    final msg = TextEditingController();
    final order = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Query'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextFormField(
                  controller: mobile,
                  decoration: const InputDecoration(labelText: 'Mobile'),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: msg,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 4,
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: order,
                  decoration: const InputDecoration(labelText: 'Order ID'),
                ),
                const SizedBox(height: 10),

                // auto priority preview
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: order,
                  builder: (_, __, ___) {
                    final pr =
                    order.text.trim().isNotEmpty ? 'High' : 'Medium';
                    return Row(
                      children: [
                        const Text('Priority: '),
                        Chip(label: Text(pr)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final q = QueryModel(
                queryId: 0,
                customerId: null,
                name: name.text.trim(),
                mobileNumber: mobile.text.trim(),
                email:
                email.text.trim().isEmpty ? null : email.text.trim(),
                message: msg.text.trim(),
                status: 'Open',
                orderId:
                order.text.trim().isEmpty ? null : order.text.trim(),
                priority:
                order.text.trim().isEmpty ? 'Medium' : 'High',
                remarks: null,
                createdAt: DateTime.now(),
              );

              final ok = await context.read<QueriesProvider>().addQuery(q);
              if (ok) {
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to add query'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // EDIT DIALOG
  // ------------------------------
  Future<void> _showEditDialog(QueryModel q) async {
    if (!isAdmin) return;

    final msg = TextEditingController(text: q.message);
    final remarks = TextEditingController(text: q.remarks ?? '');

    final priority = q.priority ?? (q.orderId != null ? 'High' : 'Medium');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Query #${q.queryId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Status: '),
                  Chip(
                    label: Text(q.status),
                    backgroundColor: _statusColor(q.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Priority: '),
                  Chip(label: Text(priority)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: msg,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              TextField(
                controller: remarks,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              if (msg.text.trim() != q.message) {
                await context
                    .read<QueriesProvider>()
                    .updateMessage(q.queryId, msg.text.trim());
              }
              await context
                  .read<QueriesProvider>()
                  .updateRemarks(q.queryId, remarks.text.trim());
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // STATUS CHANGE DIALOG (Option A)
  // ------------------------------
  // ------------------------------
  // STATUS CHANGE DIALOG (Option A)
  // ------------------------------
  Future<void> _changeStatusManually(QueryModel q) async {
    debugPrint("🟢 Opening status dialog → ID=${q.queryId}, current=${q.status}");
    if (!(isAdmin || isManager)) {
      debugPrint('🔒 Status change blocked – role=${widget.role}');
      return;
    }
    debugPrint('🟡 Opening status dialog → ${q.queryId}, current=${q.status}');
    const possibleStatuses = <String>[
      'Open',
      'In Progress',
      'Resolved',
      'Closed',
    ];

    // Ensure we use the normalized label for initial selection
    String selectedStatus = _statusLabel(q.status);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Status #${q.queryId}'),
        content: StatefulBuilder(
          builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: possibleStatuses.map((st) {
                return RadioListTile<String>(
                  title: Text(st),
                  value: st,
                  groupValue: selectedStatus,
                  onChanged: (val) {
                    if (val == null) return;
                    setStateSB(() {
                      selectedStatus = val;
                    });
                    debugPrint(
                      '   🔘 Status option tapped for query_id=${q.queryId} → $val',
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selectedStatus),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    debugPrint(
      '🟣 Status dialog closed for query_id=${q.queryId}, result=$result',
    );

    if (result == null) {
      debugPrint('ℹ️ No status change (user cancelled) for query_id=${q.queryId}');
      return;
    }

    // If DB already has the same label, nothing to do
    if (_statusLabel(q.status) == result) {
      debugPrint(
        'ℹ️ Selected status is same as current for query_id=${q.queryId} → $result',
      );
      return;
    }

    debugPrint(
      '🟡 Calling provider.updateStatus for query_id=${q.queryId} → $result',
    );

    final provider = context.read<QueriesProvider>();
    final ok = await provider.updateStatus(q.queryId, result);

    debugPrint(
      '🟢 provider.updateStatus returned $ok for query_id=${q.queryId}',
    );

    if (ok) {
      // Provider notifies listeners, but setState makes sure our pagination vars update too.
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $result')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
  }

  // ------------------------------
  // ROW BUILDER
  // ------------------------------
  DataRow _buildRow(QueryModel q) {
    final pr = q.priority ?? (q.orderId != null ? 'High' : 'Medium');
    final email = q.customerEmail ?? q.email ?? '-';
    final statusLabel = _statusLabel(q.status);

    debugPrint(
      '🔁 Building row → query_id=${q.queryId}, status=${q.status}, normalizedStatus=$statusLabel',
    );

    return DataRow(
      key: ValueKey('${q.queryId}-$statusLabel'),
      selected: _selected.contains(q.queryId),
      cells: [
        // Custom checkbox column
        DataCell(
          Checkbox(
            value: _selected.contains(q.queryId),
            onChanged: (val) {
              debugPrint(
                '☑️ Checkbox changed for query_id=${q.queryId} → $val',
              );
              setState(() {
                if (val == true) {
                  _selected.add(q.queryId);
                } else {
                  _selected.remove(q.queryId);
                }
              });
            },
          ),
        ),
        DataCell(Text('${q.queryId}')),
        DataCell(
          Text(q.name),
          onTap: () => _copyToClipboard(q.name),
        ),
        DataCell(
          Text(q.mobileNumber),
          onTap: () => _copyToClipboard(q.mobileNumber),
        ),
        DataCell(
          Text(email),
          onTap: () => _copyToClipboard(email),
        ),

        // Message column
        DataCell(
          SizedBox(
            width: 200,
            child: SelectableText(
              q.message,
              maxLines: 3,
            ),
          ),
        ),

        // Status Chip (Admin/Manager manually changes it)
        DataCell(
          InkWell(
            onTap: () {
              debugPrint("🟡 [TAP] Status chip tapped → ID=${q.queryId}, current=${q.status}");
              debugPrint("🔐 Check permissions → isAdmin=$isAdmin, isManager=$isManager");

              if (isAdmin || isManager) {
                _changeStatusManually(q);
              } else {
                debugPrint("⛔ Permission denied → Only Admin/Manager can change status");
              }
            },
            child: Chip(
              label: Text(
                statusLabel,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _statusColor(q.status),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ),

        // Priority
        DataCell(
          Chip(
            label: Text(pr),
            backgroundColor: Colors.blue.shade100,
          ),
        ),

        // Order Date
        DataCell(
          Text(
            q.orderDate != null
                ? DateFormat('yyyy-MM-dd').format(q.orderDate!)
                : '-',
          ),
        ),

        // Order ID (with order details popup)
        DataCell(
          q.orderId != null
              ? InkWell(
            onTap: () => _showOrderDetailsDialog(q.orderId!),
            child: Text(
              q.orderId!,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          )
              : const Text('-'),
        ),

        // Remarks
        DataCell(
          SizedBox(
            width: 200,
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(q.remarks ?? '-'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showRemarkEditor(q),
                ),
              ],
            ),
          ),
        ),

        // Created At
        DataCell(
          Text(DateFormat('yyyy-MM-dd HH:mm').format(q.createdAt)),
        ),

        // Actions
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => _showViewDialog(q),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(q),
                ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteOne(q.queryId),
                ),
            ],
          ),
        ),
      ],
    );
  }


  // Delete single row
  Future<void> _deleteOne(int id) async {
    if (!isAdmin) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Delete this query?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await context.read<QueriesProvider>().deleteQuery(id);
    }
  }

  // ------------------------------
  // ORDER DETAILS POPUP
  // ------------------------------
  Future<void> _showOrderDetailsDialog(String orderId) async {
    final prov = context.read<QueriesProvider>();

    // Show loading modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Loading order details..."),
          ],
        ),
      ),
    );

    final full = await prov.fetchOrderDetails(orderId);
    final items = await prov.fetchOrderItems(orderId);

    Navigator.pop(context); // Close loader

    if (full == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order $orderId not found")),
      );
      return;
    }

    final order = full['order'];
    final cust = full['customer'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(24),
        title: Text(
          "Order ${order['order_id']}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------- Customer ----------
                Text("Customer ID: ${order['customer_id'] ?? '-'}",
                    style: const TextStyle(fontSize: 16)),
                Text("Mobile: ${cust?['mobile_number'] ?? '-'}",
                    style: const TextStyle(fontSize: 16)),
                Text("Email: ${cust?['email'] ?? '-'}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),

                // -------- Address ----------
                const Text("Shipping Address:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${order['name'] ?? ''}, ${order['shipping_address'] ?? ''}",
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  "${order['shipping_state'] ?? ''}, ${order['shipping_pincode'] ?? ''}",
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 20),

                // -------- Payments ----------
                Text(
                  "Amount: ₹${order['total_amount']} (Shipping: ₹${order['shipping_amount']})",
                  style: const TextStyle(fontSize: 16),
                ),
                Text("Source: ${order['source'] ?? '-'}",
                    style: const TextStyle(fontSize: 16)),
                Text(
                  "Payment: ${order['payment_method']} - ${order['payment_transaction_id']}",
                  style: const TextStyle(fontSize: 16),
                ),
                if (order['order_note'] != null &&
                    order['order_note'].toString().trim().isNotEmpty)
                  Text("Note: ${order['order_note']}"),

                const SizedBox(height: 25),
                const Divider(),

                // -------- Items ----------
                const Text(
                  "Items",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),

                if (items.isEmpty)
                  const Text("No items found", style: TextStyle(fontSize: 15))
                else
                  Column(
                    children: items.map((item) {
                      final pv = item['product_variants'];
                      return ListTile(
                        dense: true,
                        title: Text(
                          "${pv['sku']} - ${pv['variant_name']} - ₹${pv['saleprice']}",
                          style: const TextStyle(fontSize: 15),
                        ),
                        subtitle: Text("Qty: ${item['quantity']}"),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }


  // ------------------------------
  // BUILD
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<QueriesProvider>(
      builder: (ctx, prov, _) {
        if (prov.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = prov.queries;
        final filtered = _filtered(all);

        final int itemCount = filtered.length;
        final int totalPages =
        itemCount == 0 ? 1 : ((itemCount - 1) / _rowsPerPage).floor() + 1;

        int currentPage = _currentPage;
        if (currentPage >= totalPages) {
          currentPage = totalPages - 1;
        }
        if (currentPage < 0) currentPage = 0;

        final int startIndex = currentPage * _rowsPerPage;
        final int endIndex =
        itemCount == 0 ? 0 : (startIndex + _rowsPerPage).clamp(0, itemCount);

        final page = (itemCount == 0)
            ? <QueryModel>[]
            : filtered.sublist(startIndex, endIndex);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              Row(
                children: [
                  const Text(
                    'Customer Queries',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 360,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search name/mobile/email/order',
                      ),
                      onChanged: (_) => setState(() => _currentPage = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                    onPressed: page.isEmpty
                        ? null
                        : () => ExcelService.exportQueriesToExcel(page),
                  ),
                  const SizedBox(width: 12),
                  if (isAdmin)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Query'),
                      onPressed: _openAddDialog,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ---------------- TABLE ----------------
              Expanded(
                child: Card(
                  child: Scrollbar(
                    controller: _verticalCtrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalCtrl,
                      scrollDirection: Axis.vertical,
                      child: Scrollbar(
                        controller: _horizontalCtrl,
                        thumbVisibility: true,
                        notificationPredicate: (notif) =>
                        notif.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _horizontalCtrl,
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            // Custom checkbox column used, so no built-in checkbox
                            showCheckboxColumn: false,
                            columnSpacing: 20,
                            dataRowMinHeight: 48,
                            columns: const [
                              DataColumn(label: SizedBox()), // checkbox column
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Mobile')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Message')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Priority')),
                              DataColumn(label: Text('Order Date')),
                              DataColumn(label: Text('Order ID')),
                              DataColumn(label: Text('Remarks')),
                              DataColumn(label: Text('Created')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: page.map(_buildRow).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ---------------- FOOTER ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pagination
                  Row(
                    children: [
                      const Text('Rows per page'),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: _rowsPerPage,
                        items: const [5, 10, 20, 50]
                            .map(
                              (v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v'),
                          ),
                        )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _rowsPerPage = v;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Page ${currentPage + 1} of $totalPages'
                            ' (${itemCount.toString()} items)',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: currentPage > 0
                            ? () => setState(() {
                          _currentPage = currentPage - 1;
                        })
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: currentPage < totalPages - 1
                            ? () => setState(() {
                          _currentPage = currentPage + 1;
                        })
                            : null,
                      ),
                    ],
                  ),

                  // Selection actions
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                        _selected.isEmpty ? null : _exportSelected,
                        child: const Text('Export Selected'),
                      ),
                      const SizedBox(width: 12),
                      if (isAdmin)
                        ValueListenableBuilder(
                          valueListenable: ValueNotifier(_selected.isNotEmpty),
                          builder: (_, enabled, __) {
                            return TextButton(
                              onPressed: enabled ? _deleteSelected : null,
                              child: Text(
                                "Delete Selected",
                                style: TextStyle(color: enabled ? Colors.red : Colors.grey),
                              ),
                            );
                          },
                        )

                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
