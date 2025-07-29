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
      map.values.forEach((c) => c.dispose());
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

  void removeVariantField(int index) {
    setState(() {
      variantControllers[index].values.forEach((c) => c.dispose());
      variantControllers.removeAt(index);
    });
  }

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
          : [],
      if (!hasVariant) ...{
        'saleprice': double.tryParse(salePriceController.text) ?? 0,
        'regularprice': double.tryParse(regularPriceController.text) ?? 0,
        'weight': double.tryParse(weightController.text) ?? 0,
      }
    };

    final url = '$_supabaseUrl/functions/v1/create-product-with-variants';
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
        map.values.forEach((c) => c.clear());
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

  void searchProducts(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredProducts = products.where((product) => product['name'].toLowerCase().contains(searchQuery)).toList();
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
                              map.values.forEach((c) => c.dispose());
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
                                    onPressed: () {
                                      removeVariantField(idx);
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
                          subtitle: Text('SKU: ${product['sku']} | Category: ${product['category']}'),
                          trailing: Text(product['has_variant'] ? 'Has Variant' : 'No Variant'),
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
                                  DataColumn(label: Text('Color')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: variants.map<DataRow>((variant) {
                                  return DataRow(cells: [
                                    DataCell(Text(variant['variant_name'] ?? '')),
                                    DataCell(Text(variant['sku'] ?? '')),
                                    DataCell(Text('${variant['saleprice']}')),
                                    DataCell(Text('${variant['regularprice']}')),
                                    DataCell(Text('${variant['weight']}')),
                                    DataCell(Text(variant['color'] ?? '')),
                                    DataCell(Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    products.remove(product);
                                    filteredProducts = products;
                                  });
                                },
                              ),
                            ],
                          )),
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
                                  
                                    DataCell(Text('${product['saleprice']}')),
                                    DataCell(Text('${product['regularprice']}')),
                                    DataCell(Text('${product['weight']}')),
                                
                                    DataCell(Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    products.remove(product);
                                    filteredProducts = products;
                                  });
                                },
                              ),
                            ],
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

