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

    // Get the OTHER user's ID (not current user)
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    // Get the OTHER user's name using their ID
    final otherUserName = data['userName_$otherUserId'] ?? 'Unknown User';
    // print('other $currentUserId $otherUserId $participants $otherUserName');

    return ChatRoomModel(
      id: doc.id,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserPhoto: null,
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: data['unreadCount_$currentUserId'] ?? 0,
    );
  }
}
