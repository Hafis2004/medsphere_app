import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/exceptions.dart';
import '../models/appointment.dart';
import '../models/patient.dart';

abstract class AppointmentRepository {
  Stream<List<Appointment>> watchAppointments();
  Future<void> updateAppointmentStatus({required String appointmentId, required String status});
}

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Appointment>> watchAppointments() {
    return _firestore.collection('appointments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Appointment.fromJson({...doc.data(), 'id': doc.id})).toList();
    });
  }

  @override
  Future<void> updateAppointmentStatus({required String appointmentId, required String status}) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({'status': status});
    } catch (e) {
      throw FirestoreException('Unable to update appointment status.');
    }
  }
}

class MockAppointmentRepository implements AppointmentRepository {
  MockAppointmentRepository._();
  static final MockAppointmentRepository instance = MockAppointmentRepository._();

  final List<Appointment> _appointments = [
    
  ];

  final _controller = StreamController<List<Appointment>>.broadcast();

  @override
  Stream<List<Appointment>> watchAppointments() async* {
    yield List.unmodifiable(_appointments);
    yield* _controller.stream;
  }

  @override
  Future<void> updateAppointmentStatus({required String appointmentId, required String status}) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final old = _appointments[index];
      _appointments[index] = Appointment(
        id: old.id,
        patient: old.patient,
        appointmentTime: old.appointmentTime,
        status: status,
        notes: old.notes,
      );
      _controller.add(List.unmodifiable(_appointments));
    } else {
      throw const FirestoreException('Appointment not found.');
    }
  }

  void createMockAppointment({
    required String patientId,
    required String name,
    required int age,
    required String phone,
    required String symptoms,
  }) {
    final appointment = Appointment(
      id: 'mock-apt-${DateTime.now().millisecondsSinceEpoch}',
      patient: Patient(
        id: patientId,
        name: name,
        age: age,
        phone: phone,
      ),
      appointmentTime: DateTime.now().add(const Duration(minutes: 30)),
      status: 'Unconfirmed',
      notes: symptoms,
    );
    _appointments.add(appointment);
    _controller.add(List.unmodifiable(_appointments));
  }
}
