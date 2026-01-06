import 'package:flutter/material.dart';
import '../../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  /// Bấm icon để thêm vào giỏ (đã check login ở ProductListPage)
  final VoidCallback? onAddToCart;

  /// (tuỳ chọn) giữ lâu để thêm vào giỏ
  final VoidCallback? onLongPressAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.onLongPressAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    const shopeeOrange = Color(0xFF00B14F);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPressAddToCart,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh
            AspectRatio(
              aspectRatio: 1.15,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: 'product_${product.id}',
                        child: Image.network(
                          product.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),

                    // badge giảm giá (nếu có)
                    if ((product.discountPercentage ?? 0) > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: shopeeOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '-${(product.discountPercentage!).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      '${product.price} ₫',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: shopeeOrange,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Rating + Stock
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          _ratingText(product.rating),
                          style: const TextStyle(fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          'Stock: ${product.stock}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Bottom row: hint + add cart button
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Thêm vào giỏ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ),

                        // ✅ Quan trọng: chặn sự kiện tap không “lọt” ra InkWell cha
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: shopeeOrange,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingText(dynamic r) {
    // dummyjson có thể trả double/int
    try {
      final d = (r is num) ? r.toDouble() : double.parse(r.toString());
      return d.toStringAsFixed(2);
    } catch (_) {
      return r.toString();
    }
  }
}
