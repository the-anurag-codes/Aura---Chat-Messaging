import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_messages_stream_usecase.dart';
import '../../domain/usecases/send_typing_indicator_usecase.dart';
import '../../domain/usecases/get_typing_stream_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetMessagesStreamUseCase getMessagesStreamUseCase;
  final SendTypingIndicatorUseCase sendTypingIndicatorUseCase;
  final GetTypingStreamUseCase getTypingStreamUseCase;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  final Uuid _uuid = const Uuid();

  ChatBloc({
    required this.sendMessageUseCase,
    required this.getMessagesStreamUseCase,
    required this.sendTypingIndicatorUseCase,
    required this.getTypingStreamUseCase,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
    on<ChatTypingStarted>(_onTypingStarted);
    on<ChatTypingStopped>(_onTypingStopped);
    on<ChatTypingIndicatorReceived>(_onTypingIndicatorReceived);
  }

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));

    // Listen to messages
    _messagesSubscription =
        getMessagesStreamUseCase(
          userId: event.userId,
          otherUserId: event.otherUserId,
        ).listen((result) {
          result.fold(
            (failure) {
              add(ChatMessagesUpdated(const []));
            },
            (messages) {
              add(ChatMessagesUpdated(messages));
            },
          );
        });

    // Listen to typing indicators
    _typingSubscription =
        getTypingStreamUseCase(
          userId: event.userId,
          otherUserId: event.otherUserId,
        ).listen((isTyping) {
          add(ChatTypingIndicatorReceived(isTyping));
        });

    emit(state.copyWith(status: ChatStatus.loaded));
  }

  void _onMessagesUpdated(ChatMessagesUpdated event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        messages: event.messages.cast<MessageEntity>(),
        status: ChatStatus.loaded,
      ),
    );
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final message = MessageEntity(
      id: _uuid.v4(),
      senderId: event.senderId,
      senderName: event.senderName,
      receiverId: event.receiverId,
      content: event.content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    final result = await sendMessageUseCase(message);

    result.fold(
      (failure) {
        // Handle error - could show a snackbar
        print('Failed to send message: ${failure.message}');
      },
      (_) {
        // Message sent successfully
        // Firestore stream will automatically update the UI
      },
    );
  }

  Future<void> _onTypingStarted(
    ChatTypingStarted event,
    Emitter<ChatState> emit,
  ) async {
    await sendTypingIndicatorUseCase(
      userId: event.userId,
      otherUserId: event.otherUserId,
      isTyping: true,
    );
  }

  Future<void> _onTypingStopped(
    ChatTypingStopped event,
    Emitter<ChatState> emit,
  ) async {
    await sendTypingIndicatorUseCase(
      userId: event.userId,
      otherUserId: event.otherUserId,
      isTyping: false,
    );
  }

  void _onTypingIndicatorReceived(
    ChatTypingIndicatorReceived event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(isOtherUserTyping: event.isTyping));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    return super.close();
  }
}
