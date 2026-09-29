import '../../models/messaging.dart';

/// Conversations and chat messages.
///
/// Implemented against `/api/v1/conversations/*`.
abstract class MessagingRepository {
  Future<List<Conversation>> conversations();

  Future<List<Message>> messages(String conversationId);

  Future<Message> send(String conversationId, String text);

  Future<void> markRead(String conversationId);

  Future<Conversation> startConversation({
    required String participantId,
    required String participantName,
    String jobContext,
    String jobId,
  });

  /// Removes a thread from the list without deleting its messages.
  Future<void> archiveConversation(String conversationId, {bool archived});

  Future<int> unreadMessageCount();
}
