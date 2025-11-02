import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failure.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return repository.signUpWithEmailPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
