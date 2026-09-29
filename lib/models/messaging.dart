import 'enums.dart';

/// A chat thread summary shown in the Messages list.
class Conversation {
  const Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.jobContext = '',
    this.unread = 0,
    this.isOnline = false,
    this.lastMessage = '',
    this.lastMessageAt,
  });

  final String id;
  final String participantId;
  final String participantName;
  final String jobContext;
  final int unread;
  final bool isOnline;
  final String lastMessage;
  final DateTime? lastMessageAt;

  Conversation copyWith({
    int? unread,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? isOnline,
  }) {
    return Conversation(
      id: id,
      participantId: participantId,
      participantName: participantName,
      jobContext: jobContext,
      unread: unread ?? this.unread,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

/// A single chat bubble.
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.isRead = true,
  });

  final String id;
  final String conversationId;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final bool isRead;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.targetRoute,
    this.targetId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? targetRoute;
  final String? targetId;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      targetRoute: targetRoute,
      targetId: targetId,
    );
  }
}
