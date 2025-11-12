import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/return_model.dart';
import '../providers/returns_provider.dart';
import '../services/excel_service.dart';

// ✅ Returns screen with admin edit/delete & auto return_id
class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _page = 0;
  final int _pageSize = 10;
  final Set<int> _selectedRows = {};

  final statuses = const [
    'Requested',
    'Received',
    'Inspecting',
    'Approved',
    'Rejected',
    'Refund Initiated',
    'Refunded',
    'Closed'
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ReturnsProvider>().fetchReturns());
  }

  List<ReturnModel> _applyFilters(List<ReturnModel> all) {
    final s = _query.trim().toLowerCase();
    final filtered = s.isEmpty
        ? all
        : all
        .where((r) =>
    '${r.returnId}'.contains(s) ||
        (r.orderId ?? '').toLowerCase().contains(s) ||
        (r.status).toLowerCase().contains(s) ||
        (r.reason ?? '').toLowerCase().contains(s))
        .toList();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    return start >= filtered.length ? [] : filtered.sublist(start, end);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Requested':
        return Colors.grey;
      case 'Received':
        return Colors.blueGrey;
      case 'Inspecting':
        return Colors.orange;
      case 'Approved':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      case 'Refund Initiated':
        return Colors.teal;
      case 'Refunded':
        return Colors.green;
      case 'Closed':
        return Colors.purple;
      default:
        return Colors.black54;
    }
  }

  Future<void> _openAddDialog() async {
    final form = GlobalKey<FormState>();
    final idCtrl = TextEditingController();
    final orderCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final returnedCtrl = TextEditingController();
    final refundCtrl = TextEditingController();
    DateTime? rDate = DateTime.now();
    String selStatus = 'Requested';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Return'),
        content: Form(
          key: form,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: idCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Return ID (unique)'),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter return id'
                      : null,
                ),
                TextFormField(
                  controller: orderCtrl,
                  decoration: const InputDecoration(labelText: 'Order ID'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Return Date:'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: rDate ?? now,
                          firstDate: DateTime(now.year - 3),
                          lastDate: now,
                        );
                        if (picked != null) {
                          setState(() => rDate = picked);
                        }
                      },
                      child: Text(DateFormat('yyyy-MM-dd').format(rDate!)),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: selStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    'Requested',
                    'Received',
                    'Inspecting',
                    'Approved',
                    'Rejected',
                    'Refund Initiated',
                    'Refunded',
                    'Closed'
                  ]
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  ))
                      .toList(),
                  onChanged: (v) => selStatus = v ?? selStatus,
                ),
                TextFormField(
                  controller: reasonCtrl,
                  decoration:
                  const InputDecoration(labelText: 'Reason / Problem Statement'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: returnedCtrl,
                  decoration: const InputDecoration(labelText: 'Returned Items'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: refundCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Refund Amount'),
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
            onPressed: () async {
              if (!form.currentState!.validate()) return;

              final newReturn = ReturnModel(
                returnId: int.parse(idCtrl.text),
                orderId: orderCtrl.text,
                returnDate: rDate,
                status: selStatus,
                reason: reasonCtrl.text,
                returnedItems: returnedCtrl.text,
                refundAmount: double.tryParse(refundCtrl.text),
                createdAt: DateTime.now(),
              );

              final ok = await context.read<ReturnsProvider>().addReturn(newReturn);
              if (!mounted) return;
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? '✅ Return added' : '❌ Failed to add return'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ReturnModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete return #${r.returnId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'))
        ],
      ),
    );

    if (confirm == true) {
      await context.read<ReturnsProvider>().deleteReturn(r.returnId);
      await context.read<ReturnsProvider>().fetchReturns();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('✅ Return #${r.returnId} deleted.')));
    }
  }

  Future<void> _openEditDialog(ReturnModel r) async {
    final form = GlobalKey<FormState>();
    final reasonCtrl = TextEditingController(text: r.reason ?? '');
    final itemsCtrl = TextEditingController(text: r.returnedItems ?? '');
    String selStatus = r.status;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Return #${r.returnId}'),
        content: Form(
          key: form,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => selStatus = v ?? selStatus,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason / Problem Statement'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: itemsCtrl,
                  decoration: const InputDecoration(labelText: 'Returned Items'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                await context.read<ReturnsProvider>().updateReturnDetails(
                  id: r.returnId,
                  status: selStatus,
                  reason: reasonCtrl.text,
                  returnedItems: itemsCtrl.text,
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('✅ Return updated successfully')));
              },
              child: const Text('Save')),
        ],
      ),
    );

    await context.read<ReturnsProvider>().fetchReturns(); // ✅ Auto-refresh
  }

  Future<void> _exportCurrent(List<ReturnModel> current) async {
    final success = await ExcelService.exportReturnsToExcel(current);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '✅ Export successful' : '❌ Export failed')));
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('images/bg.jpg'), fit: BoxFit.cover),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.9),
          child: Consumer<ReturnsProvider>(
            builder: (_, prov, __) {
              if (prov.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final pageData = _applyFilters(prov.items);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search by Order ID / Status / Reason...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() {
                              _query = v;
                              _page = 0;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // ⬇️ Export Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: pageData.isEmpty ? null : () => _exportCurrent(pageData),
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text('Export Excel',
                              style: TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                        const SizedBox(width: 10),

                        // ➕ Add Return Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _openAddDialog,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Return',
                              style: TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor:
                          MaterialStateProperty.all(Colors.blue.shade100),
                          columnSpacing: 20,
                          columns: [
                            DataColumn(
                              label: Row(
                                children: const [
                                  Icon(Icons.check_box_outline_blank, size: 18, color: Colors.black54),
                                  SizedBox(width: 4),
                                  Text('Select', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Return Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Returned Items', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Refund', style: TextStyle(fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: pageData.map((r) {
                            return DataRow(
                              selected: _selectedRows.contains(r.returnId),
                              onSelectChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedRows.add(r.returnId);
                                  } else {
                                    _selectedRows.remove(r.returnId);
                                  }
                                });
                              },
                              cells: [
                                DataCell(Checkbox(
                                  value: _selectedRows.contains(r.returnId),
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedRows.add(r.returnId);
                                      } else {
                                        _selectedRows.remove(r.returnId);
                                      }
                                    });
                                  },
                                )),
                                DataCell(Text(r.orderId ?? '-')),
                                DataCell(Text(r.returnDate != null
                                    ? df.format(r.returnDate!)
                                    : '-')),
                                DataCell(
                                  DropdownButton<String>(
                                    value: r.status,
                                    underline: const SizedBox(),
                                    items: statuses
                                        .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s,
                                            style: TextStyle(
                                                color: _statusColor(s)))))
                                        .toList(),
                                    onChanged: (val) async {
                                      if (val != null) {
                                        await context
                                            .read<ReturnsProvider>()
                                            .updateStatus(r.returnId, val);
                                        await context
                                            .read<ReturnsProvider>()
                                            .fetchReturns(); // ✅ auto-refresh
                                      }
                                    },
                                  ),
                                ),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 220),
                                    child: TextFormField(
                                      initialValue: r.reason ?? '-',
                                      readOnly: true,
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                          border: InputBorder.none),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 220),
                                    child: TextFormField(
                                      initialValue: r.returnedItems ?? '-',
                                      readOnly: true,
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                          border: InputBorder.none),
                                    ),
                                  ),
                                ),
                                DataCell(Text(
                                    r.refundAmount?.toStringAsFixed(2) ?? '-')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _openEditDialog(r),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(r),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
