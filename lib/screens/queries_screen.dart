import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/queries_provider.dart';
import 'package:intl/intl.dart';

class QueriesScreen extends StatefulWidget {
  const QueriesScreen({super.key});

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<QueriesProvider>().fetchQueries());
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat("yyyy-MM-dd HH:mm");

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // faded overlay for readability
          color: Colors.white.withOpacity(0.9),
          child: Consumer<QueriesProvider>(
            builder: (ctx, provider, _) {
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
              if (provider.queries.isEmpty) {
                return const Center(child: Text("No queries found"));
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                  MaterialStateProperty.all(Colors.blue.shade100),
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),       // ✅ new
                    DataColumn(label: Text('Mobile')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Message')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Created')),
                  ],
                  rows: provider.queries.map((q) {
                    return DataRow(cells: [
                      DataCell(Text(q.queryId.toString())),
                      DataCell(Text(q.name)),
                      DataCell(Text(q.mobileNumber)),
                      DataCell(Text(q.email ?? "-")),
                      DataCell(Text(q.message)),
                      DataCell(
                        DropdownButton<String>(
                          value: q.status,
                          underline: const SizedBox(),
                          items: ["Open", "In Progress", "Resolved", "Closed"]
                              .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              context
                                  .read<QueriesProvider>()
                                  .updateStatus(q.queryId, val);
                            }
                          },
                        ),
                      ),
                      DataCell(Text(dateFmt.format(q.createdAt))),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
