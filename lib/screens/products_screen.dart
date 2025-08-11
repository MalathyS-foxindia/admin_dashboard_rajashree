// lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/products_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_form.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    // fetch on load
    Future.microtask(() => Provider.of<ProductProvider>(context, listen: false).fetchProducts());
  }

  Future<void> _openAddDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ProductForm(),
    );
    if (ok == true) {
      // optionally show toast
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product created')));
    }
  }

  Future<void> _openEditDialog(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ProductForm(initial: p),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated')));
    }
  }

  Future<void> _confirmDelete(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final ok = await provider.deleteProduct(productId);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Delete failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final products = provider.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(onPressed: _openAddDialog, child: const Icon(Icons.add)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchProducts(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      key: ValueKey(p.id),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('SKU: ${p.sku} • Category: ${p.category}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEditDialog(p)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(p.id ?? '')),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Description: ${p.description}'),
                              const SizedBox(height: 8),
                              if (!p.hasVariant) ...[
                                Text('Sale price: ${p.salePrice ?? 0}'),
                                Text('Regular price: ${p.regularPrice ?? 0}'),
                                Text('Weight: ${p.weight ?? 0}'),
                              ] else ...[
                                Text('Variants (${p.variants?.length ?? 0})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Variant name')),
                                      DataColumn(label: Text('SKU')),
                                      DataColumn(label: Text('Sale')),
                                      DataColumn(label: Text('Regular')),
                                      DataColumn(label: Text('Weight')),
                                      DataColumn(label: Text('Color')),
                                    ],
                                    rows: p.variants!.map((v) {
                                      return DataRow(cells: [
                                        DataCell(Text(v.name)),
                                        DataCell(Text(v.sku)),
                                        DataCell(Text(v.salePrice.toString())),
                                        DataCell(Text(v.regularPrice.toString())),
                                        DataCell(Text(v.weight.toString())),
                                        DataCell(Row(
                                          children: [
                                            Text(v.color),
                                           IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () async {
                                                  final confirmed = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text('Delete variant'),
                                                      content: const Text('Are you sure you want to delete this variant?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(ctx).pop(false),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.of(ctx).pop(true),
                                                          child: const Text('Delete'),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirmed != true) return;

                                                  final prov = Provider.of<ProductProvider>(context, listen: false);
                                                  final ok = await prov.deleteVariant(v.id ?? '');

                                                  if (ok) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Variant deleted')),
                                                    );
                                                    await prov.fetchProducts(); // refresh list
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(prov.error ?? 'Failed')),
                                                    );
                                                  }
                                                },
                                              )
                                          ],
                                        )),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
