import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/chat_repository.dart';

class SendTypingIndicatorUseCase {
  final ChatRepository repository;

  SendTypingIndicatorUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String otherUserId,
    required bool isTyping,
  }) {
    return repository.sendTypingIndicator(
      userId: userId,
      otherUserId: otherUserId,
      isTyping: isTyping,
    );
  }
}
