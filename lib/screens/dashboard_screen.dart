import 'package:admin_dashboard_rajashree/screens/customer_screen.dart';
import 'package:admin_dashboard_rajashree/screens/orders_screen.dart';
import 'package:admin_dashboard_rajashree/screens/products_screen.dart';
import 'package:admin_dashboard_rajashree/screens/purchase_screen.dart';
import 'package:admin_dashboard_rajashree/screens/queries_screen.dart';
import 'package:admin_dashboard_rajashree/screens/returns_screen.dart';
import 'package:admin_dashboard_rajashree/screens/trackship_screen.dart';
import 'package:admin_dashboard_rajashree/screens/vendor_screen.dart';
import 'package:admin_dashboard_rajashree/screens/combo_screen.dart';
import 'package:admin_dashboard_rajashree/screens/banner_screen.dart';
import 'package:flutter/material.dart';
import 'package:admin_dashboard_rajashree/screens/login_screen.dart';
import 'package:admin_dashboard_rajashree/services/dashboard_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';



enum DashboardMenu {
  dashboard,
  orders,
  products,
  purchases,
  trackship,
  vendors,
  combos,
  customers,
  queries,
  returns,
  banners
}

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key,this.role = "Executive"});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardMenu selectedMenu = DashboardMenu.dashboard;
  final SupabaseService _supabaseService = SupabaseService();
  DateTime _selectedDate = DateTime.now(); // For daily stats

  bool _isMenuCollapsed = false;

  bool get isAdmin => widget.role.toLowerCase() == "admin";
  bool get isManager => widget.role.toLowerCase() == "manager";
  bool get isExecutive => widget.role.toLowerCase() == "executive";
String _selectedDsource = 'All';
final List<String> _dsourceOptions = ['All', 'Website', 'WhatsApp'];

@override
void initState() {
  super.initState();
  _loadLastMenu();
}

