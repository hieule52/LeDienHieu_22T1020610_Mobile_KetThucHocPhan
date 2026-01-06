import '../models/product.dart';
import '../models/product_list_response.dart';
import '../services/api_service.dart';

class ProductRepository {
  final ApiService api;
  ProductRepository(this.api);

  Future<ProductListResponse> getAllProducts({
    int limit = 10,
    int skip = 0,
    String? select, // e.g. "title,price"
    String? sortBy, // e.g. "title"
    String? order, // "asc" | "desc"
  }) async {
    final query = <String, String>{'limit': '$limit', 'skip': '$skip'};

    if (select != null && select.trim().isNotEmpty) query['select'] = select;
    if (sortBy != null && sortBy.trim().isNotEmpty) query['sortBy'] = sortBy;
    if (order != null && order.trim().isNotEmpty) query['order'] = order;

    final json = await api.getJson('/products', query: query);
    return ProductListResponse.fromJson(json);
  }

  Future<Product> getSingleProduct(int id) async {
    final json = await api.getJson('/products/$id');
    return Product.fromJson(json);
  }

  Future<ProductListResponse> searchProducts(
    String q, {
    int limit = 10,
    int skip = 0,
  }) async {
    final json = await api.getJson(
      '/products/search',
      query: {'q': q, 'limit': '$limit', 'skip': '$skip'},
    );
    return ProductListResponse.fromJson(json);
  }

  Future<List<String>> getAllCategories() async {
    final list = await api.getJsonList('/products/categories');

    // mỗi item có thể là Map: {slug, name, url}
    return list
        .map((e) {
          if (e is Map) return (e['slug'] ?? e['name'] ?? '').toString();
          return e.toString();
        })
        .where((x) => x.isNotEmpty)
        .toList();
  }

  Future<ProductListResponse> getProductsByCategory(
    String category, {
    int limit = 10,
    int skip = 0,
    String? sortBy,
    String? order,
  }) async {
    final query = <String, String>{'limit': '$limit', 'skip': '$skip'};
    if (sortBy != null && sortBy.isNotEmpty) query['sortBy'] = sortBy;
    if (order != null && order.isNotEmpty) query['order'] = order;

    final json = await api.getJson(
      '/products/category/$category',
      query: query,
    );
    return ProductListResponse.fromJson(json);
  }

  Future<ProductListResponse> getProductsByBrand(
    String brand, {
    int limit = 10,
    int skip = 0,
  }) async {
    // DummyJSON không có endpoint products/brand/... nên dùng search
    // Tìm các sản phẩm có chữ brand trong tên hoặc mô tả
    return searchProducts(brand, limit: limit, skip: skip);
  }
}
