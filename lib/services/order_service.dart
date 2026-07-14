import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dreamventz/models/order_model.dart';
import 'package:dreamventz/models/cart_item.dart';
import 'package:dreamventz/config/supabase_config.dart';

class OrderService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Returns {order_id: String, vendor_ids: List<String>}
  Future<Map<String, dynamic>> createOrder(
    List<CartDisplayItem> cartItems,
    int totalAmount,
    String paymentId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final itemsJson = cartItems.map((item) {
      return {
        'title': item.title,
        'tag': item.tag,
        'quantity': item.quantity,
        'hours': item.hours,
        'unitPrice': item.unitPrice,
        'imageUrl': item.imageUrl,
        'itemType': item.itemType.toString().split('.').last,
      };
    }).toList();

    // Insert and get back the generated order id
    final response = await _client
        .from('orderslist')
        .insert({
          'user_id': userId,
          'total_amount': totalAmount,
          'items': itemsJson,
          'razorpay_payment_id': paymentId,
          'status': 'Payment Received',
        })
        .select('id')
        .single();

    final orderId = response['id'] as String;

    // Resolve vendor_ids from vendor_card_ids in cart
    final vendorCardIds = cartItems
        .where((item) => item.itemType == CartItemType.vendor)
        .map((item) => item.itemId)
        .toSet()
        .toList();

    List<String> vendorIds = [];
    if (vendorCardIds.isNotEmpty) {
      final vendorCards = await _client
          .from('vendor_cards')
          .select('vendor_id')
          .inFilter('id', vendorCardIds);

      vendorIds = (vendorCards as List)
          .map((row) => row['vendor_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
    }

    return {'order_id': orderId, 'vendor_ids': vendorIds};
  }

  Future<List<OrderModel>> fetchActiveOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('orderslist')
        .select()
        .eq('user_id', userId)
        .not('status', 'eq', 'Completed')
        .not('status', 'eq', 'Cancelled')
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((data) => OrderModel.fromJson(data))
        .toList();
  }

  Future<List<OrderModel>> fetchHistoryOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('orderslist')
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['Completed', 'Cancelled'])
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((data) => OrderModel.fromJson(data))
        .toList();
  }
}
