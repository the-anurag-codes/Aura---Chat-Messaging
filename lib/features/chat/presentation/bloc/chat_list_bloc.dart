import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_chat_room_usecase.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChatRoomsUseCase getChatRoomsUseCase;
  StreamSubscription? _chatRoomsSubscription;

  ChatListBloc({required this.getChatRoomsUseCase})
    : super(const ChatListState()) {
    on<ChatListStarted>(_onChatListStarted);
    on<ChatListUpdated>(_onChatListUpdated);
  }

  Future<void> _onChatListStarted(
    ChatListStarted event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading));

    _chatRoomsSubscription = getChatRoomsUseCase(event.userId).listen((result) {
      result.fold(
        (failure) {
          add(const ChatListUpdated([]));
        },
        (chatRooms) {
          add(ChatListUpdated(chatRooms));
        },
      );
    });
  }

  void _onChatListUpdated(ChatListUpdated event, Emitter<ChatListState> emit) {
    emit(
      state.copyWith(
        status: ChatListStatus.loaded,
        chatRooms: event.chatRooms.cast(),
      ),
    );
  }

  @override
  Future<void> close() {
    _chatRoomsSubscription?.cancel();
    return super.close();
  }
}
