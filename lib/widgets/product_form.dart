import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/products_model.dart';
import '../providers/product_provider.dart';

class ProductForm extends StatefulWidget {
  final Product? initial;
  const ProductForm({super.key, this.initial});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _sku;
  late TextEditingController _category;
  bool _hasVariant = false;

  late TextEditingController _salePrice;
  late TextEditingController _regularPrice;
  late TextEditingController _weight;

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
        c.dispose();
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
        c.dispose();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ProductProvider>(context, listen: false);

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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: m['variant_name'],
                  decoration: const InputDecoration(labelText: 'Variant name'),
                  validator: (s) => (s == null || s.isEmpty) ? 'Required' : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeVariantRow(idx),
              ),
            ]),
            TextFormField(controller: m['sku'], decoration: const InputDecoration(labelText: 'SKU')),
            Row(children: [
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
    final provider = Provider.of<ProductProvider>(context);

    return AlertDialog(
      title: Text(isEdit ? 'Edit product' : 'Add product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: (s) => (s == null || s.isEmpty) ? 'Required' : null),
              TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
              TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU')),

              // 🔽 use dropdown if categories exist
              Consumer<ProductProvider>(
                builder: (ctx, prov, _) {
                  final cats = prov.categories;
                  if (cats.isEmpty) {
                    return TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Category'));
                  }
                  return DropdownButtonFormField<String>(
                    value: _category.text.isNotEmpty ? _category.text : null,
                    items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) _category.text = val;
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  );
                },
              ),

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
                ..._variants.asMap().entries.map((e) => _variantCard(e.key)),
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
