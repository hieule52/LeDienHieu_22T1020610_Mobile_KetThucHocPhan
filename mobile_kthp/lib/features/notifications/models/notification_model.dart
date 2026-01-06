class NotificationModel {
  final String id;
  final String title;
  final String content;
  final DateTime time;
  final String? imageUrl;
  final bool isRead;
  final String type; // 'order', 'promo', 'wallet', 'shopee'

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    this.imageUrl,
    this.isRead = false,
    this.type = 'order',
  });
}

class NotificationCategory {
  final String id;
  final String title;
  final String subtitle;
  final int badgeCount;
  final String iconAsset; // or IconData
  final int color;

  NotificationCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    this.badgeCount = 0,
    required this.iconAsset,
    required this.color,
  });
}