Future<void> _loadLastMenu() async {
  final prefs = await SharedPreferences.getInstance();
  final lastMenu = prefs.getString('last_menu');
  if (lastMenu != null) {
    setState(() {
      selectedMenu = DashboardMenu.values.firstWhere(
        (m) => m.toString() == lastMenu,
        orElse: () => DashboardMenu.dashboard,
      );
    });
  }
}

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
Future<void> _saveMenu(DashboardMenu menu) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_menu', menu.toString());
  }

  void _onMenuSelect(DashboardMenu menu) {
    setState(() {
      selectedMenu = menu;
    });
    _saveMenu(menu); // ✅ Save on every change
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 3,
        title: Row(
          children: [
              Image.asset('assets/images/logo.png', height: 32),
              const SizedBox(width: 12),
            const Text(
              "Rajashree Fashions",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepPurple),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: "profile", child: Text("Profile")),
              const PopupMenuItem(value: "settings", child: Text("Settings")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.lightGreenAccent),
            tooltip: 'Logout',
            onPressed: () async {
            final supabase = Supabase.instance.client;

            // 1️⃣ Sign out from Supabase
            await supabase.auth.signOut();

            // 2️⃣ Remove locally saved session data
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('supabase_session');
            await prefs.remove('access_token'); // if you saved this too
            await prefs.remove('last_menu'); // Clear last menu on logout
            // 3️⃣ Navigate to login screen
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
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

  Widget _buildSideMenu() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isMenuCollapsed = false),
      onExit: (_) => setState(() => _isMenuCollapsed = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isMenuCollapsed ? 70 : 235,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF7E57C2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 18), // ⬅️ more top-bottom padding
          children: [
            if (isAdmin)
              _buildMenuItem(DashboardMenu.dashboard, Icons.dashboard, "Dashboard", allowed: true),
            _buildMenuItem(DashboardMenu.orders, Icons.shopping_cart, "Orders", allowed: isAdmin || isManager),
            _buildMenuItem(DashboardMenu.products, Icons.store, "Products", allowed: isAdmin || isManager),
            _buildMenuItem(DashboardMenu.combos, Icons.all_inbox, "Combos", allowed: isAdmin || isManager),
            _buildMenuItem(DashboardMenu.purchases, Icons.receipt, "Purchase", allowed: isAdmin),
            _buildMenuItem(DashboardMenu.trackship, Icons.local_shipping, "Trackship", allowed: true),
            _buildMenuItem(DashboardMenu.vendors, Icons.store_mall_directory, "Vendors", allowed: isAdmin),
            _buildMenuItem(DashboardMenu.customers, Icons.person, "Customers", allowed: isAdmin),
            _buildMenuItem(DashboardMenu.queries, Icons.live_help_sharp, "Queries", allowed: isAdmin || isManager),
            _buildMenuItem(DashboardMenu.returns, Icons.assignment_returned, "Returns", allowed: isAdmin || isManager),
            _buildMenuItem(DashboardMenu.banners, Icons.image, "Banners", allowed: isAdmin)
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(DashboardMenu menu, IconData icon, String title, {required bool allowed}) {
    final isSelected = selectedMenu == menu;
    if (!allowed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
       
        onTap: () => _onMenuSelect(menu),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 7), // ⬅️ taller items
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24), // ⬅️ slightly bigger icon
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-0.3, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: _isMenuCollapsed
                      ? const SizedBox.shrink()
                      : Padding(
                    key: ValueKey(title),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14, // ⬅️ bigger font size
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedMenu) {
    case DashboardMenu.dashboard:
    return isAdmin ? _buildDashboardContent() : _noAccess();
    case DashboardMenu.orders:
    return (isAdmin || isManager) ? const OrdersScreen() : _noAccess();
    case DashboardMenu.products:
    return (isAdmin || isManager) ? const ProductsScreen() : _noAccess();
    case DashboardMenu.combos:
    return const ComboScreen();
    case DashboardMenu.purchases:
    return isAdmin ? const PurchasePage() : _noAccess();
    case DashboardMenu.trackship:
    return TrackShipScreen();
    case DashboardMenu.vendors:
    //return const VendorScreen();
    return isAdmin ? const VendorScreen() : _noAccess();
    case DashboardMenu.customers:
    return isAdmin ? const CustomersScreen() : _noAccess();
    case DashboardMenu.queries:
    return (isAdmin || isManager) ? const QueriesScreen() : _noAccess();
    case DashboardMenu.returns:
    return (isAdmin || isManager) ? const ReturnsScreen() : _noAccess();
    case DashboardMenu.banners:
    return isAdmin ?  const BannerFormScreen() : _noAccess();
    }
  }

  Widget _noAccess() {
    return const Center(
      child: Text("🚫 You do not have permission to view this page",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
  Widget _buildDashboardContent() {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;
    final isTablet = width >= 700 && width < 1000;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard Overview",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Data for: ",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  _selectedDate.toLocal().toString().split(' ')[0],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context),
                ),
              ],
            ),
            const SizedBox(height: 40),
              Row(
                children: [
                  const Text(
                    "Source: ",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedDsource,
                    items: _dsourceOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDsource = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

            // --- Summary Cards ---
            FutureBuilder<List<dynamic>>(
  future: Future.wait([
    _supabaseService.getDailySalesStats(
      _selectedDate,
       _selectedDsource == 'All' ? null : _selectedDsource
    ),
    _supabaseService.getTotalCustomers(),
    _supabaseService.getTotalProducts(),
  ]),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError || !snapshot.hasData) {
      return const Center(child: Text("Failed to load data."));
    }

    final dailyStats = snapshot.data![0] as List<Map<String, dynamic>>;
    final customerCount = snapshot.data![1] as int;
    final productCount = snapshot.data![2] as int;

    final totalSales = dailyStats.isNotEmpty
        ? dailyStats[0]['total_sales']?.toString() ?? '0'
        : '0';
    final orderCount = dailyStats.isNotEmpty
        ? dailyStats[0]['order_count']?.toString() ?? '0'
        : '0';

    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 2.5 : 2.0,
      children: [
        _SummaryCard(
          title: "Sales (${_selectedDate == DateTime.now() ? 'Today' : 'Selected'})",
          value: "₹$totalSales",
          color: const Color(0xFF7E57C2),
          icon: Icons.currency_rupee,
          gradient: const LinearGradient(
            colors: [Color(0xFF7E57C2), Color(0xFF4A90E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _SummaryCard(
          title: "Orders (${_selectedDate == DateTime.now() ? 'Today' : 'Selected'})",
          value: orderCount,
          color: Colors.green,
          icon: Icons.shopping_bag,
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _SummaryCard(
          title: "Customers",
          value: customerCount.toString(),
          color: Colors.orange,
          icon: Icons.people,
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _SummaryCard(
          title: "Products",
          value: productCount.toString(),
          color: Colors.purple,
          icon: Icons.inventory,
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  },
),
const SizedBox(height: 20),

            // --- Line Chart for Last Week ---
            const Text("Weekly Sales & Orders", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
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

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 1,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.3),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.3),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  int idx = value.toInt();
                                  if (idx >= 0 && idx < data.length) {
                                    final date = DateTime.parse(data[idx]['sale_date']);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        "${date.day}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }
                                  return const Text("");
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: salesSpots,
                              isCurved: true,
                              color: Colors.blue.shade700,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                            ),
                            LineChartBarData(
                              spots: ordersSpots,
                              isCurved: true,
                              color: Colors.green.shade700,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.2)),
                            ),
                          ],
                        ),
                      ),
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
  final Gradient? gradient;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
