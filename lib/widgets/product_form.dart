// lib/widgets/product_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/products_model.dart';
import '../providers/product_provider.dart';

/// ProductForm
/// - mode: add/edit based on `initial` being null or not
/// - returns true on success
class ProductForm extends StatefulWidget {
  final Product? initial;

  const ProductForm({Key? key, this.initial}) : super(key: key);

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  // basic product fields
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _sku;
  late TextEditingController _category;
  bool _hasVariant = false;

  // non-variant fields
  late TextEditingController _salePrice;
  late TextEditingController _regularPrice;
  late TextEditingController _weight;

  // variant controllers: list of maps for each variant
  List<Map<String, TextEditingController>> _variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _hasVariant = p?.hasVariant ?? false;

    _salePrice = TextEditingController(text: p?.salePrice?.toString() ?? '');
    _regularPrice = TextEditingController(text: p?.regularPrice?.toString() ?? '');
    _weight = TextEditingController(text: p?.weight?.toString() ?? '');

    if (_hasVariant && p?.variants != null) {
      _variants = p!.variants!
          .map((v) => {
                'variant_id': TextEditingController(text: v.id ?? ''),
                'variant_name': TextEditingController(text: v.name),
                'sku': TextEditingController(text: v.sku),
                'saleprice': TextEditingController(text: v.salePrice.toString()),
                'regularprice': TextEditingController(text: v.regularPrice.toString()),
                'weight': TextEditingController(text: v.weight.toString()),
                'color': TextEditingController(text: v.color),
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
      for (var c in m.values) {
        (c as TextEditingController).dispose();
      }
    }
    super.dispose();
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
      });
    });
  }

  void _removeVariantRow(int idx) {
    setState(() {
      final map = _variants.removeAt(idx);
      for (var c in map.values) {
        (c as TextEditingController).dispose();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ProductProvider>(context, listen: false);

    // build Product model
    final product = Product(
      id: widget.initial?.id,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      sku: _sku.text.trim(),
      category: _category.text.trim(),
      hasVariant: _hasVariant,
      salePrice: _hasVariant ? null : double.tryParse(_salePrice.text) ?? 0.0,
      regularPrice: _hasVariant ? null : double.tryParse(_regularPrice.text) ?? 0.0,
      weight: _hasVariant ? null : double.tryParse(_weight.text) ?? 0.0,
      variants: _hasVariant
          ? _variants.map((m) {
              return Variant(
                id: (m['variant_id']!.text.isEmpty) ? null : m['variant_id']!.text,
                name: m['variant_name']!.text,
                sku: m['sku']!.text,
                salePrice: double.tryParse(m['saleprice']!.text) ?? 0.0,
                regularPrice: double.tryParse(m['regularprice']!.text) ?? 0.0,
                weight: double.tryParse(m['weight']!.text) ?? 0.0,
                color: m['color']!.text,
              );
            }).toList()
          : [],
    );

    bool ok;
    if (widget.initial == null) {
      ok = await provider.addProduct(product);
    } else {
      ok = await provider.updateProduct(product);
    }

    if (ok) Navigator.of(context).pop(true);
    else {
      // show error (provider.error)
      final err = provider.error ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Widget _variantCard(int idx) {
    final m = _variants[idx];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextFormField(controller: m['variant_name'], decoration: const InputDecoration(labelText: 'Variant name'), validator: (s) => (s==null||s.isEmpty) ? 'Required' : null)),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeVariantRow(idx)),
            ]),
            TextFormField(controller: m['sku'], decoration: const InputDecoration(labelText: 'SKU')),
            Row(children: [
              Expanded(child: TextFormField(controller: m['saleprice'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale price'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: m['regularprice'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Regular price'))),
            ]),
            TextFormField(controller: m['weight'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight')),
            TextFormField(controller: m['color'], decoration: const InputDecoration(labelText: 'Color')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit product' : 'Add product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // product fields
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: (s) => (s==null||s.isEmpty) ? 'Required' : null),
              TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
              TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU')),
              TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Category')),

              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(value: _hasVariant, onChanged: (v) => setState(() => _hasVariant = v ?? false)),
                  const Text('Has variant'),
                ],
              ),

              if (!_hasVariant) ...[
                TextFormField(controller: _salePrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale price')),
                TextFormField(controller: _regularPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Regular price')),
                TextFormField(controller: _weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight')),
              ] else ...[
                const SizedBox(height: 8),
                ..._variants.asMap().entries.map((e) => _variantCard(e.key)).toList(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(onPressed: _addVariantRow, icon: const Icon(Icons.add), label: const Text('Add Variant')),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: Text(isEdit ? 'Save changes' : 'Create')),
      ],
    );
  }
}
