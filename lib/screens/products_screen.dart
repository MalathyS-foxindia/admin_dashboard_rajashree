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
  String _searchQuery = '';
  String? _selectedCategory;

  // Pagination state
  int _page = 0;
  int _pageSize = 10;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  List<Product> _applyFilter(List<Product> all) {
    return all.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (p.category.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  List<Product> _pagedProducts(List<Product> filtered) {
    final start = _page * _pageSize;
    if (start >= filtered.length) return [];
    final end = (_page + 1) * _pageSize;
    return filtered.sublist(start, end.clamp(0, filtered.length));
  }

  Future<void> _openAddDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ProductForm(),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product created')));
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(reset: true);
    }
  }

  Future<void> _openEditDialog(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ProductForm(initial: p),
    );

   
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product updated')));
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(reset: true);
    }
  }

  Future<void> _confirmDelete(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final ok = await provider.deleteProduct(productId);
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Deleted')));
        provider.fetchProducts(reset: true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Delete failed')));
      }
    }
  }

  Widget _buildFilterBar(ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _page = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Category filter
          DropdownButton<String?>(
            hint: const Text('Category'),
            value: _selectedCategory,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All')),
              ...provider.categories
                  .map((cat) => DropdownMenuItem<String?>(value: cat, child: Text(cat))),
            ],
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
                _page = 0;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final filtered = _applyFilter(provider.items
            .where((p) => _selectedCategory == null || p.category == _selectedCategory)
            .toList());

        final pageProducts = _pagedProducts(filtered);
        final totalPages =
            (filtered.length / _pageSize).ceil().clamp(1, double.infinity).toInt();

        return Scaffold(
          appBar: AppBar(title: const Text('Products')),
          floatingActionButton: FloatingActionButton(
              onPressed: _openAddDialog, child: const Icon(Icons.add)),
          body: Column(
            children: [
              _buildFilterBar(provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchProducts(reset: true),
                  child: Builder(
                    builder: (ctx) {
                      if (provider.isLoading && provider.items.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (provider.error != null && provider.items.isEmpty) {
                        return Center(child: Text('Error: ${provider.error}'));
                      }
                      if (filtered.isEmpty) {
                        return const Center(child: Text('No products found'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: pageProducts.length,
                        itemBuilder: (ctx, i) {
                          final p = pageProducts[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: p.imageUrl != null
                                  ? Image.network(p.imageUrl!,
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported, size: 50),
                              title: Text(p.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle:
                                  Text('SKU: ${p.sku} • Category: ${p.category} - Weight: ${p.weight ?? 'N/A'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _openEditDialog(p)),
                                  IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _confirmDelete(p.id ?? '')),
                                ],
                              ),
                              onTap: () => _openEditDialog(p),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              // Pagination controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 0 ? () => setState(() => _page--) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page ${_page + 1} / $totalPages'),
                  IconButton(
                    onPressed: (_page + 1) < totalPages
                        ? () => setState(() => _page++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: 16),
                  const Text('Page size:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _pageSize,
                    items: _pageSizeOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _pageSize = v;
                        _page = 0;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
