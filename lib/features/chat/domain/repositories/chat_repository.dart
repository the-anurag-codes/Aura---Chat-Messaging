import 'package:dartz/dartz.dart';
import '../entities/message_entity.dart';
import '../entities/chat_room_entity.dart';
import '../../../../core/errors/failure.dart';

abstract class ChatRepository {
  /// Get all chat rooms for a user
  Stream<Either<Failure, List<ChatRoomEntity>>> getChatRoomsStream(
    String userId,
  );

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
}
