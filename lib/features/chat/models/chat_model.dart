class MessageModel {
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final String? imageUrl; // For simulated photo sharing

  MessageModel({
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.imageUrl,
  });
}

class ChatSession {
  final String id;
  String riderName;
  String brandName;
  String avatarPath;
  String status; // 'Mengantar', 'Diseduh', 'Selesai'
  String lastMessageTime;
  final List<MessageModel> messages;
  int unreadCount;
  final String riderId;

  ChatSession({
    required this.id,
    required this.riderName,
    required this.brandName,
    required this.avatarPath,
    required this.status,
    required this.lastMessageTime,
    required this.messages,
    this.unreadCount = 0,
    required this.riderId,
  });
}
