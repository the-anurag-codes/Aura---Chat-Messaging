import 'dart:async';
import 'package:talksy/features/users/presentation/bloc/user_event.dart';
import 'package:talksy/features/users/presentation/bloc/user_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_all_users_usecase.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final GetAllUsersUseCase getAllUsersUseCase;
  StreamSubscription? _usersSubscription;

  UsersBloc({required this.getAllUsersUseCase}) : super(const UsersState()) {
    on<UsersLoadStarted>(_onUsersLoadStarted);
    on<UsersUpdated>(_onUsersUpdated);
  }

  Future<void> _onUsersLoadStarted(
    UsersLoadStarted event,
    Emitter<UsersState> emit,
  ) async {
    emit(state.copyWith(status: UsersStatus.loading));

    _usersSubscription = getAllUsersUseCase(event.currentUserId).listen((
      result,
    ) {
      result.fold(
        (failure) {
          add(const UsersUpdated([]));
        },
        (users) {
          add(UsersUpdated(users));
        },
      );
    });
  }

  void _onUsersUpdated(UsersUpdated event, Emitter<UsersState> emit) {
    emit(state.copyWith(status: UsersStatus.loaded, users: event.users.cast()));
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
  }
}
