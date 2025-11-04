import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';

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

      final user = credential.user!;

      // Check if user document exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Create missing user document (for existing auth users)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': user.displayName ?? email.split('@')[0],
          'email': email,
          'photoUrl': user.photoURL,
          'isOnline': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        debugPrint('Created missing user document for ${user.uid}');
      } else {
        // Update online status for existing document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'isOnline': true,
              'lastSeen': FieldValue.serverTimestamp(),
            });
        debugPrint('Updated online status for ${user.uid}');
      }

      return UserModel.fromFirebaseUser(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Authentication failed');
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Step 1: Create Firebase Auth account
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const ServerException('Failed to create account');
      }

      // Step 2: Update display name in Firebase Auth
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();

      final updatedUser = firebaseAuth.currentUser;
      if (updatedUser == null) {
        throw const ServerException('Failed to get updated user');
      }

      // Step 3: Create user document in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(updatedUser.uid)
            .set({
              'displayName': displayName,
              'email': email,
              'photoUrl': null,
              'isOnline': true,
              'createdAt': FieldValue.serverTimestamp(),
              'lastSeen': FieldValue.serverTimestamp(),
            });
      } catch (firestoreError) {
        debugPrint('Firestore error: $firestoreError');
        // Auth succeeded but Firestore failed
        // Document will be created on next sign in
      }

      return UserModel.fromFirebaseUser(updatedUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.message}');
      throw ServerException(e.message ?? 'Failed to create account');
    } catch (e) {
      debugPrint('Signup error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Update online status before signing out
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'isOnline': false,
              'lastSeen': FieldValue.serverTimestamp(),
            });
      }

      await firebaseAuth.signOut();
      debugPrint('Signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;

      // Ensure user document exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Create missing document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName':
              user.displayName ?? user.email?.split('@')[0] ?? 'User',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'isOnline': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      return UserModel.fromFirebaseUser(user);
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel.fromFirebaseUser(user);
    });
  }
}
