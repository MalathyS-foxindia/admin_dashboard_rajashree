import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class products extends StatefulWidget {
  const products({super.key});

  @override
  State<products> createState() => _ProductsState();
}

class _ProductsState extends State<products> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController regularPriceController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  bool hasVariant = false;

  List<Map<String, TextEditingController>> variantControllers = [];

  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editDescriptionController = TextEditingController();
  final TextEditingController _editCategoryController = TextEditingController();
  final TextEditingController _editSalePriceController = TextEditingController();
  final TextEditingController _editRegularPriceController = TextEditingController();
  final TextEditingController _editWeightController = TextEditingController();
  final TextEditingController _editSkuController = TextEditingController();
  bool _editHasVariant = false;
  final List<Map<String, dynamic>> _editVariantControllers = [];

  
  // Helper to clear edit controllers when done
  void _clearEditControllers() {
    _editNameController.clear();
    _editDescriptionController.clear();
    _editCategoryController.clear();
    _editSalePriceController.clear();
    _editRegularPriceController.clear();
    _editWeightController.clear();
    _editSkuController.clear();
    _editHasVariant = false;
    for (var item in _editVariantControllers) {
      final Map<String, TextEditingController> ctrls = item['controllers'];
      for (var c in ctrls.values) {
        c.dispose();
      }
    }
    _editVariantControllers.clear();
  }

  bool _isLoading = true;
  final String _supabaseUrl = 'https://gvsorguincvinuiqtooo.supabase.co';
  final String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2c29yZ3VpbmN2aW51aXF0b29vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NDg4MTksImV4cCI6MjA2ODIyNDgxOX0.-KCQAmRJ3OrBbIChgwH7f_mUmhWzaahub7fqRsk0qsk';

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final url = '$_supabaseUrl/functions/v1/get-product-with-variants';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $_supabaseAnonKey',
      });

      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = jsonDecode(response.body);
        setState(() {
          products = fetchedData.cast<Map<String, dynamic>>();
          filteredProducts = products;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch products: ${response.statusCode}')),
        );
        print('Failed to fetch products: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $e')),
      );
      print('Error fetching products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
Future<void> deleteProduct(String productId, Map<String, dynamic> product) async {
  final url = '$_supabaseUrl/rest/v1/master_product?product_id=eq.$productId';

  final response = await http.delete(
    Uri.parse(url),
    headers: {
      'apikey': _supabaseAnonKey,
      'Authorization': 'Bearer $_supabaseAnonKey',
    },
  );

  if (response.statusCode == 204) {
    setState(() {
      products.remove(product);
      filteredProducts = products;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product deleted successfully.")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to delete product: ${response.body}")),
    );
  }
}
Future<void> deleteVariant(String variantId, Map<String, dynamic> parentProduct) async {
  final url = '$_supabaseUrl/rest/v1/product_variants?id=eq.$variantId';

  final response = await http.delete(
    Uri.parse(url),
    headers: {
      'apikey': _supabaseAnonKey,
      'Authorization': 'Bearer $_supabaseAnonKey',
    },
  );

  if (response.statusCode == 204) {
    setState(() {
      // Find index of the product in the products list
      int productIndex = products.indexWhere((p) => p['product_id'] == parentProduct['product_id']);

      if (productIndex != -1) {
        // Remove the variant with the given ID
        List<dynamic> variantList = products[productIndex]['variants'];
        variantList.removeWhere((variant) => variant['variant_id'] == variantId);

        // Update filtered list too
        filteredProducts = List.from(products);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Variant deleted successfully.")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to delete variant: ${response.body}")),
    );
  }
}

 @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    salePriceController.dispose();
    regularPriceController.dispose();
    weightController.dispose();
    skuController.dispose();
    for (var map in variantControllers) {
      for (var c in map.values) {
        c.dispose();
      }
    }
    // Also dispose edit controllers
    _editNameController.dispose();
    _editDescriptionController.dispose();
    _editCategoryController.dispose();
    _editSalePriceController.dispose();
    _editRegularPriceController.dispose();
    _editWeightController.dispose();
    _editSkuController.dispose();
    for (var item in _editVariantControllers) {
  final Map<String, TextEditingController> controllers = item['controllers'];
  for (var c in controllers.values) {
    c.dispose();
  }
}

    super.dispose();
  }


  void addVariantField() {
    setState(() {
      variantControllers.add({
        'variant_name': TextEditingController(),
        'sku': TextEditingController(),
        'saleprice': TextEditingController(),
        'regularprice': TextEditingController(),
        'weight': TextEditingController(),
        'color': TextEditingController(),
      });
    });
  }

   void _removeEditVariantField(int index) {
    final Map<String, TextEditingController> ctrls = _editVariantControllers[index]['controllers'];
    for (var c in ctrls.values) {
      c.dispose();
    }
    setState(() {
      _editVariantControllers.removeAt(index);
    });
  }
