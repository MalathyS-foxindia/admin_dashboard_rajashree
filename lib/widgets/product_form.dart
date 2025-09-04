import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/products_model.dart';
import '../providers/product_provider.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:googleapis/vision/v1.dart' as vision;

class ProductForm extends StatefulWidget {
  final Product? initial;
  const ProductForm({super.key, this.initial});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  String? _imageUrl;
  final picker.ImagePicker _picker = picker.ImagePicker();

  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _sku;
  late TextEditingController _category;
  bool _hasVariant = false;

  late TextEditingController _salePrice;
  late TextEditingController _regularPrice;
  late TextEditingController _weight;

  List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _hasVariant = p?.hasVariant ?? false;
    _salePrice = TextEditingController(
        text: (p != null && !p.hasVariant && p.variants?.isNotEmpty == true)
            ? p.variants!.first.salePrice.toString()
            : '');
    _regularPrice = TextEditingController(
        text: (p != null && !p.hasVariant && p.variants?.isNotEmpty == true)
            ? p.variants!.first.regularPrice.toString()
            : '');
    _weight = TextEditingController(
        text: (p != null && !p.hasVariant && p.variants?.isNotEmpty == true)
            ? p.variants!.first.weight.toString()
            : '');
    if (p?.variants != null && p!.hasVariant) {
      _variants = p.variants!
          .map((v) => {
                'variant_id': TextEditingController(text: v.id?.toString() ?? ''),
                'variant_name': TextEditingController(text: v.name),
                'sku': TextEditingController(text: v.sku),
                'saleprice': TextEditingController(text: v.salePrice.toString()),
                'regularprice': TextEditingController(text: v.regularPrice.toString()),
                'weight': TextEditingController(text: v.weight.toString()),
                'color': TextEditingController(text: v.color),
                'length': TextEditingController(
                    text: v.length != null ? v.length.toString() : ''),
                'size': TextEditingController(
                    text: v.size != null ? v.size.toString() : ''),
                'isActive': ValueNotifier<bool>(v.isActive ?? true),
                'imageFile': null,
                'imageUrl': v.imageUrl ?? '',
              })
          .toList();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _sku.dispose();
    _category.dispose();
    _salePrice.dispose();
    _regularPrice.dispose();
    _weight.dispose();
    for (var m in _variants) {
      for (var entry in m.entries) {
        if (entry.value is TextEditingController) {
          (entry.value as TextEditingController).dispose();
        } else if (entry.value is ValueNotifier) {
          (entry.value as ValueNotifier).dispose();
        }
      }
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: picker.ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File file, String prefix) async {
    final fileName = '$prefix${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await Supabase.instance.client
          .storage
          .from('product-images')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      return Supabase.instance.client.storage.from('product-images').getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      return null;
    }
  }

  void _addVariantRow() {
    setState(() {
      _variants.add({
        'variant_id': TextEditingController(),
        'variant_name': TextEditingController(),
        'sku': TextEditingController(),
        'saleprice': TextEditingController(),
        'regularprice': TextEditingController(),
        'weight': TextEditingController(),
        'color': TextEditingController(),
        'length': TextEditingController(),
        'size': TextEditingController(),
        'isActive': ValueNotifier<bool>(true),
        'imageFile': null,
        'imageUrl': '',
      });
    });
  }

