import 'dart:convert';
import 'package:admin_dashboard_rajshree/screens/orders_screen.dart';
import 'package:admin_dashboard_rajshree/screens/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:admin_dashboard_rajshree/screens/login_screen.dart';

// import 'package:rajshree_fashions/screens/shipments_screen.dart'; // 🚧 not added yet

enum DashboardMenu {
  dashboard,
  orders,
  products,
  // shipments, // 🚧 commented out until implemented
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardMenu selectedMenu = DashboardMenu.dashboard;

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
          // 🚧 Uncomment when shipments screen is ready
          // ListTile(
          //   selected: selectedMenu == DashboardMenu.shipments,
          //   leading: const Icon(Icons.local_shipping),
          //   title: const Text("Shipments"),
          //   onTap: () => setState(() => selectedMenu = DashboardMenu.shipments),
          // ),
        ],
      ),
    );
  }

  /// Main content area
  Widget _buildContent() {
    switch (selectedMenu) {
      case DashboardMenu.dashboard:
        return _buildDashboardCards(context);

      case DashboardMenu.orders:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
          );
          setState(() => selectedMenu = DashboardMenu.dashboard);
        });
        return const SizedBox.shrink();

      case DashboardMenu.products:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductsScreen()),
          );
          setState(() => selectedMenu = DashboardMenu.dashboard);
        });
        return const SizedBox.shrink();

      // case DashboardMenu.shipments:
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const ShipmentsScreen()),
      //     );
      //     setState(() => selectedMenu = DashboardMenu.dashboard);
      //   });
      //   return const SizedBox.shrink();
    }
  }

  /// Dashboard summary cards
  Widget _buildDashboardCards(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;
    final isTablet = width >= 700 && width < 1000;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = isDesktop ? 4 : (isTablet ? 2 : 1);
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 110,
          ),
          children: const [
            _SummaryCard(title: "Sales", value: "₹0", color: Colors.blue),
            _SummaryCard(title: "Orders", value: "0", color: Colors.green),
            _SummaryCard(title: "Customers", value: "0", color: Colors.orange),
            _SummaryCard(title: "Products", value: "0", color: Colors.purple),
          ],
        );
      },
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
