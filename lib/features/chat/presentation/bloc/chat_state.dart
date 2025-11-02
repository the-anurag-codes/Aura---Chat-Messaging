import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<MessageEntity> messages;
  final bool isOtherUserTyping;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.isOtherUserTyping = false,
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<MessageEntity>? messages,
    bool? isOtherUserTyping,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    isOtherUserTyping,
    errorMessage,
  ];
}
