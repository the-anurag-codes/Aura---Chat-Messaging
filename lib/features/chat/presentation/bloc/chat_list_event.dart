import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

class ChatListStarted extends ChatListEvent {
  final String userId;

  const ChatListStarted(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ChatListUpdated extends ChatListEvent {
  final List<dynamic> chatRooms;

  const ChatListUpdated(this.chatRooms);

  @override
  List<Object?> get props => [chatRooms];
}
