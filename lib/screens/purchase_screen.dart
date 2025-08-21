import 'package:admin_dashboard_rajshree/models/purchase_model.dart';
import 'package:provider/provider.dart';
import 'package:admin_dashboard_rajshree/providers/purchase_provider.dart';
import 'package:flutter/material.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  // Pagination variables
  final int _pageSize = 10;
  int _currentPage = 0;

  // Search controller and query
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Purchase> _filteredPurchases = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PurchaseProvider>(context, listen: false).fetchPurchases();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filters purchases based on the search query
  void _filterAndPaginateData(List<Purchase> allPurchases) {
    setState(() {
      final lowerCaseQuery = _searchQuery.toLowerCase();
      _filteredPurchases = allPurchases.where((purchase) {
        return purchase.vendordetails.name
                .toLowerCase()
                .contains(lowerCaseQuery) ||
            purchase.purchaseId.toLowerCase().contains(lowerCaseQuery);
      }).toList();
      _currentPage = 0; // Reset page when filtering
    });
  }

  // Paginated subset
  List<Purchase> get _paginatedPurchases {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    if (startIndex >= _filteredPurchases.length) return [];
    return _filteredPurchases.sublist(
      startIndex,
      endIndex > _filteredPurchases.length ? _filteredPurchases.length : endIndex,
    );
  }

  // Build rows for table
  List<DataRow> _buildDataRows() {
    return _paginatedPurchases.map((purchase) {
      return DataRow(cells: [
        DataCell(Text(purchase.purchaseId)),
        DataCell(Text(purchase.vendordetails.name)),
        DataCell(Text('\$${purchase.totalAmount.toStringAsFixed(2)}')),
        DataCell(Text('${purchase.items.length} items')),
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Report')),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                provider.errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Apply filtering only once per build
          if (_filteredPurchases.isEmpty && _searchQuery.isEmpty) {
            _filteredPurchases = List.from(provider.purchases);
          }

          return Column(
            children: [
              // Search box
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by Vendor or Purchase ID',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterAndPaginateData(provider.purchases);
                  },
                ),
              ),

              // Data table
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Purchase ID')),
                        DataColumn(label: Text('Vendor Name')),
                        DataColumn(label: Text('Total Amount')),
                        DataColumn(label: Text('Item Count')),
                      ],
                      rows: _buildDataRows(),
                    ),
                  ),
                ),
              ),

              // Pagination controls
              if (_filteredPurchases.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        'Page ${_currentPage + 1} of ${(_filteredPurchases.length / _pageSize).ceil()}',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed:
                            (_currentPage + 1) * _pageSize < _filteredPurchases.length
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
