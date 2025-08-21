import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shipment_provider.dart';
import 'package:intl/intl.dart';
import '../models/shipment.dart';

class TrackshipScreen extends StatefulWidget {
  const TrackshipScreen({super.key});

  @override
  State<TrackshipScreen> createState() => _TrackshipScreenState();
}

class _TrackshipScreenState extends State<TrackshipScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch shipments as soon as the widget is created.
    // The `listen: false` is crucial here to prevent an infinite loop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShipmentProvider>(context, listen: false).fetchShipments();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return DateFormat("yyyy-MM-dd").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final shipmentProvider = Provider.of<ShipmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trackship"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: shipmentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shipmentProvider.shipments.isEmpty
              ? const Center(child: Text("No shipments found."))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    final summary = _getSummary(shipmentProvider);
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SummaryCard(
                                "Pending",
                                summary['Pending'].toString(),
                                Colors.orange,
                                Icons.schedule,
                              ),
                              _SummaryCard(
                                "Shipped",
                                summary['Shipped'].toString(),
                                Colors.blue,
                                Icons.local_shipping,
                              ),
                              _SummaryCard(
                                "Delivered",
                                summary['Delivered'].toString(),
                                Colors.green,
                                Icons.check_circle,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => shipmentProvider.refreshShipments(),
                            child: isDesktop
                                ? _buildDataTable(shipmentProvider)
                                : _buildListView(shipmentProvider),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

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

  Widget _buildDataTable(ShipmentProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(
          Colors.grey.shade200,
        ),
        columns: const [
          DataColumn(label: Text("Order ID")),
          DataColumn(label: Text("Tracking #")),
          DataColumn(label: Text("Provider")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Shipped Date")),
          DataColumn(label: Text("Delivered Date")),
        ],
        rows: provider.shipments.map((s) {
          return DataRow(cells: [
            DataCell(Text(s.orderId ?? "")),
            DataCell(Text(s.trackingNumber ?? "")),
            DataCell(Text(s.shippingProvider ?? "")),
            DataCell(Chip(
              label: Text(s.shippingStatus ?? ""),
              backgroundColor: _statusColor(s.shippingStatus),
            )),
            DataCell(Text(_formatDate(s.shippedDate))),
            DataCell(Text(_formatDate(s.deliveredDate))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildListView(ShipmentProvider provider) {
    return ListView.builder(
      itemCount: provider.shipments.length,
      itemBuilder: (context, index) {
        final s = provider.shipments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            leading: Icon(
              Icons.local_shipping,
              color: _statusColor(s.shippingStatus),
            ),
            title: Text("Order: ${s.orderId}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tracking: ${s.trackingNumber}"),
                Text("Provider: ${s.shippingProvider}"),
                Text("Status: ${s.shippingStatus}"),
                if (s.shippedDate != null)
                  Text("Shipped: ${_formatDate(s.shippedDate)}"),
                if (s.deliveredDate != null)
                  Text("Delivered: ${_formatDate(s.deliveredDate)}"),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                if (s.trackingUrl != null) {
                  // TODO: launch URL
                }
              },
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "Pending":
        return Colors.orange.shade300;
      case "Shipped":
        return Colors.blue.shade300;
      case "Delivered":
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
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
                Text(
                  title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}