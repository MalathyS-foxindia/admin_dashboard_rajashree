import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shipment_provider.dart';
import '../models/shipment.dart';

class BulkDelete {
  static Future<void> confirmAndDelete(
      BuildContext context,
      List<Shipment> selectedShipments,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${selectedShipments.length} shipments?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<ShipmentProvider>(context, listen: false)
          .deleteShipments(selectedShipments.map((s) => s.shipmentId!).toList());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected shipments deleted')),
      );
    }
  }
}
