import 'package:flutter/material.dart';
import 'package:mobile_kthp/features/notifications/models/notification_model.dart';
import 'package:mobile_kthp/features/cart/pages/cart_page.dart';
import 'package:provider/provider.dart';
import 'package:mobile_kthp/features/cart/controllers/cart_controller.dart';
import '../../chat/pages/chat_list_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Mock data for categories
  final List<NotificationCategory> _categories = [
    NotificationCategory(
      id: '1',
      title: 'Khuyến mãi',
      subtitle: 'ledienhieu ơi, 1 voucher sẽ hết hạn vào...',
      badgeCount: 5,
      iconAsset: 'assets/icons/promo.png', // Placeholder, using Icon in UI
      color: 0xFFF57224, // Colors.orange[800]
    ),
    NotificationCategory(
      id: '2',
      title: 'Live & Video',
      subtitle: 'Sale Dép đẹp trong live',
      badgeCount: 5,
      iconAsset: 'assets/icons/live.png',
      color: 0xFF26AA99, // Teal
    ),
    NotificationCategory(
      id: '3',
      title: 'Thông tin Tài chính',
      subtitle: '💗 Tặng bạn Voucher MIỄN LÃI - Dành r...',
      badgeCount: 4,
      iconAsset: 'assets/icons/finance.png',
      color: 0xFF00B14F, // Green
    ),
    NotificationCategory(
      id: '4',
      title: 'Cập nhật Shopee',
      subtitle: '👋 ledienhieu.05 ơi! Để theo dõi đơn hà...',
      badgeCount: 8,
      iconAsset: 'assets/icons/update.png',
      color: 0xFF00B14F,
    ),
  ];

  // Mock data for order updates
  final List<NotificationModel> _orders = [
    NotificationModel(
      id: '1',
      title: 'Đơn hàng đã hoàn tất',
      content:
          'Đơn hàng 251215CGHRVV68 đã hoàn thành. Bạn hãy đánh giá sản phẩm trước ngày 19-01-2026 để nhận 200 xu và giúp người dùng khác hiểu hơn về sản phẩm nhé!',
      time: DateTime(2025, 12, 20, 13, 14),
      imageUrl:
          'https://cf.shopee.vn/file/sg-11134201-22120-7e3e3e3e3e3e', // Valid URL or placeholder
    ),
    NotificationModel(
      id: '2',
      title: 'Đơn hàng đã hoàn tất',
      content:
          'Đơn hàng 2512124WDV79HY đã hoàn thành. Bạn hãy đánh giá sản phẩm trước ngày 16-01-2026 để nhận 200 xu và giúp người dùng khác hiểu hơn về sản phẩm nhé!',
      time: DateTime(2025, 12, 17, 16, 7),
    ),
    NotificationModel(
      id: '3',
      title: 'Đơn hàng đã hoàn tất',
      content:
          'Đơn hàng 2512126806J809 đã hoàn thành. Bạn hãy đánh giá sản phẩm trước ngày 16-01-2026 để nhận 200 xu và giúp người dùng khác hiểu hơn về sản phẩm nhé!',
      time: DateTime(2025, 12, 17, 15, 30),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<CartController>(
            builder: (context, cart, _) => _buildIconBadge(
              icon: Icons.shopping_cart_outlined,
              badge: cart.totalQty,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          _buildIconBadge(
            icon: Icons.chat_bubble_outline,
            badge: 0, // Mock badge
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListPage()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        children: [
          // Categories Section
          ..._categories.map((cat) => _CategoryItem(category: cat)),

          const SizedBox(height: 12),

          // Order Updates Section Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cập nhật đơn hàng',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Đọc tất cả (${_orders.length * 2})',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF00B14F),
                  ),
                ),
              ],
            ),
          ),

          // Order Updates List
          ..._orders.map(
            (notif) => _OrderNotificationItem(notification: notif),
          ),

          // Extra spacing at bottom
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIconBadge({
    required IconData icon,
    required int badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: const Color(0xFF00B14F), size: 26),
          ),
          if (badge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B14F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                constraints: const BoxConstraints(minWidth: 16),
                child: Center(
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final NotificationCategory category;

  const _CategoryItem({required this.category});

  IconData _getIconData(String id) {
    // Map ID to Icons since we don't have assets
    switch (id) {
      case '1':
        return Icons.local_offer;
      case '2':
        return Icons.videocam;
      case '3':
        return Icons.account_balance_wallet;
      case '4':
        return Icons.shopping_bag;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconData(category.id),
                      color: Color(category.color),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (category.badgeCount > 0) ...[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00B14F),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${category.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderNotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _OrderNotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 1), // Separator line effect
      color:
          Colors.white, // Light background for unread? Screenshot shows white.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade100,
                  ),
                  child: notification.imageUrl != null
                      ? const Icon(
                          Icons.image,
                          color: Colors.grey,
                        ) // Placeholder if network fails
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${notification.time.hour}:${notification.time.minute.toString().padLeft(2, '0')} ${notification.time.day}-${notification.time.month}-${notification.time.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
