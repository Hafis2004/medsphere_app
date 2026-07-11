import 'patient.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.patient,
    required this.appointmentTime,
    required this.status,
    required this.notes,
  });

  final String id;
  final Patient patient;
  final DateTime appointmentTime;
  final String status;
  final String notes;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String? ?? '',
      patient: Patient.fromJson(json['patient'] as Map<String, dynamic>? ?? {}),
      appointmentTime: DateTime.parse(json['appointmentTime'] as String? ?? DateTime.now().toIso8601String()),
      status: json['status'] as String? ?? 'Unconfirmed',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient': patient.toJson(),
      'appointmentTime': appointmentTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}
