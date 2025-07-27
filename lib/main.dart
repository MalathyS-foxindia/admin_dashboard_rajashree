import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/order_model.dart'; // Import your Order model
import 'screens/products.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Changed to blue
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Order Dashboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Order> orders = [];
  List<Order> filteredOrders = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // Fetch data from Supabase Edge Function
  Future<void> fetchOrders() async {
    const url = 'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/getOrderWithItems';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2c29yZ3VpbmN2aW51aXF0b29vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NDg4MTksImV4cCI6MjA2ODIyNDgxOX0.-KCQAmRJ3OrBbIChgwH7f_mUmhWzaahub7fqRsk0qsk',
    });

    if (response.statusCode == 200) {
      
      final Map<String, dynamic> jsonBody = json.decode(response.body);
     
      if (jsonBody.containsKey('orders')) {
        final List<dynamic> orderList = jsonBody['orders'];
        setState(() {
          orders = orderList.map((e) => Order.fromJson(e)).toList();
          filteredOrders = orders;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("Unexpected response: ${response.body}");
      }
    } else {
      setState(() => isLoading = false);
      print("Error fetching: ${response.statusCode} ${response.body}");
    }
  }

  // View full order details including combo data if applicable
  Future<void> showOrderDetails(BuildContext context, Order order) async {
    final url = 'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/getOrderWithItems?order_id=${order.orderId}';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2c29yZ3VpbmN2aW51aXF0b29vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NDg4MTksImV4cCI6MjA2ODIyNDgxOX0.-KCQAmRJ3OrBbIChgwH7f_mUmhWzaahub7fqRsk0qsk',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      final List<dynamic> items = jsonBody['items'] ?? [];

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
                  final bool isCombo = item['is_combo'] == true || item['is_combo'] == 1;
                  final variantName = item['product_variants']?['variant_name'] ?? 'N/A';
                  final variantPrice = item['product_variants']?['saleprice']?.toString() ?? '0';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.shopping_cart),
                        title: Text("$variantName - ₹$variantPrice"),
                        subtitle: Text("Qty: ${item['quantity']} | Combo: ${isCombo ? 'Yes' : 'No'}"),
                      ),
                      if (isCombo && item['combo'] != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Combo: ${item['combo']['combo_name'] ?? ''}"),
                              if (item['combo_items'] != null) ...[
                                Text("Includes Products:"),
                                ...List.from(item['combo_items']).map((p) => Text("- Product ID: ${p['variant_id']}"))
                              ]
                            ],
                          ),
                        )
                      ]

                    ],
                  );
                })
              ],
            ),
          ),
        ),
      );
    } else {
      print("Error loading order details: ${response.statusCode} ${response.body}");
    }
  }

  // Filter orders based on text input
  void filterOrders(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredOrders = orders.where((order) =>
        order.customerName.toLowerCase().contains(searchQuery) ||
        order.mobileNumber.contains(searchQuery) ||
        order.source.toLowerCase().contains(searchQuery)
      ).toList();
    });
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children:  [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
                    leading: Icon(Icons.add_box),
                    title: Text('Add Product'),
                    onTap: () {
                      Navigator.pop(context); // close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => products()),
                      );
                    },
                  ),

            ListTile(
              leading: Icon(Icons.widgets),
              title: Text('Add Combo'),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 400, // Reduced width
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
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateColor.resolveWith((states) => Colors.blue.shade50),
                        columns: const [
                          DataColumn(label: Text("Order Date")),
                          DataColumn(label: Text('Customer')),
                          DataColumn(label: Text('Mobile')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Source')),
                          DataColumn(label: Text('View')),
                        ],
                        rows: filteredOrders.map((order) => DataRow(
                          cells: [
                            DataCell(Text(order.orderDate)),
                            DataCell(Text(order.customerName)),
                            DataCell(Text(order.mobileNumber)),
                            DataCell(Text("₹${order.totalAmount.toStringAsFixed(2)}")),
                            DataCell(Text(order.source)),
                            DataCell(IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => showOrderDetails(context, order),
                            )),
                          ],
                        )).toList(),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
