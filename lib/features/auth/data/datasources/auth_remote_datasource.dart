import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../../../../../core/errors/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl(this.firebaseAuth);

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const ServerException('Failed to sign in');
      }

      return UserModel.fromFirebaseUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Authentication failed');
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const ServerException('Failed to create account');
      }

      // Update display name
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
      final updatedUser = firebaseAuth.currentUser;

      if (updatedUser == null) {
        throw const ServerException('Failed to get updated user');
      }

      return UserModel.fromFirebaseUser(updatedUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Failed to create account');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel.fromFirebaseUser(user);
    });
  }
}
