import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/extensions.dart';
import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_screen.dart';
import '../video_call/video_call_screen.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return FirebaseService.instance.isInitialized
      ? AppointmentRepositoryImpl()
      : MockAppointmentRepository.instance;
});

final appointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  return ref.watch(appointmentRepositoryProvider).watchAppointments();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final appointments = appointmentsAsync.valueOrNull ?? const <Appointment>[];
    final readyCount = appointments
        .where((item) => item.status == 'Confirmed')
        .length;
    final reviewCount = appointments
        .where((item) => item.status == 'Unconfirmed')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FC),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Row(
          children: [_AppMark(), SizedBox(width: 10), Text('MedSphere')],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(appointmentsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DoctorHero(readyCount: readyCount, reviewCount: reviewCount),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      'Today\'s consultations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${appointments.length} total',
                      style: TextStyle(color: Colors.blueGrey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                appointmentsAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const _EmptyAppointments();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) =>
                          _AppointmentCard(appointment: items[index]),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) =>
                      _DashboardError(message: error.toString()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = appointment.status;
    final isConfirmed = status == 'Confirmed';
    final isCancelled = status == 'Cancelled';
    final patientName = appointment.patient.name.trim();
    final initial = patientName.isEmpty
        ? '?'
        : patientName.substring(0, 1).toUpperCase();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFE8EEFF),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF3159C9),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Patient ID · ${appointment.patient.id}',
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF3159C9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${appointment.appointmentTime.formatDate()} · ${appointment.appointmentTime.formatTime()}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _DetailPill(
                  icon: Icons.cake_outlined,
                  label: '${appointment.patient.age} years',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailPill(
                    icon: Icons.phone_outlined,
                    label: appointment.patient.phone,
                  ),
                ),
              ],
            ),
            if (appointment.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'CONSULTATION NOTE',
                style: TextStyle(
                  color: Colors.blueGrey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appointment.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.blueGrey.shade700),
              ),
            ],
            const SizedBox(height: 18),
            if (status == 'Unconfirmed')
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: _buttonStyle,
                      onPressed: () async {
                        await ref
                            .read(appointmentRepositoryProvider)
                            .updateAppointmentStatus(
                              appointmentId: appointment.id,
                              status: 'Confirmed',
                            );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await ref
                            .read(appointmentRepositoryProvider)
                            .updateAppointmentStatus(
                              appointmentId: appointment.id,
                              status: 'Cancelled',
                            );
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            if (isConfirmed)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: _buttonStyle,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoCallScreen(
                          patientName: appointment.patient.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Start secure video call'),
                ),
              ),
            if (isCancelled) const _CancelledNotice(),
          ],
        ),
      ),
    );
  }
}

final _buttonStyle = FilledButton.styleFrom(
  backgroundColor: const Color(0xFF3159C9),
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3159C9), Color(0xFF6F8CFF)],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.health_and_safety_rounded,
        color: Colors.white,
        size: 19,
      ),
    );
  }
}

class _DoctorHero extends StatelessWidget {
  const _DoctorHero({required this.readyCount, required this.reviewCount});

  final int readyCount;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243E92), Color(0xFF5979E3)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good to see you,',
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.doctorDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your care desk is ready for today.',
            style: TextStyle(color: Colors.white.withAlpha(220)),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  value: '$readyCount',
                  label: 'Ready to call',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  value: '$reviewCount',
                  label: 'Awaiting review',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == 'Confirmed';
    final isCancelled = status == 'Cancelled';
    final color = isConfirmed
        ? const Color(0xFF17805D)
        : isCancelled
        ? const Color(0xFFC73A45)
        : const Color(0xFFB46C00);
    final label = isConfirmed
        ? 'Ready'
        : isCancelled
        ? 'Cancelled'
        : 'Review';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF52647C)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledNotice extends StatelessWidget {
  const _CancelledNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'This consultation was cancelled.',
        style: TextStyle(color: Color(0xFFC73A45), fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            color: Color(0xFF3159C9),
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'Your schedule is clear',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'New consultation requests will appear here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: const TextStyle(color: Color(0xFFC73A45)));
  }
}
