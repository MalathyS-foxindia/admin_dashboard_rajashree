import 'package:flutter/material.dart';

class products extends StatefulWidget {
  const products({super.key});

  @override
  State<products> createState() => _productsState();
}

class _productsState extends State<products> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  String searchQuery = '';

  void addProduct() {
    final product = {
      'name': nameController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'sku': skuController.text,
      'stock': int.tryParse(stockController.text) ?? 0,
    };

    setState(() {
      products.add(product);
      filteredProducts = products;
    });

    nameController.clear();
    priceController.clear();
    skuController.clear();
    stockController.clear();
    Navigator.pop(context);
  }

  void searchProducts(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredProducts = products
          .where((product) => product['name'].toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  void showAddProductPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: addProduct, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    filteredProducts = products;
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: searchProducts,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search products',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: WidgetStateColor.resolveWith(
                      (states) => Colors.blue.shade50),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filteredProducts.map((product) {
                    return DataRow(cells: [
                      DataCell(Text(product['name'])),
                      DataCell(Text(product['sku'])),
                      DataCell(Text('₹${product['price'].toStringAsFixed(2)}')),
                      DataCell(Text(product['stock'].toString())),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
