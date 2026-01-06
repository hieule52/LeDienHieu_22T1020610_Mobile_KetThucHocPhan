import '../services/api_service.dart';

class OrderRepository {
  final ApiService api;
  OrderRepository(this.api);

  Future<void> cancelOrder(int id) async {
    // API: DELETE https://dummyjson.com/carts/{id}
    await api.delete('/carts/$id');
  }

  Future<Map<String, dynamic>> getSingleOrder(int id) async {
    // API: GET https://dummyjson.com/carts/{id}
    return await api.getJson('/carts/$id');
  }
}
