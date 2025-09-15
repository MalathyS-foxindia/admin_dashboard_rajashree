// lib/screens/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/customer_model.dart';
import 'package:intl/intl.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final int _pageSize = 10;
  int _currentPage = 0;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Customer> _filtered = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CustomerProvider>().fetchCustomers());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter(List<Customer> all) {
    final q = _searchQuery.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(all);
      } else {
        _filtered = all.where((c) {
          return c.fullName.toLowerCase().contains(q) ||
              c.mobileNumber.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q);
        }).toList();
      }
      _currentPage = 0;
    });
  }

  List<Customer> get _page {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/bg.jpg"), // ✅ Background image
            fit: BoxFit.cover,
          ),
        ),
    child: Container(
    color: Colors.white.withOpacity(0.9),
        child: Consumer<CustomerProvider>(
          builder: (context, provider, _) {
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

            // initialize filter once or when searching changes
            if (_filtered.isEmpty && _searchQuery.isEmpty) {
              _filtered = List.from(provider.customers);
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Search by name / mobile / email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _searchQuery = v;
                      _applyFilter(provider.customers);
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Mobile')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('State')),
                          DataColumn(label: Text('Created')),
                        ],
                        rows: _page.map((c) {
                          return DataRow(
                            cells: [
                              DataCell(Text(c.customerId.toString())),
                              DataCell(Text(c.fullName)),
                              DataCell(Text(c.mobileNumber)),
                              DataCell(Text(c.email)),
                              DataCell(Text(c.state ?? '-')),
                              DataCell(Text(dateFmt.format(c.createdAt))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (_filtered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        Text(
                          'Page ${_currentPage + 1} of ${( (_filtered.length + _pageSize - 1) / _pageSize).floor()}',
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: (_currentPage + 1) * _pageSize <
                              _filtered.length
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
       ),
      ),
    );
  }
}
