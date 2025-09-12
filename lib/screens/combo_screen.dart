// lib/screens/combo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/combo_provider.dart';
import '../models/combo_model.dart';
import '../models/combo_items_model.dart';
import '../widgets/combo_form.dart';

class ComboScreen extends StatefulWidget {
  const ComboScreen({super.key});

  @override
  State<ComboScreen> createState() => _ComboScreenState();
}

class _ComboScreenState extends State<ComboScreen> {
  String _searchQuery = '';
  final List<int> _pageSizeOptions = [5, 10, 25, 50];
  final Set<int> _selectedComboIds = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ComboProvider>(context, listen: false)
          .fetchCombos(reset: true);
    });
  }

  Future<void> _openEditDialog(Combo combo) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => ComboFormDialog(combo: combo), // 👈 use new widget
  );
  if (ok == true && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Combo updated successfully')));
    Provider.of<ComboProvider>(context, listen: false)
        .fetchCombos(reset: true, search: _searchQuery);
  }
}



  Future<void> _showComboDetails(Combo combo) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Items in ${combo.sku}"),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: combo.items.map((item) {
                final lowStock =
                    (item.productVariants?.stock ?? 0) < item.quantityPerCombo;
                return ListTile(
                  title: Text(item.productVariants!.name),
                  subtitle: Text("SKU: ${item.productVariants?.sku}"),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Qty: ${item.quantityPerCombo}"),
                      Text(
                        "Stock: ${item.productVariants?.stock ?? 0}",
                        style: TextStyle(
                          color: lowStock ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openEditDialog(combo);
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit Combo"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(ComboProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search combos...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                provider.fetchCombos(reset: true, search: val);
              },
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _selectedComboIds.isEmpty
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Exporting ${_selectedComboIds.length} combos...')));
                  },
            icon: const Icon(Icons.download),
            label: const Text("Export"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComboProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Combo Management'),actions: [
  IconButton(
    icon: const Icon(Icons.add),
    onPressed: () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => const ComboFormDialog(), // 👈 no combo = add new
      );
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Combo added successfully')));
        Provider.of<ComboProvider>(context, listen: false)
            .fetchCombos(reset: true, search: _searchQuery);
      }
    },
  ),
]),
          body: Column(
            children: [
              _buildFilterBar(provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      provider.fetchCombos(reset: true, search: _searchQuery),
                  child: provider.isLoading && provider.combos.isEmpty
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
                                        _selectedComboIds.clear();
                                        if (_selectAll) {
                                          _selectedComboIds.addAll(
                                              provider.combos.map(
                                                  (c) => c.comboId ?? 0));
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const DataColumn(label: Text('SKU')),
                                const DataColumn(label: Text('Name')),
                                const DataColumn(label: Text('Price')),
                                const DataColumn(label: Text('Quantity')),
                                const DataColumn(label: Text('Status')),
                                const DataColumn(label: Text('Actions')),
                              ],
                              rows: provider.combos.map((combo) {
                                final isSelected =
                                    _selectedComboIds.contains(combo.comboId);
                                return DataRow(
                                  selected: isSelected,
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedComboIds
                                                  .add(combo.comboId ?? 0);
                                            } else {
                                              _selectedComboIds
                                                  .remove(combo.comboId ?? 0);
                                              _selectAll = false;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      InkWell(
                                        onTap: () => _showComboDetails(combo),
                                        child: Text(
                                          combo.sku,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(combo.name)),
                                    DataCell(Text("₹${combo.price}")),
                                    DataCell(
                                        Text(combo.comboQuantity.toString())),
                                    DataCell(
                                      Switch(
                                        value: combo.isActive,
                                        onChanged: (val) {
                                          provider.toggleStatus(
                                              combo.comboId, val);
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _openEditDialog(combo),
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
                          ? () => provider.previousPage(search: _searchQuery)
                          : null,
                    ),
                    Text('Page ${provider.currentPage} of ${provider.totalPages}'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: provider.hasMore && !provider.isLoading
                          ? () => provider.nextPage(search: _searchQuery)
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
                          provider.setPageSize(v, search: _searchQuery);
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

/// ---------- Inline Edit Dialog ----------
class _EditComboDialog extends StatelessWidget {
  final Combo combo;
  const _EditComboDialog({required this.combo});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: combo.name);
    final descController = TextEditingController(text: combo.description ?? "");
    final priceController =
        TextEditingController(text: combo.price.toString());

    return AlertDialog(
      title: const Text("Edit Combo"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Combo Name"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            const Text(
              "Items editing coming soon...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text("Save"),
          onPressed: () {
            final updated = combo.copyWith(
              name: nameController.text,
              description: descController.text,
              price: int.tryParse(priceController.text) ?? combo.price,
            );
            Provider.of<ComboProvider>(context, listen: false)
                .updateCombo(updated);
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
} 