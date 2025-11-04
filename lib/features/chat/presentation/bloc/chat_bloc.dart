import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    try {
      // IMPORTANT: Ensure chat document exists before setting up listeners
      await _ensureChatExists(
        userId: event.userId,
        otherUserId: event.otherUserId,
        userName: event.userName,
        otherUserName: event.otherUserName,
      );

      // Small delay to ensure Firestore has processed the document creation
      await Future.delayed(const Duration(milliseconds: 100));

      // Listen to messages
      _messagesSubscription?.cancel(); // Cancel any existing subscription
      _messagesSubscription =
          getMessagesStreamUseCase(
            userId: event.userId,
            otherUserId: event.otherUserId,
          ).listen(
            (result) {
              result.fold(
                (failure) {
                  debugPrint('Failed to get messages: ${failure.message}');
                  add(const ChatMessagesUpdated([]));
                },
                (messages) {
                  add(ChatMessagesUpdated(messages));
                },
              );
            },
            onError: (error) {
              debugPrint('Message stream error: $error');
              add(const ChatMessagesUpdated([]));
            },
          );

      // Listen to typing indicators
      _typingSubscription?.cancel(); // Cancel any existing subscription
      _typingSubscription =
          getTypingStreamUseCase(
            userId: event.userId,
            otherUserId: event.otherUserId,
          ).listen(
            (isTyping) {
              add(ChatTypingIndicatorReceived(isTyping));
            },
            onError: (error) {
              debugPrint('Typing stream error: $error');
            },
          );

      emit(state.copyWith(status: ChatStatus.loaded));
    } catch (e) {
      debugPrint('Error starting chat: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Failed to initialize chat: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _ensureChatExists({
    required String userId,
    required String otherUserId,
    String? userName,
    String? otherUserName,
  }) async {
    try {
      final chatId = _getChatId(userId, otherUserId);
      final chatRef = _firestore.collection('chats').doc(chatId);

      // Use a transaction to ensure atomic operation
      await _firestore.runTransaction((transaction) async {
        final chatDoc = await transaction.get(chatRef);

        if (!chatDoc.exists) {
          // Create the chat document with proper structure
          transaction.set(chatRef, {
            'participants': [userId, otherUserId],
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessageTime': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            if (userName != null) 'userName_$userId': userName,
            if (otherUserName != null) 'userName_$otherUserId': otherUserName,
            'otherUserName_$userId': otherUserName ?? '',
            'otherUserName_$otherUserId': userName ?? '',
          });

          debugPrint('Created new chat document: $chatId');
        } else {
          // Update user names if provided
          Map<String, dynamic> updates = {
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (userName != null) {
            updates['userName_$userId'] = userName;
            updates['otherUserName_$otherUserId'] = userName;
          }

          if (otherUserName != null) {
            updates['userName_$otherUserId'] = otherUserName;
            updates['otherUserName_$userId'] = otherUserName;
          }

          transaction.update(chatRef, updates);
          debugPrint('Updated existing chat document: $chatId');
        }
      });
    } catch (e) {
      debugPrint('Error ensuring chat exists: $e');
      rethrow;
    }
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
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
        debugPrint('Failed to send message: ${failure.message}');
      },
      (_) {
        // Message sent successfully
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
