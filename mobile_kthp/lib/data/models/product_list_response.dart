import 'product.dart';

class ProductListResponse {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  ProductListResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['products'] as List? ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProductListResponse(
      products: list,
      total: (json['total'] ?? 0) as int,
      skip: (json['skip'] ?? 0) as int,
      limit: (json['limit'] ?? 0) as int,
    );
  }
}
