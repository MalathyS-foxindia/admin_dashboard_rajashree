// lib/screens/add_shipment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shipment_provider.dart';

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

  // Dropdown values
  final List<String> _shippingProviders = [
    "DTDC",
    "Franch Express",
    "India Post"
  ];
  String? _selectedProvider;
  String _trackingUrl = "";

  /// Detect provider + tracking URL from tracking number
 void _detectProviderFromTracking(String trackingNumber) {
  final RegExp isAlphaOnly = RegExp(r'^[A-Za-z]+$');
  String? provider;

  if (trackingNumber.startsWith("C")) {
    provider = "DTDC";
  } else if (!isAlphaOnly.hasMatch(trackingNumber)) {
    provider = "Franch Express";
  } else if (trackingNumber.endsWith("IN")) {
    provider = "India Post";
  }

  setState(() {
    _selectedProvider = provider;
  });
}

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final orderId = _orderIdController.text.trim();
    final trackingNumber = _trackingNumberController.text.trim();
    final provider = _selectedProvider ?? "Other";
    var inline = false;

    setState(() => _isSubmitting = true);
    try {
      await Provider.of<ShipmentProvider>(context, listen: false)
          .updateTrackingNumber(
        orderId,
        trackingNumber,
        provider,
        inline,
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
    _trackingNumberController.text = "C123456";
    _detectProviderFromTracking("C123456");
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
                  onChanged: (value) {
                    // Works for manual typing
                    _detectProviderFromTracking(value);
                  },
                  onFieldSubmitted: (value) {
                    // Works for barcode scanners (Enter key)
                    final cleaned = value.trim();
                    _trackingNumberController.text = cleaned;
                    _detectProviderFromTracking(cleaned);

                    // Delay a bit so setState updates before submit
                    Future.delayed(const Duration(milliseconds: 100), _submit);
                  },
                 
                  validator: (value) =>
                      value == null || value.isEmpty ? "Tracking ID is required" : null,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: "Shipping Provider",
                  border: OutlineInputBorder(),
                ),
                items: _shippingProviders
                    .map((provider) => DropdownMenuItem(
                  value: provider,
                  child: Text(provider),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedProvider = value),
                validator: (value) =>
                value == null ? "Please select a provider" : null,
              ),
              if (_trackingUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  "🔗 Tracking URL: $_trackingUrl",
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            
            ],
          ),
        ),
      ),
    );
  }
}