// Helper to add variant fields for editing
  void _addEditVariantField() {
    setState(() {
      _editVariantControllers.add({
        'variant_id': null, // New variants don't have an ID yet
        'controllers': {
          'variant_name': TextEditingController(),
          'sku': TextEditingController(),
          'saleprice': TextEditingController(),
          'regularprice': TextEditingController(),
          'weight': TextEditingController(),
          'color': TextEditingController(),
        }
      });
    });
  }
// Helper to remove variant fields for editing
  
  void addProduct() async {
    final product = {
      'name': nameController.text,
      'description': descriptionController.text,
      'sku': skuController.text,
      'category': categoryController.text,
      'has_variant': hasVariant,
      'variants': hasVariant
          ? variantControllers.map((vc) => {
                'variant_name': vc['variant_name']!.text,
                'sku': vc['sku']!.text,
                'saleprice': double.tryParse(vc['saleprice']!.text) ?? 0,
                'regularprice': double.tryParse(vc['regularprice']!.text) ?? 0,
                'weight': double.tryParse(vc['weight']!.text) ?? 0,
                'color': vc['color']!.text,
              }).toList()
          : null,
      if (!hasVariant) ...{
        'saleprice': double.tryParse(salePriceController.text) ?? 0,
        'regularprice': double.tryParse(regularPriceController.text) ?? 0,
        'weight': double.tryParse(weightController.text) ?? 0,
      }
    };

    final url = '$_supabaseUrl/functions/v1/create-product-with-variants';
    print(jsonEncode(product)); // Debugging line to check the product data
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_supabaseAnonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product),
    );

    if (response.statusCode == 200) {
      setState(() {
        products.add(product);
        filteredProducts = products;
      });
      nameController.clear();
      descriptionController.clear();
      skuController.clear();
      categoryController.clear();
      salePriceController.clear();
      regularPriceController.clear();
      weightController.clear();
      hasVariant = false;
      for (var map in variantControllers) {
        for (var c in map.values) {
          c.clear();
        }
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add product.')),
      );
    }
  }
// --- NEW: Update Product Method ---
  Future<void> updateProduct(Map<String, dynamic> originalProduct) async {
    final productId = originalProduct['product_id'];
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Product ID not found for update.')),
      );
      return;
    }
  print("Original Product : ${jsonEncode(originalProduct)}"); // Debugging line to check the original product data
    final updatedProductPayload = {
      'product_id': productId,
      'name': _editNameController.text,
      'description': _editDescriptionController.text,
      'sku': _editSkuController.text,
      'category': _editCategoryController.text,
      'has_variant': _editHasVariant,
      if (!_editHasVariant) ...{
        'variant_id': originalProduct['variants']?[0]['variant_id'],
        'saleprice': double.tryParse(_editSalePriceController.text) ?? 0,
        'regularprice': double.tryParse(_editRegularPriceController.text) ?? 0,
        'weight': double.tryParse(_editWeightController.text) ?? 0,
      },
      if (_editHasVariant)
        'variants': _editVariantControllers.map((vc) {
          final Map<String, TextEditingController> ctrls = vc['controllers'];
          return {
            'variant_id': vc['variant_id'],
            'variant_name': ctrls['variant_name']!.text,
            'sku': ctrls['sku']!.text,
            'saleprice': double.tryParse(ctrls['saleprice']!.text) ?? 0,
            'regularprice': double.tryParse(ctrls['regularprice']!.text) ?? 0,
            'weight': double.tryParse(ctrls['weight']!.text) ?? 0,
            'color': ctrls['color']!.text,
          };
        }).toList(),
    };
    print("Updated Product : ${jsonEncode(updatedProductPayload)}"); // Debugging line to check the updated product data
    final url = '$_supabaseUrl/functions/v1/update-product-with-variants';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_supabaseAnonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatedProductPayload),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      Navigator.pop(context);
      fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed. ${response.body}')),
      );
    }
  }