  void _removeVariantRow(int idx) {
    if (widget.initial != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot delete variants while editing")),
      );
      return;
    }
    setState(() {
      final map = _variants.removeAt(idx);
      for (var entry in map.entries) {
        if (entry.value is TextEditingController) {
          (entry.value as TextEditingController).dispose();
        } else if (entry.value is ValueNotifier) {
          (entry.value as ValueNotifier).dispose();
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<ProductProvider>(context, listen: false);

    // --- Upload main image ---
    if (_imageFile != null) {
      final url = await _uploadImage(_imageFile!, 'product');
      if (url == null) return;
      _imageUrl = url;
    }

    List<Variant>? variantsToSend;
    if (_hasVariant) {
      variantsToSend = [];
      for (var m in _variants) {
        if (m['imageFile'] != null) {
          final url = await _uploadImage(m['imageFile'], m['sku'].text);
          if (url == null) return;
          m['imageUrl'] = url;
        }
        variantsToSend.add(Variant(
          id: m['variant_id']!.text.isEmpty ? null : m['variant_id']!.text,
          name: m['variant_name']!.text,
          sku: m['sku']!.text,
          salePrice: double.tryParse(m['saleprice']!.text) ?? 0.0,
          regularPrice: double.tryParse(m['regularprice']!.text) ?? 0.0,
          weight: double.tryParse(m['weight']!.text) ?? 0.0,
          color: m['color']!.text,
          length: m['length']!.text.isEmpty ? null : double.tryParse(m['length']!.text),
          size: m['size']!.text.isEmpty ? null : double.tryParse(m['size']!.text),
          isActive: (m['isActive'] as ValueNotifier<bool>).value,
          imageUrl: m['imageUrl'],
        ));
      }
    } else {
      variantsToSend = [
        Variant(
          id: widget.initial?.variants?.first.id,
          name: _name.text.trim(),
          sku: _sku.text.trim(),
          salePrice: double.tryParse(_salePrice.text) ?? 0.0,
          regularPrice: double.tryParse(_regularPrice.text) ?? 0.0,
          weight: double.tryParse(_weight.text) ?? 0.0,
          color: '',
          length: null,
          size: null,
          isActive: true,
          imageUrl: _imageUrl,
        ),
      ];
    }

    final product = Product(
      id: widget.initial?.id,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      sku: _sku.text.trim(),
      category: _category.text.trim(),
      hasVariant: _hasVariant,
      variants: variantsToSend,
      imageUrl: _imageUrl,
    );

    bool ok = widget.initial == null
        ? await provider.addProduct(product)
        : await provider.updateProduct(product);

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final err = provider.error ?? 'Unknown error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Widget _variantCard(int idx) {
    final m = _variants[idx];
    final isEdit = widget.initial != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: m['variant_name'],
                    decoration: const InputDecoration(labelText: 'Variant name'),
                    validator: (s) => (s == null || s.isEmpty) ? 'Required' : null,
                  ),
                ),
                if (!isEdit)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeVariantRow(idx),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: m['sku'],
              decoration: const InputDecoration(labelText: 'SKU'),
              readOnly: isEdit,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: m['saleprice'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sale price'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: m['regularprice'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Regular price'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: m['weight'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: m['color'],
                    decoration: const InputDecoration(labelText: 'Color'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: m['length'],
                    decoration: const InputDecoration(labelText: 'Length'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: m['size'],
                    decoration: const InputDecoration(labelText: 'Size'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<bool>(
              valueListenable: m['isActive'],
              builder: (context, value, _) => SwitchListTile(
                dense: true,
                title: Text(value ? "Active" : "Inactive"),
                value: value,
                activeColor: Colors.green,
                onChanged: (val) => m['isActive'].value = val,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _imageFileWidget(m),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await _picker.pickImage(source: picker.ImageSource.gallery);
                    if (picked != null) {
                      setState(() => m['imageFile'] = File(picked.path));
                    }
                  },
                  child: const Text('Upload Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFileWidget(Map<String, dynamic> variant) {
    if (variant['imageFile'] != null) {
      return Image.file(variant['imageFile'], width: 60, height: 60, fit: BoxFit.cover);
    } else if (variant['imageUrl'] != null && variant['imageUrl'].isNotEmpty) {
      return Image.network(variant['imageUrl'], width: 60, height: 60, fit: BoxFit.cover);
    }
    return Container(width: 60, height: 60, color: Colors.grey[300]);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final provider = Provider.of<ProductProvider>(context);

    return AlertDialog(
      title: Text(isEdit ? 'Edit product' : 'Add product'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Product Information", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              GestureDetector(
                onTap: _pickImage,
                child: _imageFile != null
                    ? Image.file(_imageFile!, height: 120, fit: BoxFit.cover)
                    : _imageUrl != null
                        ? Image.network(_imageUrl!, height: 120, fit: BoxFit.cover)
                        : Container(
                            height: 120,
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.camera_alt, size: 40)),
                          ),
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: (s) => (s == null || s.isEmpty) ? 'Required' : null),
              TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
              TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU'), readOnly: isEdit),
              Consumer<ProductProvider>(
                builder: (ctx, prov, _) {
                  final cats = prov.categories;
                  if (cats.isEmpty) {
                    return TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Category'));
                  }
                  return DropdownButtonFormField<String>(
                    value: _category.text.isNotEmpty ? _category.text : null,
                    items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) { if (val != null) _category.text = val; },
                    decoration: const InputDecoration(labelText: 'Category'),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(value: _hasVariant, onChanged: (v) => setState(() => _hasVariant = v ?? false)),
                  const Text('Has variants'),
                ],
              ),
              const SizedBox(height: 8),
              if (!_hasVariant) ...[
                TextFormField(controller: _salePrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale price')),
                TextFormField(controller: _regularPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Regular price')),
                TextFormField(controller: _weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight')),
              ],
              if (_hasVariant) ...[
                const SizedBox(height: 12),
                const Text("Variants", style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                ..._variants.asMap().entries.map((e) => _variantCard(e.key)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addVariantRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Variant'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: provider.isLoading ? null : _submit,
          child: provider.isLoading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Save changes' : 'Create'),
        ),
      ],
    );
  }
}
