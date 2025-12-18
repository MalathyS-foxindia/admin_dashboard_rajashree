import 'package:flutter/foundation.dart'; // 👈 needed for kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/products_model.dart';
import '../providers/product_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductForm extends StatefulWidget {
  final Product? initial;
  const ProductForm({super.key, this.initial});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late ValueNotifier<bool> _activeNotifier;

  File? _imageFile;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _sku;
  bool _hasVariant = false;

  late TextEditingController _salePrice;
  late TextEditingController _regularPrice;
  late TextEditingController _weight;

  // ✅ Category & Subcategory
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;

  List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _hasVariant = p?.hasVariant ?? false;
    _imageUrl = p?.imageUrl;
    _salePrice = TextEditingController(
      text: (p != null && !p.hasVariant && p.variants?.isNotEmpty == true)
          ? p.variants!.first.salePrice.toString()
          : '',
    );
    _regularPrice = TextEditingController(
      text: (p != null && !p.hasVariant && p.variants?.isNotEmpty == true)
          ? p.variants!.first.regularPrice.toString()
          : '',
    );
    _weight = TextEditingController(
      text: (p != null && !p.hasVariant && p.variants?.isNotEmpty == true)
          ? p.variants!.first.weight.toString()
          : '',
    );
    _activeNotifier = ValueNotifier<bool>(
      widget.initial == null
          ? true
          : (widget.initial!.variants?.first.isActive ?? false),
    );

    // ✅ category / subcategory
    _selectedSubcategoryId = p?.subcategoryId; // product stores subcategory ID
    _selectedCategoryId = null; // will be inferred later when categories load

    if (p?.variants != null && p!.hasVariant) {
      _variants = p.variants!
          .map(
            (v) => {
              'variant_id': TextEditingController(text: v.id?.toString() ?? ''),
              'variant_name': TextEditingController(text: v.name),
              'sku': TextEditingController(text: v.sku),
              'saleprice': TextEditingController(text: v.salePrice.toString()),
              'regularprice': TextEditingController(
                text: v.regularPrice.toString(),
              ),
              'weight': TextEditingController(text: v.weight.toString()),
              'color': TextEditingController(text: v.color),
              'length': TextEditingController(
                text: v.length != null ? v.length.toString() : '',
              ),
              'size': TextEditingController(
                text: v.size != null ? v.size.toString() : '',
              ),
              'isActive': ValueNotifier<bool>(v.isActive ?? true),
              'imageFile': null,
              'imageUrl': v.imageUrl ?? '',
            },
          )
          .toList();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _sku.dispose();
    _salePrice.dispose();
    _regularPrice.dispose();
    _weight.dispose();
    _activeNotifier.dispose();

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
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final url = await _uploadBytes(bytes, 'product');
        if (url != null) {
          setState(() => _imageUrl = url);
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
          .from('product-images')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      return Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      return null;
    }
  }

  Future<String?> _uploadBytes(Uint8List bytes, String prefix) async {
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await Supabase.instance.client.storage
          .from('product-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
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
        variantsToSend.add(
          Variant(
            id: m['variant_id']!.text.isEmpty ? null : m['variant_id']!.text,
            name: m['variant_name']!.text,
            sku: m['sku']!.text,
            salePrice: double.tryParse(m['saleprice']!.text) ?? 0.0,
            regularPrice: double.tryParse(m['regularprice']!.text) ?? 0.0,
            weight: double.tryParse(m['weight']!.text) ?? 0.0,
            color: m['color']!.text,
            length: m['length']!.text.isEmpty ? null : m['length']!.text,
            size: m['size']!.text.isEmpty ? null : m['size']!.text,
            isActive: (m['isActive'] as ValueNotifier<bool>).value,
            imageUrl: m['imageUrl'],
          ),
        );
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
          isActive: _activeNotifier.value,
          imageUrl: _imageUrl,
        ),
      ];
    }

    final product = Product(
      id: widget.initial?.id,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      sku: _sku.text.trim(),
      subcategoryName: "",
      subcategoryId: _selectedSubcategoryId, // pass int? not ''
      hasVariant: _hasVariant,
      variants: variantsToSend,
      imageUrl: _imageUrl,
      isActive: _activeNotifier.value,
    );

    bool ok = widget.initial == null
        ? await provider.addProduct(product)
        : await provider.updateProduct(product);

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final err = provider.error ?? 'Unknown error';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Widget _buildImagePreview(String? imageUrl, File? localFile) {
    if (localFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(localFile, width: 70, height: 70, fit: BoxFit.cover),
      );
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.white70),
    );
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
            padding: const EdgeInsets.all(8),
            children: [
              const Text(
                "Product Information",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              GestureDetector(
                onTap: _pickImage,
                child: Align(
                  alignment: Alignment.center,
                  child: _buildImagePreview(_imageUrl, _imageFile),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (s) => (s == null || s.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _sku,
                decoration: const InputDecoration(labelText: 'SKU'),
                readOnly: isEdit,
              ),
              const SizedBox(height: 10),

              // ✅ Category + Subcategory dropdowns
              Consumer<ProductProvider>(
                builder: (ctx, prov, _) {
                  final cats = prov.categoriesWithSubs;
                  if (cats.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Determine selectedCategoryId based on subcategory when editing
                  if (_selectedCategoryId == null &&
                      _selectedSubcategoryId != null) {
                    for (var cat in cats) {
                      final subs = List<Map<String, dynamic>>.from(
                        cat['subcategories'],
                      );
                      if (subs.any(
                        (s) => s['subcategory_id'] == _selectedSubcategoryId,
                      )) {
                        _selectedCategoryId = cat['category_id'] as int;
                        break;
                      }
                    }
                  }

                  final selectedCategory = cats.firstWhere(
                    (c) => (c['category_id'] as int) == _selectedCategoryId,
                    orElse: () => cats.first,
                  );

                  final subcategories =
                      (selectedCategory['subcategories'] ?? [])
                          as List<dynamic>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        value: _selectedCategoryId,
                        items: cats
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['category_id'] as int,
                                child: Text(c['category_name'] ?? '-'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                            _selectedSubcategoryId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Subcategory',
                        ),
                        value: _selectedSubcategoryId,
                        items: subcategories
                            .map(
                              (s) => DropdownMenuItem<int>(
                                value: s['subcategory_id'] as int,
                                child: Text(s['name'] ?? '-'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedSubcategoryId = val);
                        },
                        validator: (val) =>
                            (val == null) ? 'Select a subcategory' : null,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: _hasVariant,
                    onChanged: (v) => setState(() => _hasVariant = v ?? false),
                  ),
                  const Text('Has variants'),
                ],
              ),
              const SizedBox(height: 12),

              if (!_hasVariant) ...[
                TextFormField(
                  controller: _salePrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sale price'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _regularPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Regular price'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight'),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _activeNotifier,
                  builder: (context, value, _) => SwitchListTile(
                    dense: true,
                    title: Text(value ? "Active" : "Inactive"),
                    value: value,
                    thumbColor: MaterialStateProperty.all(Colors.green),
                    onChanged: (val) => _activeNotifier.value = val,
                  ),
                ),
              ],

              if (_hasVariant) ...[
                const SizedBox(height: 15),
                const Text(
                  "Variants",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                for (int i = 0; i < _variants.length; i++) _variantCard(i),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: provider.isLoading ? null : _submit,
          child: provider.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  // ✅ Existing variant card kept intact
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
                    decoration: const InputDecoration(
                      labelText: 'Variant name',
                    ),
                    validator: (s) =>
                        (s == null || s.isEmpty) ? 'Required' : null,
                  ),
                ),
                if (!isEdit)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeVariantRow(idx),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: m['sku'],
              decoration: const InputDecoration(labelText: 'SKU'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: m['saleprice'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sale price'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: m['regularprice'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Regular price'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: m['weight'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setState(() {
                        if (kIsWeb) {
                          m['imageFile'] = picked;
                        } else {
                          m['imageFile'] = File(picked.path);
                        }
                      });
                    }
                  },
                  child: _buildImagePreview(
                    m['imageUrl'],
                    m['imageFile'] is File ? m['imageFile'] : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: m['isActive'],
                    builder: (context, value, _) => SwitchListTile(
                      dense: true,
                      title: Text(value ? "Active" : "Inactive"),
                      value: value,
                      onChanged: (val) => m['isActive'].value = val,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
