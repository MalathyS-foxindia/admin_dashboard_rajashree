// lib/screens/add_shipment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shipment_provider.dart';
// import 'package:mobile_scanner/mobile_scanner.dart'; // Enable later when using scanner

class AddShipmentScreen extends StatefulWidget {
  const AddShipmentScreen({super.key});

  @override
  State<AddShipmentScreen> createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _trackingNumberController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final orderId = _orderIdController.text.trim();
    final trackingNumber = _trackingNumberController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      await Provider.of<ShipmentProvider>(context, listen: false).updateTrackingNumber(
        orderId,
        trackingNumber,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Shipment added/updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// Mock button for testing without barcode scanner
  void _fillMockData() {
    _orderIdController.text = "WA000005";
    _trackingNumberController.text = "SHIP67890";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Shipment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _orderIdController,
                decoration: const InputDecoration(
                  labelText: "Order ID",
                  hintText: "Scan or enter Order ID",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Order ID is required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _trackingNumberController,
                decoration: const InputDecoration(
                  labelText: "Tracking ID",
                  hintText: "Scan or enter Tracking ID",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Tracking ID is required" : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Save"),
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bug_report),
                    label: const Text("Mock Data"),
                    onPressed: _fillMockData,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
