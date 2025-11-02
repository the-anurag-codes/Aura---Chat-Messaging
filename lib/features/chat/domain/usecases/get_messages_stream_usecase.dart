import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessagesStreamUseCase {
  final ChatRepository repository;

  GetMessagesStreamUseCase(this.repository);

  Stream<Either<Failure, List<MessageEntity>>> call({
    required String userId,
    required String otherUserId,
  }) {
    return repository.getMessagesStream(
      userId: userId,
      otherUserId: otherUserId,
    );
  }
}
