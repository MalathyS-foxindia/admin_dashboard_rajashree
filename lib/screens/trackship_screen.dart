import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/shipment_provider.dart';
import '../models/shipment.dart';
import '../utils/csv_exporter.dart';
import '../utils/bulk_delete.dart';

class TrackshipScreen extends StatefulWidget {
  const TrackshipScreen({super.key});

  @override
  State<TrackshipScreen> createState() => _TrackshipScreenState();
}

class _TrackshipScreenState extends State<TrackshipScreen> {
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
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                    'Search by Order ID or Tracking Number',
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

              // Summary Cards + Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.start,
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
                    // Buttons always visible but disabled if none selected
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _selectedRows.isEmpty
                              ? null
                              : () {
                            final selectedItems = _selectedRows
                                .map((i) => shipmentProvider
                                .shipments[i])
                                .toList();
                            BulkDelete.confirmAndDelete(
                                context, selectedItems)
                                .then((_) {
                              setState(() {
                                _selectedRows.clear();
                              });
                            });
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _selectedRows.isEmpty
                              ? null
                              : () async {
                            final selectedItems = _selectedRows
                                .map((i) => shipmentProvider
                                .shipments[i])
                                .toList();
                            final path = await CsvExporter
                                .exportShipments(selectedItems);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                  content:
                                  Text('Exported to $path')),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Export'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Data Table / List View
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
    final filteredShipments = provider.shipments.where((s) {
      return s.orderId?.toLowerCase().contains(_searchQuery) == true ||
          s.trackingNumber?.toLowerCase().contains(_searchQuery) == true;
    }).toList();

    final start = _currentPage * _rowsPerPage;
    final end = start + _rowsPerPage;
    final pageItems = filteredShipments.sublist(
        start,
        end > filteredShipments.length
            ? filteredShipments.length
            : end);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: true,
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
            rows: List.generate(pageItems.length, (index) {
              final s = pageItems[index];
              final rowIndex = start + index;
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
                  DataCell(Text(s.trackingNumber ?? "")),
                  DataCell(Text(s.shippingProvider ?? "")),
                  DataCell(Chip(
                    label: Text(s.shippingStatus ?? ""),
                    backgroundColor: _statusColor(s.shippingStatus),
                  )),
                  DataCell(Text(_formatDate(s.shippedDate))),
                  DataCell(Text(_formatDate(s.deliveredDate))),
                ],
              );
            }),
          ),
        ),
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
                'Page ${_currentPage + 1} of ${(filteredShipments.length / _rowsPerPage).ceil()}',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: end < filteredShipments.length
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ),
      ],
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
        return Colors.orange;
      case "Shipped":
        return Colors.blue;
      case "Delivered":
        return Colors.green;
      default:
        return Colors.greenAccent;
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
