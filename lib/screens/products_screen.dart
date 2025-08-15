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
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();

    // First load
    Future.microtask(() {
      Provider.of<ProductProvider>(context, listen: false)
          .fetchProducts(reset: true);
    });

    // Infinite scroll listener
    _scrollController.addListener(() {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !provider.isLoading &&
          provider.hasMore) {
        provider.fetchMoreProducts(
          search: _searchQuery,
          category: _selectedCategory,
        );
      }
    });
  }

  Future<void> _openAddDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ProductForm(),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product created')));
      Provider.of<ProductProvider>(context, listen: false)
          .fetchProducts(reset: true);
    }
  }

  Future<void> _openEditDialog(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ProductForm(initial: p),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product updated')));
      Provider.of<ProductProvider>(context, listen: false)
          .fetchProducts(reset: true);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Deleted')));
        provider.fetchProducts(reset: true);
      } else {
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
                setState(() => _searchQuery = val);
                provider.fetchProducts(
                  reset: true,
                  search: val,
                  category: _selectedCategory,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Category filter
          DropdownButton<String?>(
            hint: const Text('Category'),
            value: _selectedCategory,
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All')),
              ...provider.categories
                  .map((cat) =>
                      DropdownMenuItem<String?>(value: cat, child: Text(cat))),
            ],
            onChanged: (val) {
              setState(() => _selectedCategory = val);
              provider.fetchProducts(
                reset: true,
                search: _searchQuery,
                category: val,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final products = provider.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
          onPressed: _openAddDialog, child: const Icon(Icons.add)),
      body: Column(
        children: [
          _buildFilterBar(provider),
          Expanded(
            child: provider.isLoading && products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.fetchProducts(
                      reset: true,
                      search: _searchQuery,
                      category: _selectedCategory,
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: products.length + (provider.hasMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= products.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final p = products[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: p.image_url != null
                                ? Image.network(p.image_url!,
                                    width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.image_not_supported,
                                    size: 50),
                            title: Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'SKU: ${p.sku} • Category: ${p.category}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _openEditDialog(p)),
                                IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        _confirmDelete(p.id ?? '')),
                              ],
                            ),
                            onTap: () => _openEditDialog(p),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
