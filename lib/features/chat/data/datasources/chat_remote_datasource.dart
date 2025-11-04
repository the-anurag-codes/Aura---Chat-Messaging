import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/chat_model.dart';
import '../models/chat_room_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId);

  Future<void> sendMessage(MessageModel message);

  Stream<List<MessageModel>> getMessagesStream({
    required String userId,
    required String otherUserId,
  });

  Future<void> sendTypingIndicator({
    required String userId,
    required String otherUserId,
    required bool isTyping,
  });

  Stream<bool> getTypingStream({
    required String userId,
    required String otherUserId,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;

  ChatRemoteDataSourceImpl(this.firestore);

  @override
  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId) {
    try {
      return firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => ChatRoomModel.fromFirestore(
                    doc: doc,
                    currentUserId: userId,
                  ),
                )
                .toList();
          });
    } catch (e) {
      throw ServerException('Failed to get chat rooms: ${e.toString()}');
    }
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    try {
      final chatId = MessageModel.getChatId(
        message.senderId,
        message.receiverId,
      );

      // Get receiver's info from users collection
      final receiverDoc = await firestore
          .collection('users')
          .doc(message.receiverId)
          .get();

      // FIX: Properly extract receiver's name
      final receiverName = receiverDoc.exists
          ? (receiverDoc.data()?['displayName'] ?? 'Unknown')
          : 'Unknown';

      // Batch write for atomicity
      final batch = firestore.batch();

      // Add message
      final messageRef = firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id);

      batch.set(messageRef, message.toFirestore());

      // Update chat metadata with CORRECT user names
      final chatRef = firestore.collection('chats').doc(chatId);
      batch.set(chatRef, {
        'participants': [message.senderId, message.receiverId],
        'lastMessage': message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'userName_${message.senderId}': message.senderName,
        'userName_${message.receiverId}': receiverName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Failed to send message: $e');
      throw ServerException('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> ensureChatExists({
    required String userId,
    required String otherUserId,
    String? userName,
    String? otherUserName,
  }) async {
    try {
      final chatId = MessageModel.getChatId(userId, otherUserId);
      final chatRef = firestore.collection('chats').doc(chatId);

      // Check if chat exists
      final chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        // Get user names from users collection
        final userDoc = await firestore.collection('users').doc(userId).get();
        final otherUserDoc = await firestore
            .collection('users')
            .doc(otherUserId)
            .get();

        final fetchedUserName = userDoc.exists
            ? (userDoc.data()?['displayName'] ?? 'Unknown')
            : (userName ?? 'Unknown');

        final fetchedOtherUserName = otherUserDoc.exists
            ? (otherUserDoc.data()?['displayName'] ?? 'Unknown')
            : (otherUserName ?? 'Unknown');

        // Create the chat document with proper structure
        await chatRef.set({
          'participants': [userId, otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'updatedAt': FieldValue.serverTimestamp(),
          'userName_$userId': fetchedUserName,
          'userName_$otherUserId': fetchedOtherUserName,
        });
      }
    } catch (e) {
      debugPrint('Failed to ensure chat exists: $e');
      throw ServerException('Failed to ensure chat exists: ${e.toString()}');
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream({
    required String userId,
    required String otherUserId,
  }) {
    try {
      final chatId = MessageModel.getChatId(userId, otherUserId);

      // Ensure chat exists before setting up stream
      ensureChatExists(userId: userId, otherUserId: otherUserId);

      return firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => MessageModel.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      throw ServerException('Failed to get messages: ${e.toString()}');
    }
  }

  @override
  Future<void> sendTypingIndicator({
    required String userId,
    required String otherUserId,
    required bool isTyping,
  }) async {
    try {
      final chatId = MessageModel.getChatId(userId, otherUserId);

      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .set({
            'isTyping': isTyping,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Auto-delete after 3 seconds if still typing
      if (isTyping) {
        Future.delayed(const Duration(seconds: 3), () {
          firestore
              .collection('chats')
              .doc(chatId)
              .collection('typing')
              .doc(userId)
              .delete();
        });
      }
    } catch (e) {
      debugPrint('Failed to send typing indicator: $e');
    }
  }

  @override
  Stream<bool> getTypingStream({
    required String userId,
    required String otherUserId,
  }) {
    try {
      final chatId = MessageModel.getChatId(userId, otherUserId);

      return firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(otherUserId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) return false;

            final data = snapshot.data();
            if (data == null) return false;

            return data['isTyping'] as bool? ?? false;
          });
    } catch (e) {
      return Stream.value(false);
    }
  }
}
