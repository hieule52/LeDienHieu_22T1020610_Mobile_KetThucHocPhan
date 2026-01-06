class ChatConversation {
  final String id;
  final String shopName;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.id,
    required this.shopName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = true,
  });
}
