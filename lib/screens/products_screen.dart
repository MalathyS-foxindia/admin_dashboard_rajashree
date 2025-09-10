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

  final List<int> _pageSizeOptions = [10, 25, 50, 100];

  /// Track selected product IDs
  final Set<String> _selectedProductIds = {};

  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false)
          .fetchProducts(reset: true);
    });
  }
void _showImageDialog(String imageUrl) {
  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(imageUrl),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black54),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> _openAddDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ProductForm(),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product created')));
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(
        reset: true,
        search: _searchQuery,
        category: _selectedCategory,
      );
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
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(
        reset: true,
        search: _searchQuery,
        category: _selectedCategory,
      );
    }
  }

  Future<void> _showProductDetails(Product p) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        final productActive = _isProductActive(p);

        return AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(p.name)),
              Icon(
                productActive ? Icons.check_circle : Icons.cancel,
                color: productActive ? Colors.green : Colors.red,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.network(p.imageUrl!, height: 100),
                  ),
                Row(
                  children: [
                    const Text('SKU: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(p.sku),
                  ],
                ),
                Row(
                  children: [
                    const Text('Category: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(p.category),
                  ],
                ),
                const SizedBox(height: 10),
                if (p.variants != null && p.variants!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Variants:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...p.variants!.map((v) {
                        final lowStock = (v.stock ?? 0) < 10;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(fontSize: 18)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(v.name)),
                                      Icon(
                                        v.isActive == true
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: v.isActive == true
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'SKU: ${v.sku}, Regular: ${v.regularPrice}, Sale: ${v.salePrice}, Weight: ${v.weight}',
                                  ),
                                  Text(
                                    'Stock: ${v.stock?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          lowStock ? Colors.red : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openEditDialog(p);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
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
          DropdownButton<String?>(
            hint: const Text('Category'),
            value: _selectedCategory,
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All')),
              ...provider.categories
                  .map((cat) =>
                      DropdownMenuItem<String?>(value: cat, child: Text(cat)))
                  .toList(),
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
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _selectedProductIds.isEmpty
                ? null
                : () {
                    // TODO: implement export selected logic
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Exporting ${_selectedProductIds.length} products...')));
                  },
            icon: const Icon(Icons.download),
            label: const Text("Export"),
          ),
        ],
      ),
    );
  }

  bool _isProductActive(Product p) {
    if (p.variants == null || p.variants!.isEmpty) return true;
    return p.variants!.any((v) => v.isActive == true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Products')),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddDialog,
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              _buildFilterBar(provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchProducts(
                    reset: true,
                    search: _searchQuery,
                    category: _selectedCategory,
                  ),
                  child: provider.isLoading && provider.items.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(
                                  label: Checkbox(
                                    value: _selectAll,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectAll = val ?? false;
                                        _selectedProductIds.clear();
                                        if (_selectAll) {
                                          _selectedProductIds.addAll(provider
                                              .items
                                              .map((p) => p.id ?? ''));
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const DataColumn(label: Text('Image')),
                                const DataColumn(label: Text('Name')),
                                const DataColumn(label: Text('SKU')),
                                const DataColumn(label: Text('Category')),
                                const DataColumn(label: Text('Status')),
                                const DataColumn(label: Text('Actions')),
                              ],
                              rows: provider.items.map((p) {
                                final productActive = _isProductActive(p);
                                final isSelected =
                                    _selectedProductIds.contains(p.id);

                                return DataRow(
                                  selected: isSelected,
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedProductIds
                                                  .add(p.id ?? '');
                                            } else {
                                              _selectedProductIds
                                                  .remove(p.id ?? '');
                                              _selectAll = false;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(
  p.imageUrl != null
      ? GestureDetector(
          onTap: () => _showImageDialog(p.imageUrl!),
          child: Image.network(
            p.imageUrl!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        )
      : const Icon(Icons.image_not_supported, size: 40),
),

                                    DataCell(Text(p.name)),
                                    DataCell(
                                      InkWell(
                                        onTap: () => _showProductDetails(p),
                                        child: Text(
                                          p.sku,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(p.category)),
                                    DataCell(
                                      Icon(
                                        productActive
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: productActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _openEditDialog(p),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ),
              // ✅ Pagination footer
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: provider.currentPage > 1 && !provider.isLoading
                          ? () => provider.previousPage(
                                search: _searchQuery,
                                category: _selectedCategory,
                              )
                          : null,
                    ),
                    Text('Page ${provider.currentPage} of ${provider.totalPages}'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: provider.hasMore && !provider.isLoading
                          ? () => provider.nextPage(
                                search: _searchQuery,
                                category: _selectedCategory,
                              )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    const Text('Page size:'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: provider.limit,
                      items: _pageSizeOptions
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text('$s')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          provider.setPageSize(
                            v,
                            search: _searchQuery,
                            category: _selectedCategory,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
