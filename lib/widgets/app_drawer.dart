import 'package:flutter/material.dart';
import '../utils/role_helper.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  const AppDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Text("Welcome $role",
                style: const TextStyle(color: Colors.white, fontSize: 20)),
          ),

          if (RoleHelper.canAccessDashboard(role))
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pushNamed(context, "/dashboard"),
            ),

          if (RoleHelper.canAccessOrders(role))
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("Orders"),
              onTap: () => Navigator.pushNamed(context, "/orders"),
            ),

          if (RoleHelper.canAccessProducts(role))
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Products"),
              subtitle: !RoleHelper.canManageProducts(role)
                  ? const Text("View Only", style: TextStyle(fontSize: 12))
                  : null,
              onTap: () => Navigator.pushNamed(context, "/products"),
            ),

          if (RoleHelper.canAccessPurchases(role))
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text("Purchases"),
              onTap: () => Navigator.pushNamed(context, "/purchases"),
            ),

          if (RoleHelper.canAccessVendors(role))
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text("Vendors"),
              onTap: () => Navigator.pushNamed(context, "/vendors"),
            ),

          if (RoleHelper.canAccessShipments(role))
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text("Shipments"),
              onTap: () => Navigator.pushNamed(context, "/shipments"),
            ),
        ],
      ),
    );
  }
}
