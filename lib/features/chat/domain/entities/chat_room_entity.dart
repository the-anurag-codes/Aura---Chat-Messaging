import 'package:equatable/equatable.dart';

class ChatRoomEntity extends Equatable {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  const ChatRoomEntity({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    otherUserId,
    otherUserName,
    otherUserPhoto,
    lastMessage,
    lastMessageTime,
    unreadCount,
  ];
}
