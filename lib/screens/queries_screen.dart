import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;
import '../providers/queries_provider.dart';

class QueriesScreen extends StatefulWidget {
  const QueriesScreen({super.key});

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _rowsPerPage = 5; // Updated default for better desktop view
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // This correctly handles session refresh: Every time the widget is mounted,
    // it fetches the latest data from the provider.
    Future.microtask(() => context.read<QueriesProvider>().fetchQueries());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Helper function to determine the color of the status chip (uses lowercase strings)
  Color _getStatusColor(String status) {
    switch (status) {
      case "open":
        return Colors.redAccent;
      case "inprogress": // Ensure status string matches provider's expectation
        return Colors.orangeAccent;
      case "resolved":
        return Colors.green;
      case "closed":
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  // --- Dialog for Editing Remarks (Prevents Overflow) ---
  Future<void> _showEditRemarkDialog(BuildContext context, dynamic query) async {
    // Assuming query object has a queryId and remarks field
    final TextEditingController remarkCtrl =
    TextEditingController(text: query.remarks ?? '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Edit Remark for Query #${query.queryId}'),
          content: SingleChildScrollView(
            child: TextField(
              controller: remarkCtrl,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: "Enter remark...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
              onPressed: () {
                // CORRECTED CALL: Pass context, queryId, and remark
                context.read<QueriesProvider>().updateRemarks(
                  context,
                  query.queryId,
                  remarkCtrl.text,
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }


  // Now accepts List<dynamic> (assuming it contains QueryModel instances)
  void _exportToCSV(List queries) {
    List<List<dynamic>> rows = [
      ["ID", "Name", "Mobile", "Email", "Message", "Status", "Created At", "Remarks"]
    ];

    for (var q in queries) {
      rows.add([
        q.queryId,
        q.name,
        q.mobileNumber,
        q.email ?? "",
        q.message,
        q.status,
        DateFormat("yyyy-MM-dd HH:mm").format(q.createdAt),
        q.remarks ?? "",
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "queries_export.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("yyyy-MM-dd HH:mm");

    return Container(
      // Removed the unnecessary image background and color overlay
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Consumer<QueriesProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Text(provider.errorMessage,
                  style: const TextStyle(color: Colors.red)),
            );
          }

          var filteredQueries = provider.queries.where((q) {
            final s = _searchCtrl.text.toLowerCase();
            return q.name.toLowerCase().contains(s) ||
                q.mobileNumber.contains(s) ||
                (q.email?.toLowerCase().contains(s) ?? false) ||
                (q.status?.toLowerCase().contains(s) ?? false); // Allow status search
          }).toList();

          if (filteredQueries.isEmpty) {
            return Center(
                child: Text(
                    _searchCtrl.text.isEmpty
                        ? "No queries found"
                        : "No results for \"${_searchCtrl.text}\"",
                    style: const TextStyle(fontSize: 18)));
          }

          final totalPages =
          (filteredQueries.length / _rowsPerPage).ceil().clamp(1, 999);
          final start = _currentPage * _rowsPerPage;
          final end = (start + _rowsPerPage) > filteredQueries.length
              ? filteredQueries.length
              : (start + _rowsPerPage);
          final pageData = filteredQueries.sublist(start, end);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Title, Search, and Export Button (All in one Row)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  const Text("Customer Queries", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

                  const SizedBox(width: 32), // Spacer

                  // Search Filter (Now Centered via Expanded)
                  Expanded(
                    child: SizedBox(
                      width: 400, // Provides a decent minimum size
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: "Search (Name, Mobile, Email)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() => _currentPage = 0),
                      ),
                    ),
                  ),

                  const SizedBox(width: 32), // Spacer

                  // Export Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _exportToCSV(filteredQueries),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text("Export CSV", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 24), // Space between header bar and table

              // 📋 Table
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  // WRAPPED WITH VERTICAL SCROLL: This handles the vertical scrolling of the table data
                  child: Scrollbar(
                    thumbVisibility: true,
                    // Note: The primary ScrollView is set to vertical here
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Scrollbar(
                        thumbVisibility: true,
                        // This SingleChildScrollView handles the horizontal scroll for wide tables
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                            columnSpacing: 25,
                            dataRowMinHeight: 60,
                            dataRowMaxHeight: 80,
                            columns: const [
                              DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Mobile')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Message')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Remarks')),
                              DataColumn(label: Text('Created')),
                            ],
                            rows: pageData.map((q) {
                              // Normalize status string to lowercase for internal consistency
                              final currentStatus = (q.status as String).toLowerCase();

                              return DataRow(
                                cells: [
                                  DataCell(Text(q.queryId.toString())),
                                  DataCell(Text(q.name)),
                                  DataCell(Text(q.mobileNumber)),
                                  DataCell(Text(q.email ?? "-")),
                                  DataCell(
                                    // Keep fixed width for Message to prevent overflow
                                    SizedBox(
                                      width: 150,
                                      child: Text(q.message, overflow: TextOverflow.ellipsis, maxLines: 2),
                                    ),
                                  ),
                                  DataCell(
                                    // Constrain DropdownButton width to prevent overflow
                                    SizedBox(
                                      width: 120,
                                      child: DropdownButton<String>(
                                        value: currentStatus,
                                        icon: const Icon(Icons.keyboard_arrow_down),
                                        underline: Container(),
                                        isExpanded: true, // Use max width available
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            // CORRECTED CALL: Pass context, queryId, and newValue (newStatus)
                                            context.read<QueriesProvider>().updateStatus(context, q.queryId, newValue);
                                          }
                                        },
                                        // Possible statuses must be lowercase to match provider
                                        items: ["open", "inProgress", "resolved", "closed"]
                                            .map<DropdownMenuItem<String>>((String s) {
                                          final statusText = s[0].toUpperCase() + s.substring(1).replaceAll('inProgress', 'In Progress');
                                          final color = _getStatusColor(s);
                                          return DropdownMenuItem<String>(
                                            value: s,
                                            child: Chip(
                                              label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                              backgroundColor: color,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    // Constrain Remarks cell width for better table stability
                                    SizedBox(
                                      width: 150,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              q.remarks == null || q.remarks!.isEmpty
                                                  ? "Add remark"
                                                  : q.remarks!.length > 15
                                                  ? q.remarks!.substring(0, 12) + "..."
                                                  : q.remarks!,
                                              style: TextStyle(
                                                  color: q.remarks == null || q.remarks!.isEmpty ? Colors.grey : Colors.black),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18),
                                            onPressed: () => _showEditRemarkDialog(context, q),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(dateFmt.format(q.createdAt))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 📄 Pagination (This remains outside the table scroll area)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Rows per page selector
                  Row(
                    children: [
                      const Text("Rows per page:"),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _rowsPerPage,
                        items: const [
                          DropdownMenuItem(value: 5, child: Text("5")),
                          DropdownMenuItem(value: 10, child: Text("10")),
                          DropdownMenuItem(value: 20, child: Text("20")),
                        ],
                        onChanged: (int? newRows) {
                          if (newRows != null) {
                            setState(() {
                              _rowsPerPage = newRows;
                              _currentPage = 0; // Reset page
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                          "Page ${_currentPage + 1} of $totalPages (Total ${filteredQueries.length} queries)"),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}


