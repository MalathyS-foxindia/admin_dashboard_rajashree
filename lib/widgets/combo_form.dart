// lib/widgets/combo_form.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // 👈 needed for kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late TextEditingController _quantityController; // combo-level quantity

  List<ComboItem> _items = [];

  File? _imageFile;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

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
        text: widget.combo?.comboQuantity?.toString() ?? "0");

    _items = List.from(widget.combo?.items ?? []);
    _imageUrl = widget.combo?.imageUrl;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final url = await _uploadBytes(bytes, 'combo');
        if (url != null) {
          setState(() {
            _imageFile = null;
            _imageUrl = url;
          });
        }
      } else {
        setState(() => _imageFile = File(picked.path));
      }
    }
  }

  Future<String?> _uploadImage(File file, String prefix) async {
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await Supabase.instance.client.storage
          .from('combo-images')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      return Supabase.instance.client.storage
          .from('combo-images')
          .getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      return null;
    }
  }

  Future<String?> _uploadBytes(Uint8List bytes, String prefix) async {
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await Supabase.instance.client.storage.from('combo-images').uploadBinary(
          fileName, bytes,
          fileOptions: const FileOptions(upsert: true));
      return Supabase.instance.client.storage
          .from('combo-images')
          .getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      return null;
    }
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

  Future<void> _save() async {
    // upload image if file chosen
    if (_imageFile != null) {
      final url = await _uploadImage(_imageFile!, 'combo');
      if (url != null) _imageUrl = url;
    }

    final updated = (widget.combo ?? Combo.empty()).copyWith(
      name: _nameController.text,
      description: _descController.text,
      price: int.tryParse(_priceController.text) ?? 0,
      sku: _skuController.text,
      comboQuantity: int.tryParse(_quantityController.text) ?? 0,
      items: _items,
      imageUrl: _imageUrl,
    );

    final provider = Provider.of<ComboProvider>(context, listen: false);

    if (widget.combo == null) {
      provider.addCombo(updated);
    } else {
      provider.updateCombo(updated);
    }

    Navigator.pop(context, true);
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_imageFile!, width: 90, height: 90, fit: BoxFit.cover),
      );
    }
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child:
            Image.network(_imageUrl!, width: 90, height: 90, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.white70),
    );
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
              GestureDetector(
                onTap: _pickImage,
                child: Align(
                  alignment: Alignment.center,
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 12),
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
                    const InputDecoration(labelText: "Combo Quantity"),
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
