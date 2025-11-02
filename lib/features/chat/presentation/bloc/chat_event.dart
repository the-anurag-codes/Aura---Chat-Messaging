import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  final String userId;
  final String otherUserId;

  const ChatStarted({required this.userId, required this.otherUserId});

  @override
  List<Object?> get props => [userId, otherUserId];
}

class ChatMessageSent extends ChatEvent {
  final String content;
  final String senderId;
  final String senderName;
  final String receiverId;

  const ChatMessageSent({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
  });

  @override
  List<Object?> get props => [content, senderId, senderName, receiverId];
}

class ChatMessagesUpdated extends ChatEvent {
  final List<dynamic> messages;

  const ChatMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatTypingStarted extends ChatEvent {
  final String userId;
  final String otherUserId;

  const ChatTypingStarted({required this.userId, required this.otherUserId});

  @override
  List<Object?> get props => [userId, otherUserId];
}

class ChatTypingStopped extends ChatEvent {
  final String userId;
  final String otherUserId;

  const ChatTypingStopped({required this.userId, required this.otherUserId});

  @override
  List<Object?> get props => [userId, otherUserId];
}

class ChatTypingIndicatorReceived extends ChatEvent {
  final bool isTyping;

  const ChatTypingIndicatorReceived(this.isTyping);

  @override
  List<Object?> get props => [isTyping];
}
