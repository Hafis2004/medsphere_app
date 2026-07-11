import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/firebase_service.dart';

abstract class DoctorAvailabilityRepository {
  Stream<bool> watchAvailability();
  Future<void> setAvailability(bool isAvailable);
}

class DoctorAvailabilityRepositoryImpl implements DoctorAvailabilityRepository {
  DoctorAvailabilityRepositoryImpl({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _collection = 'doctorAvailability';
  static const _documentId = 'primary';

  @override
  Stream<bool> watchAvailability() {
    return _firestore.collection(_collection).doc(_documentId).snapshots().map(
          (snapshot) => snapshot.data()?['isAvailable'] as bool? ?? true,
        );
  }

  @override
  Future<void> setAvailability(bool isAvailable) {
    return _firestore.collection(_collection).doc(_documentId).set(
          {'isAvailable': isAvailable},
          SetOptions(merge: true),
        );
  }
}

class MockDoctorAvailabilityRepository implements DoctorAvailabilityRepository {
  MockDoctorAvailabilityRepository._();

  static final instance = MockDoctorAvailabilityRepository._();
  final _controller = StreamController<bool>.broadcast();
  bool _isAvailable = true;

  @override
  Stream<bool> watchAvailability() async* {
    yield _isAvailable;
    yield* _controller.stream;
  }

  @override
  Future<void> setAvailability(bool isAvailable) async {
    _isAvailable = isAvailable;
    _controller.add(_isAvailable);
  }
}

final doctorAvailabilityRepositoryProvider = Provider<DoctorAvailabilityRepository>((ref) {
  return FirebaseService.instance.isInitialized
      ? DoctorAvailabilityRepositoryImpl()
      : MockDoctorAvailabilityRepository.instance;
});

final doctorAvailabilityProvider = StreamProvider<bool>((ref) {
  return ref.watch(doctorAvailabilityRepositoryProvider).watchAvailability();
});
