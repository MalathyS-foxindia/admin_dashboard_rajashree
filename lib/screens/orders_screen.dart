import 'package:admin_dashboard_rajshree/models/order_model.dart';
import 'package:admin_dashboard_rajshree/providers/order_provider.dart';
import 'package:admin_dashboard_rajshree/services/invoice_service.dart';
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
  bool _selectAllOnPage = false;

  // Pagination
  int _page = 0;
  int _pageSize = 10;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  bool _isGenerating = false;

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

  List<Order> _applyFilterAndSort(List<Order> all) {
    final filtered = all.where((order) {
      return order.customerName.toLowerCase().contains(searchQuery) ||
          order.mobileNumber.contains(searchQuery) ||
          order.source.toLowerCase().contains(searchQuery) ||
          order.orderId.toLowerCase().contains(searchQuery);
    }).toList();

    // optionally sort (e.g. newest first) - depends on your Order model
    // filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  List<Order> _pagedOrders(List<Order> allFiltered) {
    final start = _page * _pageSize;
    if (start >= allFiltered.length) return [];
    final end = (_page + 1) * _pageSize;
    return allFiltered.sublist(start, end.clamp(0, allFiltered.length));
  }

  void _toggleSelectAllOnPage(List<Order> pageOrders, bool? value) {
    setState(() {
      _selectAllOnPage = value ?? false;
      if (_selectAllOnPage) {
        for (var o in pageOrders) {
          _selectedOrderIds.add(o.orderId);
        }
      } else {
        for (var o in pageOrders) {
          _selectedOrderIds.remove(o.orderId);
        }
      }
    });
  }

  void _toggleOrderSelection(String orderId, bool? value, List<Order> pageOrders) {
    setState(() {
      if (value ?? false) {
        _selectedOrderIds.add(orderId);
      } else {
        _selectedOrderIds.remove(orderId);
      }
      _selectAllOnPage =
          pageOrders.every((o) => _selectedOrderIds.contains(o.orderId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final allOrders = _applyFilterAndSort(orderProvider.orders);
    final pageOrders = _pagedOrders(allOrders);
    final totalPages =
        (allOrders.length / _pageSize).ceil().clamp(1, double.infinity).toInt();

    // keep select all synced when page changes
    final isAllSelectedOnPage =
        pageOrders.isNotEmpty && pageOrders.every((o) => _selectedOrderIds.contains(o.orderId));
    if (isAllSelectedOnPage != _selectAllOnPage) {
      _selectAllOnPage = isAllSelectedOnPage;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                // Top controls row: search + generate button + page size
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 400,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: filterOrders,
                          decoration: const InputDecoration(
                            hintText: 'Search by name, mobile, source, order id',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : () => _generateInvoices(context),
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf),
                      label: const Text('Generate Invoice'),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                    const Text('Page size:'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _pageSize,
                      items: _pageSizeOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _pageSize = v;
                          _page = 0; // reset page
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // List header with Select all on page
                Row(
                  children: [
                    Checkbox(
                      value: _selectAllOnPage,
                      onChanged: (v) => _toggleSelectAllOnPage(pageOrders, v),
                    ),
                    const Text('Select all on this page'),
                    const Spacer(),
                    Text(
                      'Showing ${(_page * _pageSize) + 1}-${(_page * _pageSize) + pageOrders.length} of ${allOrders.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Orders list (paged)
                Expanded(
                  child: ListView.builder(
                    itemCount: pageOrders.length,
                    itemBuilder: (context, index) {
                      final order = pageOrders[index];
                      final isSelected = _selectedOrderIds.contains(order.orderId);

                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (v) => _toggleOrderSelection(order.orderId, v, pageOrders),
                          ),
                          title: Text('Order ID: ${order.orderId}'),
                          subtitle: Text(
                              '${order.customerName} • ₹${order.totalAmount.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _showOrderDetails(context, order),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Pagination controls
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
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedOrderIds.clear();
                      }),
                      child: const Text('Clear Selection'),
                    )
                  ],
                ),
              ]),
            ),
    );
  }

  Future<void> _showOrderDetails(BuildContext context, Order order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final items = await orderProvider.fetchOrderItems(order.orderId.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            controller: controller,
            children: [
              Text("Order ID: ${order.orderId}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Customer: ${order.customerName}"),
              Text("Mobile: ${order.mobileNumber}"),
              Text("Address: ${order.address}, ${order.state}"),
              Text("Amount: ₹${order.totalAmount.toStringAsFixed(2)} (Shipping: ₹${order.shippingAmount})"),
              Text("Source: ${order.source} | Guest: ${order.isGuest ? 'Yes' : 'No'}"),
              Text("Payment: ${order.paymentMethod} - ${order.paymentTransactionId}"),
              if (order.orderNote.isNotEmpty) Text("Note: ${order.orderNote}"),
              const Divider(),
              const Text("Items", style: TextStyle(fontWeight: FontWeight.bold)),
              ...items.map((item) {
                final isCombo = item.isCombo;
                final variantName = item.productVariants?['variant_name'] ?? 'N/A';
                final variantPrice = item.productVariants?['saleprice']?.toString() ?? '0';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shopping_cart),
                      title: Text("$variantName - ₹$variantPrice"),
                      subtitle: Text("Qty: ${item.quantity} | Combo: ${isCombo ? 'Yes' : 'No'}"),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
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
        print("❌ Order $orderId: No JSON data returned");
      }
      print('Generating invoice for order: $orderId');
      final invoiceData = await InvoiceService.generateInvoiceFromJson(jsonData!);
      print('Generated invoice data: $invoiceData');
      final success = await orderProvider.uploadInvoiceToSupabaseStorage(invoiceData);

      if (!success) 
      {
        allSuccess = false;
        print("❌ Order $orderId: Failed to upload invoice PDF");
      }
    }

    setState(() => _isGenerating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(allSuccess
            ? 'Invoices generated successfully!'
            : 'Some invoices failed.'),
      ),
    );

    setState(() {
      _selectedOrderIds.clear();
      _selectAllOnPage = false;
    });
  }
}
