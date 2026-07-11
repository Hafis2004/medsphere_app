import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/services/firebase_service.dart';
import '../core/utils/exceptions.dart';

import 'appointment_repository.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password});
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required int age,
    required String phone,
    required String symptoms,
  });
  Future<void> signOut();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService.instance;

  final FirebaseService _firebaseService;

  @override
  Stream<User?> authStateChanges() => _firebaseService.isInitialized ? _firebaseService.authStateChanges() : Stream.value(null);

  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    if (!_firebaseService.isInitialized) {
      throw const AuthException('Firebase is not configured. Add firebase_options.dart or configure Firebase for web.');
    }
    try {
      return await _firebaseService.auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (e) {
      throw const AuthException('Unable to sign in right now.');
    }
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required int age,
    required String phone,
    required String symptoms,
  }) async {
    if (!_firebaseService.isInitialized) {
      throw const AuthException('Firebase is not configured. Add firebase_options.dart or configure Firebase for web.');
    }
    try {
      final credential = await _firebaseService.auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await credential.user?.updateDisplayName(name.trim());

      // Store patient profile in Firestore
      await _firebaseService.firestore!.collection('patients').doc(credential.user!.uid).set({
        'name': name.trim(),
        'age': age,
        'phone': phone.trim(),
        'email': email.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Create initial appointment request in Firestore
      await _firebaseService.firestore!.collection('appointments').add({
        'patient': {
          'id': credential.user!.uid,
          'name': name.trim(),
          'age': age,
          'phone': phone.trim(),
        },
        'appointmentTime': DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
        'status': 'Unconfirmed',
        'notes': symptoms.trim(),
      });

      // Sign out immediately to prevent auto-login redirection
      await _firebaseService.auth!.signOut();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (e) {
      throw const AuthException('Unable to register at this time.');
    }
  }

  @override
  Future<void> signOut() async {
    if (!_firebaseService.isInitialized) return;
    await _firebaseService.auth!.signOut();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

class MockUser implements User {
  @override
  final String uid;

  @override
  final String email;

  @override
  final String displayName;

  MockUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements UserCredential {
  @override
  final User? user;

  MockUserCredential({this.user});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockRegistration {
  final String name;
  final String email;
  final String password;
  final int age;
  final String phone;

  _MockRegistration({
    required this.name,
    required this.email,
    required this.password,
    required this.age,
    required this.phone,
  });
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository._() {
    _registrations['patient@medsphere.app'] = _MockRegistration(
      name: 'Hafis',
      email: 'patient@medsphere.app',
      password: 'patient123',
      age: 28,
      phone: '0477 468246',
    );
    MockAppointmentRepository.instance.createMockAppointment(
      patientId: 'mock-patient-patient@medsphere.app',
      name: 'Hafis',
      age: 28,
      phone: '0477 468246',
      symptoms: 'fever',
    );
  }
  static final MockAuthRepository instance = MockAuthRepository._();

  final _controller = StreamController<User?>.broadcast();
  User? _currentUser;

  final Map<String, _MockRegistration> _registrations = {};

  @override
  Stream<User?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final trimmedEmail = email.trim();

    if (trimmedEmail == AppConstants.doctorEmail && password == 'doctor123') {
      _currentUser = MockUser(
        uid: 'demo-doctor-uid',
        email: AppConstants.doctorEmail,
        displayName: AppConstants.doctorDisplayName,
      );
      _controller.add(_currentUser);
      return MockUserCredential(user: _currentUser);
    } else if (_registrations.containsKey(trimmedEmail) && _registrations[trimmedEmail]!.password == password) {
      final reg = _registrations[trimmedEmail]!;
      _currentUser = MockUser(
        uid: 'mock-patient-${reg.email}',
        email: reg.email,
        displayName: reg.name,
      );
      _controller.add(_currentUser);
      return MockUserCredential(user: _currentUser);
    } else {
      throw const AuthException('The email or password you entered is incorrect.');
    }
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required int age,
    required String phone,
    required String symptoms,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final trimmedEmail = email.trim();

    if (trimmedEmail == AppConstants.doctorEmail || _registrations.containsKey(trimmedEmail)) {
      throw const AuthException('The email address is already in use by another account.');
    }

    final reg = _MockRegistration(
      name: name.trim(),
      email: trimmedEmail,
      password: password,
      age: age,
      phone: phone.trim(),
    );
    _registrations[trimmedEmail] = reg;

    final mockUser = MockUser(
      uid: 'mock-patient-${reg.email}',
      email: reg.email,
      displayName: reg.name,
    );

    // Call MockAppointmentRepository to schedule the appointment request
    MockAppointmentRepository.instance.createMockAppointment(
      patientId: mockUser.uid,
      name: reg.name,
      age: reg.age,
      phone: reg.phone,
      symptoms: symptoms,
    );

    // We do not automatically sign in the registered user here to allow redirecting to login page.
    return MockUserCredential(user: mockUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
