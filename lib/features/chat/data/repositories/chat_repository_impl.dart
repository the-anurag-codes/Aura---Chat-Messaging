import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/chat_room_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_model.dart';
import '../../../../core/errors/exceptions.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Stream<Either<Failure, List<ChatRoomEntity>>> getChatRoomsStream(
    String userId,
  ) {
    try {
      return remoteDataSource
          .getChatRoomsStream(userId)
          .map((rooms) => Right<Failure, List<ChatRoomEntity>>(rooms))
          .handleError((error) {
            return Left<Failure, List<ChatRoomEntity>>(
              ServerFailure(error.toString()),
            );
          });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage(MessageEntity message) async {
    try {
      final messageModel = MessageModel(
        id: message.id,
        senderId: message.senderId,
        senderName: message.senderName,
        receiverId: message.receiverId,
        content: message.content,
        timestamp: message.timestamp,
        status: message.status,
      );

      await remoteDataSource.sendMessage(messageModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<MessageEntity>>> getMessagesStream({
    required String userId,
    required String otherUserId,
  }) {
    try {
      return remoteDataSource
          .getMessagesStream(userId: userId, otherUserId: otherUserId)
          .map((messages) => Right<Failure, List<MessageEntity>>(messages))
          .handleError((error) {
            return Left<Failure, List<MessageEntity>>(
              ServerFailure(error.toString()),
            );
          });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> sendTypingIndicator({
    required String userId,
    required String otherUserId,
    required bool isTyping,
  }) async {
    try {
      await remoteDataSource.sendTypingIndicator(
        userId: userId,
        otherUserId: otherUserId,
        isTyping: isTyping,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<bool> getTypingStream({
    required String userId,
    required String otherUserId,
  }) {
    return remoteDataSource.getTypingStream(
      userId: userId,
      otherUserId: otherUserId,
    );
  }
}
