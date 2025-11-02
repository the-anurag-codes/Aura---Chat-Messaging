import 'package:dartz/dartz.dart';
import '../entities/message_entity.dart';
import '../../../../core/errors/failure.dart';

abstract class ChatRepository {
  /// Send a message to Firestore
  Future<Either<Failure, void>> sendMessage(MessageEntity message);

  /// Get messages stream between two users
  Stream<Either<Failure, List<MessageEntity>>> getMessagesStream({
    required String userId,
    required String otherUserId,
  });

  /// Send typing indicator
  Future<Either<Failure, void>> sendTypingIndicator({
    required String userId,
    required String otherUserId,
    required bool isTyping,
  });

  /// Get typing indicator stream
  Stream<bool> getTypingStream({
    required String userId,
    required String otherUserId,
  });

  /// Mark message as read
  Future<Either<Failure, void>> markMessageAsRead({required String messageId});
}
