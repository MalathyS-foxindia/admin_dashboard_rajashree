// Import the SupabaseService from its new location
import 'package:admin_dashboard_rajshree/screens/orders_screen.dart';
import 'package:admin_dashboard_rajshree/screens/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:admin_dashboard_rajshree/screens/login_screen.dart';
import 'package:admin_dashboard_rajshree/services/dashboard_service.dart';

enum DashboardMenu {
  dashboard,
  orders,
  products,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardMenu selectedMenu = DashboardMenu.dashboard;
  final SupabaseService _supabaseService = SupabaseService();
  DateTime _selectedDate = DateTime.now(); // State variable for the date
  Future<void> _pickDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  );
  if (picked != null && picked != _selectedDate) {
    setState(() {
      _selectedDate = picked;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSideMenu(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// Sidebar menu
  Widget _buildSideMenu() {
    return Container(
      width: 220,
      color: Colors.grey[200],
      child: ListView(
        children: [
          ListTile(
            selected: selectedMenu == DashboardMenu.dashboard,
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () => setState(() => selectedMenu = DashboardMenu.dashboard),
          ),
          ListTile(
            selected: selectedMenu == DashboardMenu.orders,
            leading: const Icon(Icons.shopping_cart),
            title: const Text("Orders"),
            onTap: () => setState(() => selectedMenu = DashboardMenu.orders),
          ),
          ListTile(
            selected: selectedMenu == DashboardMenu.products,
            leading: const Icon(Icons.store),
            title: const Text("Products"),
            onTap: () => setState(() => selectedMenu = DashboardMenu.products),
          ),
        ],
      ),
    );
  }

  /// Main content area
  Widget _buildContent() {
    switch (selectedMenu) {
      case DashboardMenu.dashboard:
        return _buildDashboardContent();
      case DashboardMenu.orders:
        return const OrdersScreen();
      case DashboardMenu.products:
        return const ProductsScreen();
    }
  }

  /// Full dashboard content with cards
  Widget _buildDashboardContent() {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;
    final isTablet = width >= 700 && width < 1000;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard Overview",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    "Data for: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>?>(
              future: _supabaseService.getDailySalesStats(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text("Failed to load data."));
                }

                final dailyStats = snapshot.data!;
                final totalSales = dailyStats.isNotEmpty
                    ? dailyStats[0]['total_sales']?.toString() ?? '0'
                    : '0';
                final orderCount = dailyStats.isNotEmpty
                    ? dailyStats[0]['order_count']?.toString() ?? '0'
                    : '0';

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = isDesktop ? 4 : (isTablet ? 2 : 1);
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 110,
                      ),
                      children: [
                        _SummaryCard(
                          title: "Sales (Today)",
                          value: "₹$totalSales",
                          color: Colors.blue,
                        ),
                        _SummaryCard(
                          title: "Orders (Today)",
                          value: orderCount,
                          color: Colors.green,
                        ),
                        const _SummaryCard(
                            title: "Customers", value: "0", color: Colors.orange),
                        const _SummaryCard(
                            title: "Products", value: "0", color: Colors.purple),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}