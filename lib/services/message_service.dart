import '../models/message.dart';
import '../models/user.dart';
import 'insforge_client.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  static MessageService get instance => _instance;

  final InsforgeClient _client = InsforgeClient.instance;

  // In-memory storage for read message IDs
  final Set<String> _readMessageIds = <String>{};

  // Get messages for a match
  Future<List<Message>> getMessagesForMatch(String matchId) async {
    try {
      final messagesData = await _client.select(
        table: 'messages',
        filters: {'match_id': matchId},
        orderBy: 'created_at.asc',
      );

      return messagesData.map((data) => Message.fromJson(data)).toList();
    } catch (e) {
      print('Error getting messages for match: $e');
      return [];
    }
  }

  // Send a text message
  Future<Message?> sendMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      // Validate inputs
      if (matchId.isEmpty) {
        print('Error: matchId is empty');
        return null;
      }
      if (senderId.isEmpty) {
        print('Error: senderId is empty');
        return null;
      }
      if (receiverId.isEmpty) {
        print('Error: receiverId is empty');
        return null;
      }
      if (content.isEmpty) {
        print('Error: content is empty');
        return null;
      }

      final messageData = {
        'match_id': matchId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _client.insert(
        table: 'messages',
        data: messageData,
      );

      return Message.fromJson(result);
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Send a message with image
  Future<Message?> sendImageMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String imageUrl,
    String? imageKey,
    String? caption,
  }) async {
    try {
      // Validate inputs
      if (matchId.isEmpty) {
        print('Error: matchId is empty');
        return null;
      }
      if (senderId.isEmpty) {
        print('Error: senderId is empty');
        return null;
      }
      if (receiverId.isEmpty) {
        print('Error: receiverId is empty');
        return null;
      }
      if (imageUrl.isEmpty) {
        print('Error: imageUrl is empty');
        return null;
      }

      final messageData = {
        'match_id': matchId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': caption ?? '',
        'image_url': imageUrl,
        'image_key': imageKey,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _client.insert(
        table: 'messages',
        data: messageData,
      );

      return Message.fromJson(result);
    } catch (e) {
      print('Error sending image message: $e');
      return null;
    }
  }

  // Get messages for a user (all matches)
  Future<List<Message>> getUserMessages(String userId) async {
    try {
      final messagesData = await _client.select(
        table: 'messages',
        filters: {
          'sender_id': userId,
        },
        orderBy: 'created_at.desc',
      );

      final messages2Data = await _client.select(
        table: 'messages',
        filters: {
          'receiver_id': userId,
        },
        orderBy: 'created_at.desc',
      );

      final allMessages = [...messagesData, ...messages2Data];
      return allMessages.map((data) => Message.fromJson(data)).toList();
    } catch (e) {
      print('Error getting user messages: $e');
      return [];
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _client.delete(
        table: 'messages',
        filters: {'id': messageId},
      );
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final messagesData = await _client.select(
        table: 'messages',
        filters: {
          'receiver_id': userId,
        },
      );

      // Count messages that are not marked as read
      int unreadCount = 0;
      for (final messageData in messagesData) {
        final messageId = messageData['id'] as String;
        if (!_readMessageIds.contains(messageId)) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(String matchId, String userId) async {
    try {
      // Get all messages for this match
      final messages = await getMessagesForMatch(matchId);

      // Mark messages from other user as read
      for (final message in messages) {
        if (message.senderId != userId) {
          _readMessageIds.add(message.id);
        }
      }

      return true;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  // Check if a message is read
  bool isMessageRead(String messageId) {
    return _readMessageIds.contains(messageId);
  }
}
