import '../repositories/chat_repository.dart';

class GetTypingStreamUseCase {
  final ChatRepository repository;

  GetTypingStreamUseCase(this.repository);

  Stream<bool> call({required String userId, required String otherUserId}) {
    return repository.getTypingStream(userId: userId, otherUserId: otherUserId);
  }
}
