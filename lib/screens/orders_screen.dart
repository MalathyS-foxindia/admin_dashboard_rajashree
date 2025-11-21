// lib/screens/orders_screen.dart
import 'dart:io' show File;
import 'dart:convert';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // only ok if guarded inside kIsWeb

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
// KEEP ONLY SYNCFUSION
import 'package:syncfusion_flutter_pdf/pdf.dart';

// your other app files…
import 'package:admin_dashboard_rajashree/models/order_model.dart';
import 'package:admin_dashboard_rajashree/providers/order_provider.dart';
import 'package:admin_dashboard_rajashree/screens/trackship_screen.dart';
import 'package:admin_dashboard_rajashree/services/invoice_service.dart';
import 'package:admin_dashboard_rajashree/services/excel_service.dart';
import 'package:admin_dashboard_rajashree/services/dashboard_service.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String searchQuery = '';
  final Set<String> _selectedOrderIds = {};
  int _page = 0;
  int _pageSize = 10;
  final List<int> _pageSizeOptions = [10, 20, 50, 100];

  /// 🔹 Define available filter categories
  final Map<String, List<String>> _filterOptions = {
    "Status": ["processing", "Completed", "failed"],
    "Source": ["Website", "WhatsApp"],
    "Date": [], // empty list, we use DatePicker instead of dropdown
  };

  bool _isGenerating = false;
  bool _isExporting = false;
  bool _showShipmentPage = false;

  // ---------- NEW multi-select filter state ----------
  List<String> _selectedStatuses = [];
  List<String> _selectedSources = [];
  DateTime? _selectedDateFilter;
  // --------------------------------------------------

  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _skuSummary = [];
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => Provider.of<OrderProvider>(context, listen: false).fetchOrders(),
    );
    _loadSkuSummary();
  }

  Future<void> _loadSkuSummary() async {
    final summary = await _supabaseService.fetchDailySkuSummary(_selectedDate);
    setState(() => _skuSummary = List<Map<String, dynamic>>.from(summary));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      print("selected date: $picked");
      setState(() => _selectedDate = picked);
      await _loadSkuSummary();
    }
  }

  void _showSkuSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("📦 Daily SKU Sales Summary"),
              content: SizedBox(
                width: 700,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                              await _loadSkuSummary();
                              // refresh dialog UI
                              setDialogState(() {});
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            "${_selectedDate.toLocal()}".split(' ')[0],
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _skuSummary.isEmpty
                              ? null
                              : () async {
                            final success =
                            await ExcelService.exportSkuSummaryToExcel(
                              _skuSummary,
                              _selectedDate,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'SKU Summary exported!'
                                        : 'Failed to export.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.file_download),
                          label: const Text("Export Excel"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 400,
                      child: _skuSummary.isEmpty
                          ? const Center(
                        child: Text("No sales summary available"),
                      )
                          : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                            WidgetStateProperty.resolveWith(
                                  (states) => Colors.grey[200],
                            ),
                            columns: const [
                              DataColumn(label: Text("SKU")),
                              DataColumn(label: Text("Variant")),
                              DataColumn(label: Text("Qty Sold")),
                              DataColumn(label: Text("Current Stock")),
                            ],
                            rows: _skuSummary.map((sku) {
                              final currentStock =
                                  int.tryParse(
                                    sku['current_stock']?.toString() ??
                                        '0',
                                  ) ??
                                      0;
                              final totalQty =
                                  int.tryParse(
                                    sku['total_qty']?.toString() ?? '0',
                                  ) ??
                                      0;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      (sku['sku'] ?? 'N/A').toString(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (sku['variant_name'] ?? 'N/A')
                                          .toString(),
                                    ),
                                  ),
                                  DataCell(Text(totalQty.toString())),
                                  DataCell(
                                    Text(
                                      currentStock.toString(),
                                      style: TextStyle(
                                        color: currentStock < totalQty
                                            ? Colors.red
                                            : Colors.black,
                                        fontWeight:
                                        currentStock < totalQty
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void filterOrders(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      _page = 0;
    });
  }

  // ----------------- UPDATED FILTERING (supports multi-select) -----------------
  List<Order> _applyFilter(List<Order> all) {
    return all.where((order) {
      final customer = order.customer;

      final matchesSearch =
          (customer?.fullName.toLowerCase().contains(searchQuery) ?? false) ||
              (customer?.mobileNumber.contains(searchQuery) ?? false) ||
              (order.shippingAddress.toLowerCase().contains(searchQuery)) ||
              (order.shippingState.toLowerCase().contains(searchQuery)) ||
              order.source.toLowerCase().contains(searchQuery) ||
              order.orderId.toLowerCase().contains(searchQuery);

      // MULTI SELECT STATUS
      final matchesStatus = _selectedStatuses.isEmpty
          ? true
          : _selectedStatuses.contains(order.orderStatus);

      // MULTI SELECT SOURCE
      final matchesSource = _selectedSources.isEmpty
          ? true
          : _selectedSources.contains(order.source);

      // SINGLE SELECT DATE
      final matchesDate = _selectedDateFilter == null
          ? true
          : (order.createdAt != null &&
          order.createdAt!.year == _selectedDateFilter!.year &&
          order.createdAt!.month == _selectedDateFilter!.month &&
          order.createdAt!.day == _selectedDateFilter!.day);

      return matchesSearch && matchesStatus && matchesSource && matchesDate;
    }).toList();
  }
  // -----------------------------------------------------------------------------

  List<Order> _pagedOrders(List<Order> allFiltered) {
    final start = _page * _pageSize;
    if (start >= allFiltered.length) return [];
    final end = (_page + 1) * _pageSize;
    return allFiltered.sublist(start, end.clamp(0, allFiltered.length));
  }

  Future<void> _exportOrdersToExcel() async {
    if (_selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one order to export'),
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final selectedOrders = orderProvider.orders
        .where((order) => _selectedOrderIds.contains(order.orderId))
        .toList();

    final success = await ExcelService.exportToExcel(
      selectedOrders,
      orderProvider,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Orders exported to Excel!' : 'Failed to export orders.',
          ),
        ),
      );
    }

    setState(() => _isExporting = false);
  }

  Future<void> _generateInvoices(BuildContext context) async {
    if (_selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one order')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    bool allSuccess = true;

    // Store URLs of uploaded invoices
    final List<String> invoiceUrls = [];

    // =============== 1️⃣ GENERATE + UPLOAD INVOICES =================
    for (String orderId in _selectedOrderIds) {
      final jsonData = await orderProvider.fetchOrderJson(orderId);
      if (jsonData == null) {
        allSuccess = false;
        continue;
      }

      if (jsonData['order_status'] != 'failed') {
        final invoiceData = await InvoiceService.generateInvoiceFromJson(
          jsonData,
        );

        if (invoiceData == null) {
          allSuccess = false;
          continue;
        }

        final uploadedUrl = await orderProvider.uploadInvoiceToSupabaseStorage(
          invoiceData,
        );

        if (uploadedUrl == "") {
          allSuccess = false;
        } else {
          invoiceUrls.add(uploadedUrl);
        }
      }
    }

    // =============== 2️⃣ MERGE PDF (WEB vs MOBILE) =================
    try {
      // Build final merged PDF
      final PdfDocument finalDoc = PdfDocument();

      for (String url in invoiceUrls) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) continue;

        final PdfDocument doc = PdfDocument(inputBytes: response.bodyBytes);

        for (int i = 0; i < doc.pages.count; i++) {
          final page = doc.pages[i];
          final template = page.createTemplate();
          final newPage = finalDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }

        doc.dispose();
      }

      final mergedBytes = await finalDoc.save();
      finalDoc.dispose();

      // ---------- WEB (DOWNLOAD) ----------
      if (kIsWeb) {
        final base64Pdf = base64Encode(mergedBytes);
        final url = "data:application/pdf;base64,$base64Pdf";

        // ignore: undefined_prefixed_name
        html.AnchorElement(href: url)
          ..setAttribute("download", "Combined_Invoices.pdf")
          ..click();

        print("Merged PDF downloaded (web)");
      } else {
        // ---------- MOBILE / DESKTOP ----------
        final dir = await getTemporaryDirectory();
        final outFile = File("${dir.path}/Combined_Invoices.pdf");

        await outFile.writeAsBytes(mergedBytes, flush: true);
        await OpenFilex.open(outFile.path);

        print("Merged PDF saved at ${outFile.path}");
      }
    } catch (e) {
      print("PDF merge error: $e");
    }

    // Cleanup
    setState(() {
      _isGenerating = false;
      _selectedOrderIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allSuccess
                ? 'Invoices generated successfully!'
                : 'Some invoices failed.',
          ),
        ),
      );
    }
  }

  Future<void> _showOrderDetails(BuildContext context, Order order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final items = await orderProvider.fetchOrderItems(order.orderId.toString());
    final customer = order.customer;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Order ${order.orderId}"),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customer != null) ...[
                  Text("Customer ID: ${customer.customerId}"),
                  Text("Mobile: ${customer.mobileNumber}"),
                  Text("Email: ${customer.email}"),
                ],
                Text(
                  "Shipping Address : ${order.name} , ${order.shippingAddress}, ${order.shippingState}, ${order.contactNumber}",
                ),
                Text(
                  "Amount: ₹${order.totalAmount} (Shipping: ₹${order.shippingAmount})",
                ),
                Text("Source: ${order.source}"),
                Text(
                  "Payment: ${order.paymentMethod} - ${order.paymentTransactionId}",
                ),
                if (order.orderNote.isNotEmpty)
                  Text("Note: ${order.orderNote}"),
                const Divider(),
                const Text(
                  "Items",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...items.map((item) {
                  final sku = item.productVariants?['sku'] ?? 'N/A';
                  final variantName =
                      item.productVariants?['variant_name'] ?? 'N/A';
                  final variantPrice =
                      item.productVariants?['saleprice']?.toString() ?? '0';
                  return ListTile(
                    dense: true,
                    title: Text("$sku - $variantName - ₹$variantPrice"),
                    subtitle: Text("Qty: ${item.quantity}"),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ----------------- MULTI SELECT HELPER -----------------
  Future<List<String>> _showMultiSelect(
      List<String> options,
      List<String> selectedValues,
      String title,
      ) async {
    final tempSelected = [...selectedValues];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    children: options.map((opt) {
                      final isSelected = tempSelected.contains(opt);
                      return FilterChip(
                        label: Text(opt),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              tempSelected.add(opt);
                            } else {
                              tempSelected.remove(opt);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Apply"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return tempSelected;
  }
  // ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final allOrders = _applyFilter(orderProvider.orders);
    final pageOrders = _pagedOrders(allOrders);
    final totalPages = (allOrders.length / _pageSize)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text(_showShipmentPage ? 'Shipment Tracking' : 'Orders'),
        leading: _showShipmentPage
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showShipmentPage = false),
        )
            : null,
      ),
      body: _showShipmentPage
          ? const TrackShipScreen()
          : orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          /// 🔹 Top controls row
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showSkuSummaryDialog,
            icon: const Icon(Icons.inventory),
            label: const Text("SKU Summary"),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    onChanged: filterOrders,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by mobile, source, order id',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // ---------------- NEW MULTI-SELECT FILTER UI ----------------

                // ================= MULTI SELECT STATUS ===================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        ..._selectedStatuses.map(
                              (s) => Chip(
                            label: Text(s),
                            onDeleted: () {
                              setState(() {
                                _selectedStatuses.remove(s);
                                _page = 0;
                              });
                            },
                          ),
                        ),
                        ActionChip(
                          label: const Text("Select"),
                          avatar: const Icon(Icons.filter_alt),
                          onPressed: () async {
                            final result = await _showMultiSelect(
                              _filterOptions["Status"]!,
                              _selectedStatuses,
                              "Select Status",
                            );
                            setState(() {
                              _selectedStatuses = result;
                              _page = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // ================= MULTI SELECT SOURCE ===================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Source",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        ..._selectedSources.map(
                              (s) => Chip(
                            label: Text(s),
                            onDeleted: () {
                              setState(() {
                                _selectedSources.remove(s);
                                _page = 0;
                              });
                            },
                          ),
                        ),
                        ActionChip(
                          label: const Text("Select"),
                          avatar: const Icon(Icons.filter_alt),
                          onPressed: () async {
                            final result = await _showMultiSelect(
                              _filterOptions["Source"]!,
                              _selectedSources,
                              "Select Source",
                            );
                            setState(() {
                              _selectedSources = result;
                              _page = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // ================= DATE FILTER ===================
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _selectedDateFilter != null
                            ? "${_selectedDateFilter!.toLocal()}".split(
                          ' ',
                        )[0]
                            : "Filter Date",
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                          _selectedDateFilter ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateFilter = picked;
                            _page = 0;
                          });
                        }
                      },
                    ),
                    if (_selectedDateFilter != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _selectedDateFilter = null);
                        },
                      ),
                  ],
                ),

                // ----------------------------------------------------------
                ElevatedButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () => _generateInvoices(context),
                  icon: _isGenerating
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate Invoice'),
                ),
                ElevatedButton.icon(
                  onPressed:
                  (_selectedOrderIds.isNotEmpty && !_isExporting)
                      ? _exportOrdersToExcel
                      : null,
                  icon: _isExporting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.file_download),
                  label: Text(
                    'Export Excel (${_selectedOrderIds.length})',
                  ),
                ),
              ],
            ),
          ),

          /// Orders Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  showCheckboxColumn: true,
                  columns: const [
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Order ID")),
                    DataColumn(label: Text("Customer Name")),
                    DataColumn(label: Text("Mobile")),
                    DataColumn(label: Text("Amount")),
                    DataColumn(label: Text("Source")),
                    DataColumn(label: Text("Order Status")),
                    DataColumn(label: Text("Shipment Status")),
                    DataColumn(label: Text("Invoice")),
                    DataColumn(label: Text("Payment")),
                  ],
                  rows: pageOrders.map((order) {
                    final isSelected = _selectedOrderIds.contains(
                      order.orderId,
                    );
                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedOrderIds.add(order.orderId);
                          } else {
                            _selectedOrderIds.remove(order.orderId);
                          }
                        });
                      },
                      cells: [
                        DataCell(Text(order.orderDate)),
                        DataCell(
                          InkWell(
                            child: Text(
                              order.orderId,
                              style: const TextStyle(color: Colors.blue),
                            ),
                            onTap: () =>
                                _showOrderDetails(context, order),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 150, // 👈 give a fixed width
                            child: Text(
                              order.customer?.fullName ?? "N/A",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(order.customer?.mobileNumber ?? "N/A"),
                        ),
                        DataCell(
                          Text(
                            "₹${order.totalAmount.toStringAsFixed(2)}",
                          ),
                        ),
                        DataCell(Text(order.source)),
                        DataCell(Text(order.orderStatus)),
                        DataCell(
                          InkWell(
                            child: Text(
                              order.shipmentStatus ?? "N/A",
                              style: const TextStyle(color: Colors.blue),
                            ),
                            onTap: () =>
                                setState(() => _showShipmentPage = true),
                          ),
                        ),
                        DataCell(
                          order.invoiceUrl != null
                              ? InkWell(
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            onTap: () => launchUrl(
                              Uri.parse(order.invoiceUrl!),
                            ),
                          )
                              : const Text("N/A"),
                        ),
                        DataCell(
                          order.paymentTransactionId != null &&
                              order.paymentTransactionId!.isNotEmpty
                              ? InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(
                                "https://dashboard.razorpay.com/app/orders/${order.paymentTransactionId}",
                              ),
                            ),
                            child: Text(
                              order.paymentTransactionId!,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration:
                                TextDecoration.underline,
                              ),
                            ),
                          )
                              : const Text("Not Paid"),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          /// 🔹 Pagination controls + Rows per page
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _page > 0
                      ? () => setState(() => _page--)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${_page + 1} / $totalPages'),
                IconButton(
                  onPressed: (_page + 1) < totalPages
                      ? () => setState(() => _page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                const SizedBox(width: 20),
                const Text("Rows per page: "),
                DropdownButton<int>(
                  value: _pageSize,
                  items: _pageSizeOptions
                      .map(
                        (s) =>
                        DropdownMenuItem(value: s, child: Text('$s')),
                  )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _pageSize = v!;
                    _page = 0;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}