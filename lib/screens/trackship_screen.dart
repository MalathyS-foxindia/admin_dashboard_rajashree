// lib/screens/track_ship_screen.dart
import 'package:admin_dashboard_rajshree/widgets/shipment_form.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/shipment_provider.dart';

class TrackShipScreen extends StatefulWidget {
  const TrackShipScreen({super.key});

  @override
  State<TrackShipScreen> createState() => _TrackShipScreenState();
}

class _TrackShipScreenState extends State<TrackShipScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShipmentProvider>(context, listen: false).fetchShipments();
    });
  }

  Future<String?> _scanBarcodeTest(BuildContext context) async {
    return Future.value("TEST123456789");
  }

  Future<String?> _scanBarcode(BuildContext context) async {
    String? scannedValue;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Scan Barcode")),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                scannedValue = barcodes.first.rawValue ?? "";
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );

    return scannedValue;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShipmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shipment Tracking"),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.shipments.isEmpty
              ? const Center(child: Text("No shipments found"))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // 📌 Desktop / Tablet
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border: TableBorder.all(color: Colors.grey.shade300),
                            columns: const [
                              DataColumn(label: Text("Order ID")),
                              DataColumn(label: Text("Provider")),
                              DataColumn(label: Text("Shipped Date")),
                              DataColumn(label: Text("Tracking Number")),
                              DataColumn(label: Text("Tracking URL")),
                            ],
                            rows: provider.shipments.map((s) {
                              final controller =
                                  TextEditingController(text: s.trackingNumber);
                              bool isEditing = false;

                              return DataRow(
                                cells: [
                                  DataCell(Text(s.orderId.toString())),
                                  DataCell(Text(s.shippingProvider ?? "-")),
                                  DataCell(Text(
                                      s.shippedDate?.toString() ?? "-")),
                                  DataCell(
                                    StatefulBuilder(
                                      builder: (context, setState) {
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: isEditing
                                                  ? TextField(
                                                      controller: controller)
                                                  : Text(s.trackingNumber ?? "-"),
                                            ),
                                            if (isEditing)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.qr_code_scanner,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () async {
                                                  final scanned =
                                                      await _scanBarcodeTest(
                                                          context);
                                                  if (scanned != null &&
                                                      scanned.isNotEmpty) {
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
                                                    await provider
                                                        .updateTrackingNumber(
                                                      s.shipmentId.toString(),
                                                      controller.text,
                                                    );

                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            "Tracking number updated"),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );

                                                    setState(() =>
                                                        isEditing = false);
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            "Failed to update: $e"),
                                                        backgroundColor:
                                                            Colors.red,
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
                                                  controller.text =
                                                      s.trackingNumber ?? "";
                                                  setState(() =>
                                                      isEditing = false);
                                                },
                                              ),
                                            if (!isEditing)
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () =>
                                                    setState(() =>
                                                        isEditing = true),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    s.trackingUrl != null &&
                                            s.trackingUrl!.isNotEmpty
                                        ? InkWell(
                                            onTap: () async {
                                              final url =
                                                  Uri.parse(s.trackingUrl!);
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              }
                                            },
                                            child: const Text(
                                              "Open Link",
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  decoration:
                                                      TextDecoration.underline),
                                            ),
                                          )
                                        : const Text("-"),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    } else {
                      // 📌 Mobile
                      return ListView.builder(
                        itemCount: provider.shipments.length,
                        itemBuilder: (context, index) {
                          final s = provider.shipments[index];
                          final controller =
                              TextEditingController(text: s.trackingNumber);
                          bool isEditing = false;

                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: StatefulBuilder(
                              builder: (context, setState) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      title: Text("Order: ${s.orderId}"),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Provider: ${s.shippingProvider ?? '-'}"),
                                          Text("Shipped: ${s.shippedDate ?? '-'}"),
                                          isEditing
                                              ? TextField(controller: controller)
                                              : Text(
                                                  "Tracking: ${s.trackingNumber ?? '-'}"),
                                          if (s.trackingUrl != null &&
                                              s.trackingUrl!.isNotEmpty)
                                            InkWell(
                                              onTap: () async {
                                                final url =
                                                    Uri.parse(s.trackingUrl!);
                                                if (await canLaunchUrl(url)) {
                                                  await launchUrl(url,
                                                      mode: LaunchMode
                                                          .externalApplication);
                                                }
                                              },
                                              child: const Text(
                                                "Open Tracking Link",
                                                style: TextStyle(
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline),
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isEditing)
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.qr_code_scanner,
                                                  color: Colors.blue),
                                              onPressed: () async {
                                                final scanned =
                                                    await _scanBarcodeTest(
                                                        context);
                                                if (scanned != null &&
                                                    scanned.isNotEmpty) {
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
                                                  await provider
                                                      .updateTrackingNumber(
                                                    s.shipmentId.toString(),
                                                    controller.text,
                                                  );
                                                  setState(() =>
                                                      isEditing = false);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          "Tracking number updated"),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          "Failed to update: $e"),
                                                      backgroundColor:
                                                          Colors.red,
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
                                                controller.text =
                                                    s.trackingNumber ?? "";
                                                setState(() => isEditing = false);
                                              },
                                            ),
                                          if (!isEditing)
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () =>
                                                  setState(() =>
                                                      isEditing = true),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddShipmentScreen(),
            ),
          );
          Provider.of<ShipmentProvider>(context, listen: false)
              .fetchShipments();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
