// lib/widgets/combo_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/combo_model.dart';
import '../models/combo_items_model.dart';
import '../models/products_model.dart';
import '../providers/combo_provider.dart';
import 'product_variant_selector.dart';

class ComboFormDialog extends StatefulWidget {
  final Combo? combo; // null means "Add new"
  const ComboFormDialog({super.key, this.combo});

  @override
  State<ComboFormDialog> createState() => _ComboFormDialogState();
}

class _ComboFormDialogState extends State<ComboFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _skuController;
  late TextEditingController _quantityController; // 👈 combo-level quantity

  List<ComboItem> _items = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.combo?.name ?? "");
    _descController =
        TextEditingController(text: widget.combo?.description ?? "");
    _priceController =
        TextEditingController(text: widget.combo?.price.toString() ?? "");
    _skuController = TextEditingController(
        text: widget.combo?.sku ?? "RFP-BC"); // default for new combos
    _quantityController = TextEditingController(
        text: widget.combo?.comboQuantity?.toString() ?? "0"); // 👈 default 0

    _items = List.from(widget.combo?.items ?? []);
  }

  void _addItem(Variant variant) {
    setState(() {
      _items.add(ComboItem(
        comboId: widget.combo?.comboId ?? 0,
        variantId: variant.id,
        quantityPerCombo: 1,
        productVariants: variant,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int qty) {
    setState(() {
      _items[index] = _items[index].copyWith(quantityPerCombo: qty);
    });
  }

  void _save() {
    final updated = (widget.combo ?? Combo.empty()).copyWith(
      name: _nameController.text,
      description: _descController.text,
      price: int.tryParse(_priceController.text) ?? 0,
      sku: _skuController.text,
      comboQuantity: int.tryParse(_quantityController.text) ?? 0, // 👈 include combo qty
      items: _items,
    );

    final provider = Provider.of<ComboProvider>(context, listen: false);

    if (widget.combo == null) {
      provider.addCombo(updated);
    } else {
      provider.updateCombo(updated);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.combo == null ? "Add Combo" : "Edit Combo"),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: "Combo SKU"),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Combo Name"),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _quantityController,
                decoration:
                    const InputDecoration(labelText: "Combo Quantity"), // 👈 NEW FIELD
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Items"),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final variant = await showDialog<Variant>(
                        context: context,
                        builder: (_) => ProductVariantSelectorDialog(),
                      );
                      if (variant != null) {
                        _addItem(variant);
                      }
                    },
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  return ListTile(
                    title: Text(item.productVariants?.name ?? "Unknown"),
                    subtitle: Text("SKU: ${item.productVariants?.sku ?? 'N/A'}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (item.quantityPerCombo > 1) {
                              _updateItemQuantity(
                                  i, item.quantityPerCombo - 1);
                            }
                          },
                        ),
                        Text(item.quantityPerCombo.toString()),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _updateItemQuantity(
                              i, item.quantityPerCombo + 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(i),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text("Save"),
        ),
      ],
    );
  }
}
