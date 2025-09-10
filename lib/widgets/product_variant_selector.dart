// lib/widgets/product_variant_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/products_model.dart';
import '../providers/product_provider.dart';

class ProductVariantSelectorDialog extends StatefulWidget {
  const ProductVariantSelectorDialog({super.key});

  @override
  State<ProductVariantSelectorDialog> createState() =>
      _ProductVariantSelectorDialogState();
}

class _ProductVariantSelectorDialogState
    extends State<ProductVariantSelectorDialog> {
  String _search = "";
  int _maxResults = 100; // ✅ limit results to avoid UI freeze

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final variants = provider.variants
        .where((v) =>
            (v.name ?? '').toLowerCase().contains(_search.toLowerCase()) ||
            (v.sku ?? '').toLowerCase().contains(_search.toLowerCase()))
        .toList();

    final limited = variants.take(_maxResults).toList();

    return AlertDialog(
      title: const Text("Select Product Variant"),
      content: SizedBox(
        width: 500,
        height: 450,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Search",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: limited.length + (variants.length > _maxResults ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == limited.length) {
                    // Load More button
                    return TextButton(
                      onPressed: () => setState(() => _maxResults += 100),
                      child: const Text("Load more..."),
                    );
                  }
                  final v = limited[i];
                  return ListTile(
                    title: Text(v.name ?? "Unnamed"),
                    subtitle: Text(
                      "SKU: ${v.sku ?? '-'} | Stock: ${v.stock}",
                      style: TextStyle(
                        color: (v.stock ?? 0) <= 0 ? Colors.red : null,
                      ),
                    ),
                    trailing: Text("₹${v.salePrice}"),
                    onTap: () => Navigator.pop(context, v),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
