import 'dart:convert';
import 'package:admin_dashboard_rajshree/models/purchase_model.dart';
import 'package:provider/provider.dart';
import 'package:admin_dashboard_rajshree/providers/purchase_provider.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/connectors/v1.dart' hide Provider;
import 'package:http/http.dart' as http;
// The main widget for displaying the purchase report.
class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  

  // State variables for managing UI and data.
  final bool _isLoading = true;
  final String _errorMessage = '';
  final List<Purchase> _allPurchases = [];
  List<Purchase> _filteredPurchases = [];
  
  // Pagination variables.
  final int _pageSize = 10;
  int _currentPage = 0;

  // Search controller and query.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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


  // Filters the data based on the search query and updates the displayed list.
  void _filterAndPaginateData() {
    setState(() {
      _filteredPurchases = _allPurchases.where((purchase) {
        final lowerCaseQuery = _searchQuery.toLowerCase();
        return purchase.vendordetails.name.toLowerCase().contains(lowerCaseQuery) ||
               purchase.purchaseId.toLowerCase().contains(lowerCaseQuery);
      }).toList();
      _currentPage = 0; // Reset to the first page after filtering.
    });
  }

  // Returns the subset of data for the current page.
  List<Purchase> get _paginatedPurchases {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    if (startIndex >= _filteredPurchases.length) {
      return [];
    }
    return _filteredPurchases.sublist(
      startIndex,
      endIndex > _filteredPurchases.length ? _filteredPurchases.length : endIndex,
    );
  }

  // Builds the data table rows.
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
      appBar: AppBar(
        title: const Text('Purchase Report'),
      ),
      body: Column(
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
                setState(() {
                  _searchQuery = value;
                  _filterAndPaginateData();
                });
              },
            ),
          ),
          
          // Data display and loading indicator
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : _errorMessage.isNotEmpty
                  ? Expanded(
                      child: Center(
                          child: Text(_errorMessage,
                              style: const TextStyle(color: Colors.red))))
                  : Expanded(
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
                  Text('Page ${_currentPage + 1} of ${(_filteredPurchases.length / _pageSize).ceil()}'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: (_currentPage + 1) * _pageSize < _filteredPurchases.length
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
      ),
    );
  }
}
