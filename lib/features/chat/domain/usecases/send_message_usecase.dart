import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(MessageEntity message) {
    return repository.sendMessage(message);
  }
}
