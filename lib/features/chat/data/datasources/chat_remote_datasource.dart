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

      // First, ensure chat document exists
      final chatDoc = await firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Create chat document first
        await firestore.collection('chats').doc(chatId).set({
          'participants': [message.senderId, message.receiverId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }

      // Add message with batch write for atomicity
      final batch = firestore.batch();

      // Add message
      final messageRef = firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id);

      batch.set(messageRef, message.toFirestore());

      // Update chat metadata
      final chatRef = firestore.collection('chats').doc(chatId);
      batch.set(chatRef, {
        'participants': [message.senderId, message.receiverId],
        'lastMessage': message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'otherUserName_${message.receiverId}': message.senderName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Commit batch
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to send message: ${e.toString()}');
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream({
    required String userId,
    required String otherUserId,
  }) {
    try {
      final chatId = MessageModel.getChatId(userId, otherUserId);

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
