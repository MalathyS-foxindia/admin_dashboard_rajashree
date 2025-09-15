/*
import 'package:admin_dashboard_rajshree/screens/customer_screen.dart';
import 'package:admin_dashboard_rajshree/screens/orders_screen.dart';
import 'package:admin_dashboard_rajshree/screens/products_screen.dart';
import 'package:admin_dashboard_rajshree/screens/purchase_screen.dart';
import 'package:admin_dashboard_rajshree/screens/trackship_screen.dart';
import 'package:admin_dashboard_rajshree/screens/vendor_screen.dart';
import 'package:flutter/material.dart';
import 'package:admin_dashboard_rajshree/screens/login_screen.dart';
import 'package:admin_dashboard_rajshree/services/dashboard_service.dart';
import 'package:fl_chart/fl_chart.dart';

enum DashboardMenu {
  dashboard,
  orders,
  products,
  purchases,
  trackship,
  vendors,
  customers,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardMenu selectedMenu = DashboardMenu.dashboard;
  final SupabaseService _supabaseService = SupabaseService();
  DateTime _selectedDate = DateTime.now(); // For daily stats

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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        elevation: 3,
        title: Row(
          children: [
            Image.asset("images/logo.png", height: 32),
            const SizedBox(width: 12),
            const Text(
              "Rajshree Fashions",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepPurple),
            ),
            onSelected: (value) {
              if (value == "logout") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "profile", child: Text("Profile")),
              const PopupMenuItem(value: "settings", child: Text("Settings")),
              const PopupMenuItem(value: "logout", child: Text("Logout")),
            ],
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

  Widget _buildSideMenu() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          //  colors: [Color(0xFF7E57C2), Color(0xFF4A90E2)]),
          colors: [Color(0xFF4A90E2),Color(0xFF7E57C2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        children: [
          _buildMenuItem(DashboardMenu.dashboard, Icons.dashboard, "Dashboard"),
          _buildMenuItem(DashboardMenu.orders, Icons.shopping_cart, "Orders"),
          _buildMenuItem(DashboardMenu.products, Icons.store, "Products"),
          _buildMenuItem(DashboardMenu.purchases, Icons.receipt, "Purchase"),
          _buildMenuItem(DashboardMenu.trackship, Icons.local_shipping, "Trackship"),
          _buildMenuItem(DashboardMenu.vendors, Icons.store_mall_directory, "Vendors"),
          _buildMenuItem(DashboardMenu.customers,Icons.person, "Customers"),
        ],
      ),
    );
  }

  Widget _buildMenuItem(DashboardMenu menu, IconData icon, String title) {
    final isSelected = selectedMenu == menu;
    return ListTile(
      selected: isSelected,
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.deepPurple.shade400 : null,
      onTap: () => setState(() => selectedMenu = menu),
    );
  }

  Widget _buildContent() {
    switch (selectedMenu) {
      case DashboardMenu.dashboard:
        return _buildDashboardContent();
      case DashboardMenu.orders:
        return const OrdersScreen();
      case DashboardMenu.products:
        return const ProductsScreen();
      case DashboardMenu.purchases:
        return const PurchasePage();
      case DashboardMenu.trackship:
        return TrackShipScreen();
      case DashboardMenu.vendors:
        return const VendorScreen();
      case DashboardMenu.customers:
        return const CustomersScreen();
    }
  }

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
                Expanded(
                  child: Text(
                    "Data for: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Summary Cards ---
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
                      icon: Icons.currency_rupee,
                    ),
                    _SummaryCard(
                      title: "Orders (Today)",
                      value: orderCount,
                      color: Colors.green,
                      icon: Icons.shopping_bag,
                    ),
                    const _SummaryCard(
                        title: "Customers",
                        value: "0",
                        color: Colors.orange,
                        icon: Icons.people),
                    const _SummaryCard(
                        title: "Products",
                        value: "0",
                        color: Colors.purple,
                        icon: Icons.inventory),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // --- Line Chart for Last Week ---
            const Text("Weekly Sales & Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>?>(
              future: _supabaseService.getWeeklySalesStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No weekly data available."));
                }

                final data = snapshot.data!;
                final salesSpots = <FlSpot>[];
                final ordersSpots = <FlSpot>[];

                for (int i = 0; i < data.length; i++) {
                  final day = i.toDouble();
                  salesSpots.add(FlSpot(day, (data[i]['total_sales'] ?? 0).toDouble()));
                  ordersSpots.add(FlSpot(day, (data[i]['order_count'] ?? 0).toDouble()));
                }

                return SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              int idx = value.toInt();
                              if (idx >= 0 && idx < data.length) {
                                final date = DateTime.parse(data[idx]['sale_date']);
                                return Text("${date.month}/${date.day}");
                              }
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: salesSpots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                        ),
                        LineChartBarData(
                          spots: ordersSpots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.2)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.25),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: color)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
