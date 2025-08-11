import 'package:admin_dashboard_rajshree/models/order_model.dart';
import 'package:admin_dashboard_rajshree/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_dashboard_rajshree/models/order_item_model.dart';

import '../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<OrderProvider>(context, listen: false).fetchOrders());
  }

  void filterOrders(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.orders.where((order) {
      return order.customerName.toLowerCase().contains(searchQuery) ||
          order.mobileNumber.contains(searchQuery) ||
          order.source.toLowerCase().contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                          hintText: 'Search by name, mobile or source',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          child: ListTile(
                            title: Text('Order ID: ${order.orderId}'),
                            subtitle: Text(
                                '${order.customerName} • ₹${order.totalAmount.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _showOrderDetails(context, order),
                            ),
                        ));
                      },
                    ),
                  ),
                ],
              ),
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
                      subtitle:
                          Text("Qty: ${item.quantity} | Combo: ${isCombo ? 'Yes' : 'No'}"),
                    ),
                   
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