// --- NEW: Show Edit Product Popup Method ---
  void showEditProductPopup(Map<String, dynamic> productToEdit) {
    // Populate controllers with existing product data
    _editNameController.text = productToEdit['name'] ?? '';
    _editDescriptionController.text = productToEdit['description'] ?? '';
    _editSkuController.text = productToEdit['sku'] ?? '';
    _editCategoryController.text = productToEdit['category'] ?? '';
    _editHasVariant = productToEdit['has_variant'] ?? false;

    if (!_editHasVariant) {
      for (var variant in productToEdit['variants']) {
      _editSalePriceController.text = (variant['saleprice'] ?? 0.0).toString();
      _editRegularPriceController.text = (variant['regularprice'] ?? 0.0).toString();
      _editWeightController.text = (variant['weight'] ?? 0.0).toString();
         }
    } else {
      // Clear and re-populate variant controllers for editing
      _editVariantControllers.clear();
      if (productToEdit['variants'] != null && productToEdit['variants'] is List) {
        for (var variant in productToEdit['variants']) {
          
          _editVariantControllers.add({
  'variant_id': variant['variant_id'],
  'controllers': {
    'variant_name': TextEditingController(text: variant['variant_name'] ?? ''),
    'sku': TextEditingController(text: variant['sku'] ?? ''),
    'saleprice': TextEditingController(text: (variant['saleprice'] ?? 0.0).toString()),
    'regularprice': TextEditingController(text: (variant['regularprice'] ?? 0.0).toString()),
    'weight': TextEditingController(text: (variant['weight'] ?? 0.0).toString()),
    'color': TextEditingController(text: variant['color'] ?? ''),
  }
});

        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Edit Product"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _editNameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: _editDescriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _editSkuController,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                TextField(
                  controller: _editCategoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _editHasVariant,
                      onChanged: (value) {
                        setStateDialog(() {
                          _editHasVariant = value ?? false;
                          if (!_editHasVariant) {
                            // Clear and dispose variant controllers if unchecked
                            for (var map in _editVariantControllers) {
                              for (var c in map.values) {
                                c.dispose();
                              }
                            }
                            _editVariantControllers.clear();
                          }
                        });
                      },
                    ),
                    const Text('Has Variant'),
                  ],
                ),
                if (!_editHasVariant) ...[
                  TextField(
                    controller: _editSalePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sale Price'),
                  ),
                  TextField(
                    controller: _editRegularPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Regular Price'),
                  ),
                  TextField(
                    controller: _editWeightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight'),
                  ),
                ],
                if (_editHasVariant)
                  Column(
                    children: [
                      ..._editVariantControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var vc = entry.value;
                        final ctrls = vc['controllers'] as Map<String, TextEditingController>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: ctrls['variant_name'],
                                  decoration: const InputDecoration(labelText: 'Variant Name'),
                                ),
                                TextField(
                                  controller: ctrls['sku'],
                                  decoration: const InputDecoration(labelText: 'Variant SKU'),
                                ),
                                TextField(
                                  controller: ctrls['saleprice'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Sale Price'),
                                ),
                                TextField(
                                  controller: ctrls['regularprice'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Regular Price'),
                                ),
                                TextField(
                                  controller: ctrls['weight'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Weight'),
                                ),
                                TextField(
                                  controller: ctrls['color'],
                                  decoration: const InputDecoration(labelText: 'Color'),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _removeEditVariantField(idx);
                                      setStateDialog(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Variant'),
                          onPressed: () {
                            _addEditVariantField();
                            setStateDialog(() {});
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearEditControllers(); // Clear on cancel
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => updateProduct(productToEdit), // Pass the original product data
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // This 'then' block runs when the dialog is closed.
      // Dispose controllers after the dialog is completely dismissed.
      _clearEditControllers();
    });
  }

  void searchProducts(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredProducts = products.where((product) => product['name'].toLowerCase().contains(searchQuery)).toList();
    });
  }
  void _removeVariantField(int index) {
    setState(() {
      for (var c in variantControllers[index].values) {
        c.dispose();
      }
      variantControllers.removeAt(index);
    });
  }

  void showAddProductPopup() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Add Product"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU')),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                Row(
                  children: [
                    Checkbox(
                      value: hasVariant,
                      onChanged: (value) {
                        setState(() {
                          hasVariant = value ?? false;
                          if (!hasVariant) {
                            for (var map in variantControllers) {
                              for (var c in map.values) {
                                c.dispose();
                              }
                            }
                            variantControllers.clear();
                          }
                        });
                        setStateDialog(() {});
                      },
                    ),
                    const Text('Has Variant'),
                  ],
                ),
                if (!hasVariant) ...[
                  TextField(controller: salePriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale Price')),
                  TextField(controller: regularPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Regular Price')),
                  TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight')),
                ],
                if (hasVariant)
                  Column(
                    children: [
                      ...variantControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var vc = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextField(controller: vc['variant_name'], decoration: const InputDecoration(labelText: 'Variant Name')),
                                TextField(controller: vc['sku'], decoration: const InputDecoration(labelText: 'Variant SKU')),
                                TextField(controller: vc['saleprice'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale Price')),
                                TextField(controller: vc['regularprice'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Regular Price')),
                                TextField(controller: vc['weight'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight')),
                                TextField(controller: vc['color'], decoration: const InputDecoration(labelText: 'Color')),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: ()  {
                                      _removeVariantField(idx);
                                      setStateDialog(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Variant'),
                          onPressed: () {
                            addVariantField();
                            setStateDialog(() {});
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: addProduct, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Products")),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddProductPopup,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: searchProducts,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: ExpansionPanelList.radio(
                  children: filteredProducts.map<ExpansionPanelRadio>((product) {
                    final variants = product['variants'] ?? [];
                    return ExpansionPanelRadio(
                      value: product['sku'],
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                          title: Text(product['name'] ?? ''),
                          subtitle: Text('SKU: ${product['sku']} | Category: ${product['category']} | Has Variant: ${product['has_variant'] ? 'Yes' : 'No'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => showEditProductPopup(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => deleteProduct(product['product_id'].toString(), product),
                              ),
                            ],
                          ),
                        );
                      },
                      body: Column(
                        children: [
                          if (product['has_variant'])
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Variant Name')),
                                  DataColumn(label: Text('SKU')),
                                  DataColumn(label: Text('Sale Price')),
                                  DataColumn(label: Text('Regular Price')),
                                  DataColumn(label: Text('Weight')),
                                  DataColumn(label: Text('Color'))
                                
                                ],
                                rows: variants.map<DataRow>((variant) {
                                  return DataRow(cells: [
                                    DataCell(Text(variant['variant_name'] ?? '')),
                                    DataCell(Text(variant['sku'] ?? '')),
                                    DataCell(Text('${variant['saleprice']}')),
                                    DataCell(Text('${variant['regularprice']}')),
                                    DataCell(Text('${variant['weight']}')),
                                    DataCell(Text(variant['color'] ?? '')),
                                    
                                  ]);
                                }).toList(),
                              ),
                            )
                          else
                             SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  
                                  DataColumn(label: Text('Sale Price')),
                                  DataColumn(label: Text('Regular Price')),
                                  DataColumn(label: Text('Weight')),
                                  
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: variants.map<DataRow>((variant) {
                                  return DataRow(cells: [
                                  
                                    DataCell(Text('${variant['saleprice']}')),
                                    DataCell(Text('${variant['regularprice']}')),
                                    DataCell(Text('${variant['weight']}')),                                
                                    DataCell(Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            
                          )),
                                  ]);
                                }).toList(),
                              ),
                            )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      )
    );}
  }

