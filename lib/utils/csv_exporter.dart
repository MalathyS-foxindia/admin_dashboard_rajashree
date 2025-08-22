import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/shipment.dart';

class CsvExporter {
  static Future<String> exportShipments(List<Shipment> shipments) async {
    List<List<dynamic>> rows = [
      ['Order ID', 'Tracking Number', 'Provider', 'Status', 'Shipped Date', 'Delivered Date'],
    ];

    for (var s in shipments) {
      rows.add([
        s.orderId ?? '',
        s.trackingNumber ?? '',
        s.shippingProvider ?? '',
        s.shippingStatus ?? '',
        s.shippedDate?.toIso8601String() ?? '',
        s.deliveredDate?.toIso8601String() ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/trackship_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvData);
    return path;
  }
}
