import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final String baseUrl = 'https://<your-supabase-id>.functions.supabase.co'; // <- Update this
  final String supabaseKey = '<your-service-role-or-anon-key>'; // <- Update this

  final _vendorController = TextEditingController();
  final _amountController = TextEditingController();

  List<Map<String, TextEditingController>> itemControllers = [];

  bool isLoading = false;
  String result = "";

  @override
  void initState() {
    super.initState();
    addItem(); // Add one item by default
  }

  void addItem() {
    setState(() {
      itemControllers.add({
        "variant_id": TextEditingController(),
        "quantity": TextEditingController(),
        "cost_price": TextEditingController(),
      });
    });
  }

  void removeItem(int index) {
    setState(() {
      itemControllers.removeAt(index);
    });
  }

  Future<void> createPurchase() async {
    final vendor = _vendorController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final items = itemControllers.map((map) {
      return {
        "variant_id": int.tryParse(map["variant_id"]!.text.trim()) ?? 0,
        "quantity": int.tryParse(map["quantity"]!.text.trim()) ?? 0,
        "cost_price": double.tryParse(map["cost_price"]!.text.trim()) ?? 0.0
      };
    }).where((item) => item["variant_id"] != 0 && item["quantity"] != 0).toList();

    if (vendor.isEmpty || items.isEmpty) {
      setState(() {
        result = "Vendor and at least one valid item required.";
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseKey',
        },
        body: jsonEncode({
          "vendor_name": vendor,
          "amount": amount,
          "items": items,
        }),
      );

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          result = "✅ Success! Purchase ID: ${json['purchase_id']}";
        });
      } else {
        setState(() {
          result = "❌ Error: ${json['error']}";
        });
      }
    } catch (e) {
      setState(() {
        result = "❌ Exception: $e";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Purchase")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _vendorController,
              decoration: const InputDecoration(labelText: "Vendor Name"),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Total Amount"),
            ),
            const SizedBox(height: 20),
            const Text("Items", style: TextStyle(fontWeight: FontWeight.bold)),

            ...itemControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controllers = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: controllers["variant_id"],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Variant ID"),
                      ),
                      TextField(
                        controller: controllers["quantity"],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Quantity"),
                      ),
                      TextField(
                        controller: controllers["cost_price"],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Cost Price"),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeItem(index),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            TextButton.icon(
              onPressed: addItem,
              icon: const Icon(Icons.add),
              label: const Text("Add Item"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : createPurchase,
              child: isLoading ? const CircularProgressIndicator() : const Text("Submit Purchase"),
            ),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    for (var map in itemControllers) {
      for (var c in map.values) {
        c.dispose();
      }
    }
    super.dispose();
  }
}
