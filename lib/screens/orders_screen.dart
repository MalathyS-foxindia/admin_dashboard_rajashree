import 'package:admin_dashboard_rajshree/models/order_model.dart';
import 'package:admin_dashboard_rajshree/providers/order_provider.dart';
import 'package:admin_dashboard_rajshree/screens/trackship_screen.dart';
import 'package:admin_dashboard_rajshree/services/invoice_service.dart';
import 'package:admin_dashboard_rajshree/services/excel_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  bool _isGenerating = false;
  bool _isExporting = false;

  /// 👇 controls whether Orders table or Shipment page is shown
  bool _showShipmentPage = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<OrderProvider>(context, listen: false).fetchOrders());
  }

  void filterOrders(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      _page = 0;
    });
  }

  List<Order> _applyFilter(List<Order> all) {
    return all.where((order) {
      return order.customerName.toLowerCase().contains(searchQuery) ||
          order.mobileNumber.contains(searchQuery) ||
          order.source.toLowerCase().contains(searchQuery) ||
          order.orderId.toLowerCase().contains(searchQuery);
    }).toList();
  }

  List<Order> _pagedOrders(List<Order> allFiltered) {
    final start = _page * _pageSize;
    if (start >= allFiltered.length) return [];
    final end = (_page + 1) * _pageSize;
    return allFiltered.sublist(start, end.clamp(0, allFiltered.length));
  }

  Future<void> _exportOrdersToExcel() async {
    if (_selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one order to export')),
      );
      return;
    }

    setState(() => _isExporting = true);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final selectedOrders = orderProvider.orders.where(
      (order) => _selectedOrderIds.contains(order.orderId),
    ).toList();

    final success = await ExcelService.exportToExcel(selectedOrders);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Orders exported to Excel!'
              : 'Failed to export orders.'),
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

    for (String orderId in _selectedOrderIds) {
      final jsonData = await orderProvider.fetchOrderJson(orderId);
      if (jsonData == null) {
        allSuccess = false;
        continue;
      }

      final invoiceData =
          await InvoiceService.generateInvoiceFromJson(jsonData);

      final success =
          await orderProvider.uploadInvoiceToSupabaseStorage(invoiceData);

      if (!success) allSuccess = false;
    }

    setState(() => _isGenerating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allSuccess
              ? 'Invoices generated successfully!'
              : 'Some invoices failed.'),
        ),
      );
    }

    setState(() {
      _selectedOrderIds.clear();
    });
  }

  Future<void> _showOrderDetails(BuildContext context, Order order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final items = await orderProvider.fetchOrderItems(order.orderId.toString());
    print(items);
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
                Text("Customer: ${order.customerName}"),
                Text("Mobile: ${order.mobileNumber}"),
                Text("Address: ${order.address}, ${order.state}"),
                Text("Amount: ₹${order.totalAmount} (Shipping: ₹${order.shippingAmount})"),
                Text("Source: ${order.source} | Guest: ${order.isGuest ? 'Yes' : 'No'}"),
                Text("Payment: ${order.paymentMethod} - ${order.paymentTransactionId}"),
                if (order.orderNote.isNotEmpty) Text("Note: ${order.orderNote}"),
                const Divider(),
                const Text("Items", style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.map((item) {
                  final sku = item.productVariants?['sku'] ?? 'N/A';
                  final variantName = item.productVariants?['variant_name'] ?? 'N/A';
                  final variantPrice = item.productVariants?['saleprice']?.toString() ?? '0';
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final allOrders = _applyFilter(orderProvider.orders);
    final pageOrders = _pagedOrders(allOrders);
    final totalPages =
        (allOrders.length / _pageSize).ceil().clamp(1, double.infinity).toInt();

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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 300,
                            child: TextField(
                              onChanged: filterOrders,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Search by name, mobile, source, order id',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isGenerating ? null : () => _generateInvoices(context),
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.picture_as_pdf),
                            label: const Text('Generate Invoice'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: (_selectedOrderIds.isNotEmpty && !_isExporting)
                                ? _exportOrdersToExcel
                                : null,
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.file_download),
                            label: Text('Export Excel (${_selectedOrderIds.length})'),
                          ),
                          const Spacer(),
                          const Text("Rows per page: "),
                          DropdownButton<int>(
                            value: _pageSize,
                            items: _pageSizeOptions
                                .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _pageSize = v!;
                              _page = 0;
                            }),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          showCheckboxColumn: true,
                          columns: const [
                            DataColumn(label: Text("Order ID")),
                            DataColumn(label: Text("Customer")),
                            DataColumn(label: Text("Mobile")),
                            DataColumn(label: Text("Amount")),
                            DataColumn(label: Text("Order Status")),
                            DataColumn(label: Text("Shipment Status")),
                            DataColumn(label: Text("Invoice")),
                            DataColumn(label: Text("Date")),
                          ],
                          rows: pageOrders.map((order) {
                            final isSelected = _selectedOrderIds.contains(order.orderId);
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
                                DataCell(
                                  InkWell(
                                    child: Text(order.orderId,
                                        style: const TextStyle(color: Colors.blue)),
                                    onTap: () => _showOrderDetails(context, order),
                                  ),
                                ),
                                DataCell(Text(order.customerName)),
                                DataCell(Text(order.mobileNumber)),
                                DataCell(Text("₹${order.totalAmount.toStringAsFixed(2)}")),
                                DataCell(Text(order.orderStatus)),
                                DataCell(
                                  InkWell(
                                    child: Text(order.shipmentStatus ?? "N/A",
                                        style: const TextStyle(color: Colors.blue)),
                                    onTap: () {
                                      /// 👇 instead of push, toggle to shipment screen
                                      setState(() {
                                        _showShipmentPage = true;
                                      });
                                    },
                                  ),
                                ),
                                DataCell(order.invoiceUrl != null
                                    ? InkWell(
                                        child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                        onTap: () {
                                          if (order.invoiceUrl != null) {
                                            // TODO: open pdf with url_launcher
                                          }
                                        },
                                      )
                                    : const Text("N/A")),
                                DataCell(Text(order.orderDate)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _page > 0 ? () => setState(() => _page--) : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Page ${_page + 1} / $totalPages'),
                        IconButton(
                          onPressed: (_page + 1) < totalPages
                              ? () => setState(() => _page++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
