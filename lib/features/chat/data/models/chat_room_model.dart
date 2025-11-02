import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_room_entity.dart';

class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.id,
    required super.otherUserId,
    required super.otherUserName,
    super.otherUserPhoto,
    super.lastMessage,
    super.lastMessageTime,
    super.unreadCount,
  });

  factory ChatRoomModel.fromFirestore({
    required DocumentSnapshot doc,
    required String currentUserId,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final participants = List<String>.from(data['participants'] ?? []);

    // Get the other user's ID
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    return ChatRoomModel(
      id: doc.id,
      otherUserId: otherUserId,
      otherUserName: data['otherUserName_$otherUserId'] ?? 'Unknown User',
      otherUserPhoto: data['otherUserPhoto_$otherUserId'],
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: data['unreadCount_$currentUserId'] ?? 0,
    );
  }
}
