import 'package:dartz/dartz.dart';
import '../entities/chat_room_entity.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/errors/failure.dart';

class GetChatRoomsUseCase {
  final ChatRepository repository;

  GetChatRoomsUseCase(this.repository);

  Stream<Either<Failure, List<ChatRoomEntity>>> call(String userId) {
    return repository.getChatRoomsStream(userId);
  }
}
