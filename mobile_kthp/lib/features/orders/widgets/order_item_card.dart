import 'package:flutter/material.dart';

class OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String status;
  final VoidCallback? onCancel;
  final VoidCallback? onBuyAgain;
  final VoidCallback? onViewDetail;

  const OrderItemCard({
    super.key,
    required this.order,
    required this.status,
    this.onCancel,
    this.onBuyAgain,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final products = (order['products'] as List<dynamic>);
    final total = order['total'] ?? 0;

    String statusText = '';
    Color statusColor = Colors.orange;

    if (status == 'pending') {
      statusText = 'Chờ xác nhận';
    } else if (status == 'processing') {
      statusText = 'Chờ lấy hàng';
      statusColor = Colors.teal;
    } else if (status == 'shipping') {
      statusText = 'Chờ giao hàng';
      statusColor = Colors.blue;
    } else if (status == 'delivered') {
      statusText = 'Hoàn thành';
      statusColor = const Color(0xFF00B14F);
    } else if (status == 'cancelled') {
      statusText = 'Đã hủy';
      statusColor = Colors.grey;
    } else if (status == 'returned') {
      statusText = 'Trả hàng/Hoàn tiền';
      statusColor = Colors.red;
    }

    return GestureDetector(
      onTap: onViewDetail,
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Shop Name & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'Yêu thích',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Shop Official',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.black12),

            // First Product + "..more" if needed
            _buildProductItem(products.first),
            if (products.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Xem thêm ${products.length - 1} sản phẩm...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            const Divider(height: 24, color: Colors.black12),

            // Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} sản phẩm',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Row(
                  children: [
                    const Text(
                      'Thành tiền: ',
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                    Text(
                      '${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫',
                      style: const TextStyle(
                        color: Color(0xFFEE4D2D), // Shopee Orange for Price
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'delivered') ...[
                  OutlinedButton(
                    onPressed: () {}, // Dummy Rate
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      side: const BorderSide(color: Colors.black12),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Đánh giá'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onBuyAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEE4D2D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Mua lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ] else if (status == 'pending') ...[
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hủy đơn hàng này?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Không'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                if (onCancel != null) onCancel!();
                              },
                              child: const Text(
                                'Đồng ý',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black12),
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('Hủy đơn hàng'),
                  ),
                ] else if (status == 'cancelled') ...[
                  ElevatedButton(
                    onPressed: onBuyAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEE4D2D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Mua lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ] else
                  // Default View Detail
                  OutlinedButton(
                    onPressed: onViewDetail,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black12),
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> p) {
    final title = p['title'] ?? 'Software';
    final price = p['price'] ?? 0;
    final quantity = p['quantity'] ?? 1;
    final thumb = p['thumbnail'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Image.network(
            thumb.toString(),
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 70,
              height: 70,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'Phân loại: Mặc định',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'x$quantity',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  // If discounted price logic existed, put it here. For now raw price.
                  Text(
                    '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      decoration:
                          TextDecoration.lineThrough, // Fake original price
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
