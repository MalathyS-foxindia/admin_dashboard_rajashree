import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    const url = 'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/getOrderWithItems';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['orders'] != null) {
        _orders = List<Order>.from(data['orders'].map((e) => Order.fromJson(e)));
      }
    } else {
      debugPrint('Error fetching orders: ${response.body}');
    }

    _isLoading = false;
    notifyListeners();
  }

// Fetch single order detail (items)
  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    final url = 'https://gvsorguincvinuiqtooo.supabase.co/functions/v1/getOrderWithItems?order_id=$orderId';
    final headers = {
       'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}'
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      final body = json.decode(response.body);
      if (response.statusCode == 200 && body['items'] != null) {
        return (body['items'] as List).map((e) => OrderItem.fromJson(e)).toList();
      }
    } catch (e) {
      print('Order detail fetch error: $e');
    }

    return [];
  }
}