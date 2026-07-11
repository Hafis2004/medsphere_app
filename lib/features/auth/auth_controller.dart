import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/firebase_service.dart';
import '../../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseService.instance.isInitialized ? AuthRepositoryImpl() : MockAuthRepository.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final registrationInProgressProvider = StateProvider<bool>((ref) => false);

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._authRepository, this._ref) : super(const AsyncValue.data(null));

  final AuthRepository _authRepository;
  final Ref _ref;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String phone,
    required String symptoms,
  }) async {
    state = const AsyncValue.loading();
    _ref.read(registrationInProgressProvider.notifier).state = true;
    try {
      await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        age: age,
        phone: phone,
        symptoms: symptoms,
      );
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    } finally {
      _ref.read(registrationInProgressProvider.notifier).state = false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
