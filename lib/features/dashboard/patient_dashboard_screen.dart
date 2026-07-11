import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/extensions.dart';
import '../../models/appointment.dart';
import '../../repositories/doctor_availability_repository.dart';
import '../auth/auth_controller.dart';
import 'dashboard_screen.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final isDoctorAvailable = ref.watch(doctorAvailabilityProvider).valueOrNull ?? true;
    final patientName = user?.displayName?.trim().isNotEmpty == true ? user!.displayName! : 'there';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FC),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Row(
          children: [
            _PortalMark(),
            SizedBox(width: 10),
            Text('My care'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(appointmentsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PatientHero(name: patientName, isDoctorAvailable: isDoctorAvailable),
              const SizedBox(height: 28),
              Text('Your consultations', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Stay up to date with your care request.', style: TextStyle(color: Colors.blueGrey.shade600)),
              const SizedBox(height: 16),
              appointmentsAsync.when(
                data: (appointments) {
                  final myAppointments = appointments.where((appointment) => appointment.patient.id == user?.uid).toList();
                  if (myAppointments.isEmpty) return const _NoConsultations();
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myAppointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, index) => _PatientAppointmentCard(appointment: myAppointments[index], isDoctorAvailable: isDoctorAvailable),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientAppointmentCard extends StatelessWidget {
  const _PatientAppointmentCard({required this.appointment, required this.isDoctorAvailable});

  final Appointment appointment;
  final bool isDoctorAvailable;

  @override
  Widget build(BuildContext context) {
    final presentation = _StatusPresentation.from(appointment.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFFE8EEFF), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('SC', style: TextStyle(color: Color(0xFF3159C9), fontSize: 16, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dr. Sarah Collins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(isDoctorAvailable ? 'Internal Medicine · Available now' : 'Internal Medicine · Currently unavailable', style: const TextStyle(color: Color(0xFF66768E), fontSize: 12)),
                  ],
                ),
              ),
              _StatusBadge(presentation: presentation),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF4F7FF), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF3159C9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scheduled consultation', style: TextStyle(color: Color(0xFF66768E), fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('${appointment.appointmentTime.formatDate()} · ${appointment.appointmentTime.formatTime()}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('YOUR REQUEST', style: TextStyle(color: Color(0xFF66768E), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 5),
          Text(appointment.notes, style: const TextStyle(fontSize: 14, height: 1.35)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: presentation.background, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(presentation.icon, size: 19, color: presentation.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(presentation.nextStepTitle, style: TextStyle(color: presentation.color, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(presentation.description, style: TextStyle(color: presentation.color.withAlpha(220), fontSize: 12, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientHero extends StatelessWidget {
  const _PatientHero({required this.name, required this.isDoctorAvailable});

  final String name;
  final bool isDoctorAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF243E92), Color(0xFF5979E3)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, $name', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text('Your personal space for calm, connected care.', style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 15)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: isDoctorAvailable ? const Color(0xFFB6F3DC) : const Color(0xFFFFD58D), size: 10),
                const SizedBox(width: 7),
                Text(isDoctorAvailable ? 'Dr. Sarah is available today' : 'Dr. Sarah is currently unavailable', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalMark extends StatelessWidget {
  const _PortalMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: const Color(0xFFE8EEFF), borderRadius: BorderRadius.circular(11)),
      child: const Icon(Icons.favorite_outline_rounded, color: Color(0xFF3159C9), size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.presentation});

  final _StatusPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: presentation.background, borderRadius: BorderRadius.circular(999)),
      child: Text(presentation.label, style: TextStyle(color: presentation.color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _NoConsultations extends StatelessWidget {
  const _NoConsultations();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const Column(
        children: [
          Icon(Icons.event_note_outlined, size: 40, color: Color(0xFF3159C9)),
          SizedBox(height: 12),
          Text('No care requests yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          SizedBox(height: 4),
          Text('Your consultation updates will appear here.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({required this.label, required this.icon, required this.color, required this.background, required this.nextStepTitle, required this.description});

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final String nextStepTitle;
  final String description;

  factory _StatusPresentation.from(String status) {
    switch (status) {
      case 'Confirmed':
        return const _StatusPresentation(label: 'Approved', icon: Icons.check_circle_outline_rounded, color: Color(0xFF167A59), background: Color(0xFFEAF7F2), nextStepTitle: 'Your doctor will call you', description: 'Your consultation is approved. Dr. Sarah Collins will start the secure video call when ready.');
      case 'Cancelled':
        return const _StatusPresentation(label: 'Cancelled', icon: Icons.info_outline_rounded, color: Color(0xFFC73A45), background: Color(0xFFFFF1F2), nextStepTitle: 'This request was cancelled', description: 'Please contact the clinic if you need to make another care request.');
      default:
        return const _StatusPresentation(label: 'Under review', icon: Icons.hourglass_top_rounded, color: Color(0xFFAA6900), background: Color(0xFFFFF5E8), nextStepTitle: 'Waiting for doctor review', description: 'Dr. Sarah Collins is reviewing your request and will approve it when ready.');
    }
  }
}
