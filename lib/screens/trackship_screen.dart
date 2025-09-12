// lib/screens/track_ship_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/shipment_provider.dart';
import '../models/shipment.dart';
import '../widgets/shipment_form.dart';

class TrackShipScreen extends StatefulWidget {
  const TrackShipScreen({super.key});

  @override
  State<TrackShipScreen> createState() => _TrackShipScreenState();
}

class _TrackShipScreenState extends State<TrackShipScreen> {
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 0;
  final Set<int> _selectedRows = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShipmentProvider>(context, listen: false).fetchShipments();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    return DateFormat("yyyy-MM-dd").format(date);
  }

  Future<String?> _scanBarcodeTest(BuildContext context) async {
    return Future.value("C123456789");
  }

  /// Detect provider from tracking number
  Map<String, String?> _detectProviderFromTracking(String trackingNumber) {
    String? provider;
    if (trackingNumber.startsWith("C")) {
      provider = "DTDC";
    } else if (trackingNumber.startsWith("F")) {
      provider = "Franch Express";
    } else if (trackingNumber.endsWith("IN")) {
      provider = "India Post";
    }
    return {"provider": provider};
  }

  /// Stub method for Excel export
  Future<void> _exportToExcel(List<Shipment> shipments) async {
    // TODO: Replace with real Excel export logic
    debugPrint("Stub: Exporting ${shipments.length} shipments to Excel...");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Excel export is not yet implemented")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipmentProvider = Provider.of<ShipmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shipment Tracking"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/bg.jpg"), // 🔥 add your background image here
            fit: BoxFit.cover,
          ),
        ),
        child:Container(
          color: Colors.white.withOpacity(0.8),
        child: shipmentProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : shipmentProvider.shipments.isEmpty
            ? const Center(child: Text("No shipments found."))
            : LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            final summary = _getSummary(shipmentProvider);

            return Column(
              children: [
                // 🔎 Search Bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID or Tracking Number',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _currentPage = 0;
                      });
                    },
                  ),
                ),

                // 📊 Summary Cards + Export
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _SummaryCard("Pending",
                                summary['Pending'].toString(),
                                Colors.orange, Icons.schedule),
                            _SummaryCard("Shipped",
                                summary['Shipped'].toString(),
                                Colors.blue, Icons.local_shipping),
                            _SummaryCard("Delivered",
                                summary['Delivered'].toString(),
                                Colors.green, Icons.check_circle),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectedRows.isEmpty
                            ? null
                            : () async {
                          final selectedItems = _selectedRows
                              .map((i) => shipmentProvider.shipments[i])
                              .toList();
                          await _exportToExcel(selectedItems);
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export Excel'),
                      ),
                    ],
                  ),
                ),

                // 📋 Shipments List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        shipmentProvider.refreshShipments(),
                    child: isDesktop
                        ? _buildDataTable(shipmentProvider)
                        : _buildListView(shipmentProvider),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddShipmentScreen(),
            ),
          );
          Provider.of<ShipmentProvider>(context, listen: false).fetchShipments();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 📊 Shipment summary
  Map<String, int> _getSummary(ShipmentProvider provider) {
    final Map<String, int> summary = {
      "Pending": 0,
      "Shipped": 0,
      "Delivered": 0
    };
    for (var s in provider.shipments) {
      summary[s.shippingStatus ?? "Pending"] =
          (summary[s.shippingStatus ?? "Pending"] ?? 0) + 1;
    }
    return summary;
  }

  /// 🖥 DataTable for desktop
  Widget _buildDataTable(ShipmentProvider provider) {
    final filtered = provider.shipments.where((s) {
      return s.orderId?.toLowerCase().contains(_searchQuery) == true ||
          s.trackingNumber?.toLowerCase().contains(_searchQuery) == true;
    }).toList();

    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    final pageItems = filtered.sublist(start, end);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: true,
            columnSpacing: 24,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
            columns: const [
              DataColumn(label: Text("Order ID")),
              DataColumn(label: Text("Provider")),
              DataColumn(label: Text("Shipped Date")),
              DataColumn(label: Text("Tracking Number")),
              DataColumn(label: Text("Tracking URL")),
            ],
            rows: List.generate(pageItems.length, (index) {
              final s = pageItems[index];
              final rowIndex = start + index;
              final controller = TextEditingController(text: s.trackingNumber);
              bool isEditing = false;

              return DataRow(
                selected: _selectedRows.contains(rowIndex),
                onSelectChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedRows.add(rowIndex);
                    } else {
                      _selectedRows.remove(rowIndex);
                    }
                  });
                },
                cells: [
                  DataCell(Text(s.orderId ?? "")),
                  DataCell(Text(s.shippingProvider ?? "-")),
                  DataCell(Text(_formatDate(s.shippedDate))),
                  DataCell(
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          children: [
                            Expanded(
                              child: isEditing
                                  ? TextField(controller: controller)
                                  : Text(s.trackingNumber ?? "-"),
                            ),
                            if (isEditing)
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner,
                                    color: Colors.blue),
                                onPressed: () async {
                                  final scanned =
                                      await _scanBarcodeTest(context);
                                  if (scanned != null && scanned.isNotEmpty) {
                                    controller.text = scanned;
                                  }
                                },
                              ),
                            if (isEditing)
                              IconButton(
                                icon: const Icon(Icons.save,
                                    color: Colors.green),
                                onPressed: () async {
                                  try {
                                    final detected =
                                        _detectProviderFromTracking(
                                            controller.text);

                                    await provider.updateTrackingNumber(
                                      s.orderId.toString(),
                                      controller.text,
                                      detected["provider"] ??
                                          s.shippingProvider ??
                                          "",
                                      true,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text("Tracking number updated"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    setState(() => isEditing = false);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text("Failed to update: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            if (isEditing)
                              IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.red),
                                onPressed: () {
                                  controller.text = s.trackingNumber ?? "";
                                  setState(() => isEditing = false);
                                },
                              ),
                            if (!isEditing)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    setState(() => isEditing = true),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  DataCell(
                    s.trackingUrl != null && s.trackingUrl!.isNotEmpty
                        ? InkWell(
                            onTap: () async {
                              final url = Uri.parse(s.trackingUrl!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text(
                              "Open Link",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        : const Text("-"),
                  ),
                ],
              );
            }),
          ),
        ),

        // Pagination
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Rows per page: '),
              DropdownButton<int>(
                value: _rowsPerPage,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 20, child: Text('20')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _rowsPerPage = v;
                      _currentPage = 0;
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text(
                  'Page ${_currentPage + 1} of ${(filtered.length / _rowsPerPage).ceil()}'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: end < filtered.length
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📱 ListView for mobile
  Widget _buildListView(ShipmentProvider provider) {
    final filtered = provider.shipments.where((s) {
      return s.orderId?.toLowerCase().contains(_searchQuery) == true ||
          s.trackingNumber?.toLowerCase().contains(_searchQuery) == true;
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final s = filtered[index];
        final controller = TextEditingController(text: s.trackingNumber);
        bool isEditing = false;

        return Card(
          margin: const EdgeInsets.all(8),
          child: StatefulBuilder(
            builder: (context, setState) {
              return ListTile(
                title: Text("Order: ${s.orderId}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Provider: ${s.shippingProvider ?? '-'}"),
                    Text("Shipped: ${_formatDate(s.shippedDate)}"),
                    isEditing
                        ? TextField(controller: controller)
                        : Text("Tracking: ${s.trackingNumber ?? '-'}"),
                    if (s.trackingUrl != null && s.trackingUrl!.isNotEmpty)
                      InkWell(
                        onTap: () async {
                          final url = Uri.parse(s.trackingUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text(
                          "Open Tracking Link",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner,
                            color: Colors.blue),
                        onPressed: () async {
                          final scanned = await _scanBarcodeTest(context);
                          if (scanned != null && scanned.isNotEmpty) {
                            controller.text = scanned;
                          }
                        },
                      ),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.save, color: Colors.green),
                        onPressed: () async {
                          try {
                            final detected =
                                _detectProviderFromTracking(controller.text);

                            await provider.updateTrackingNumber(
                              s.shipmentId.toString(),
                              controller.text,
                              detected["provider"] ??
                                  s.shippingProvider ??
                                  "",
                              true,
                            );

                            setState(() => isEditing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Tracking number updated"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Failed to update: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          controller.text = s.trackingNumber ?? "";
                          setState(() => isEditing = false);
                        },
                      ),
                    if (!isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => setState(() => isEditing = true),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard(this.title, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
