import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/doctor_availability_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(doctorAvailabilityProvider);
    final isAvailable = availabilityAsync.valueOrNull ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FC),
        surfaceTintColor: Colors.transparent,
        title: const Text('My profile'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          children: [
            _ProfileHero(isAvailable: isAvailable),
            const SizedBox(height: 16),
            _AvailabilityControl(
              isAvailable: isAvailable,
              isUpdating: availabilityAsync.isLoading,
              onChanged: (value) async {
                try {
                  await ref.read(doctorAvailabilityRepositoryProvider).setAvailability(value);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update availability.')));
                  }
                }
              },
            ),
            const SizedBox(height: 22),
            _SectionCard(
              title: 'Professional details',
              icon: Icons.badge_outlined,
              children: const [
                _ProfileRow(icon: Icons.local_hospital_outlined, label: 'Specialty', value: 'Internal Medicine'),
                _ProfileRow(icon: Icons.workspace_premium_outlined, label: 'License status', value: 'Verified clinician'),
                _ProfileRow(icon: Icons.business_outlined, label: 'Care location', value: 'MedSphere clinic'),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Contact & availability',
              icon: Icons.call_outlined,
              children: const [
                _ProfileRow(icon: Icons.email_outlined, label: 'Work email', value: 'doctor@medsphere.app'),
                _ProfileRow(icon: Icons.phone_outlined, label: 'Clinic phone', value: '0477 468246'),
                _ProfileRow(icon: Icons.schedule_outlined, label: 'Availability', value: 'Mon – Fri · 9:00 AM – 5:00 PM'),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: Color(0xFF167A59)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Secure care profile', style: TextStyle(color: Color(0xFF126248), fontWeight: FontWeight.w800)),
                        SizedBox(height: 3),
                        Text('Your professional information is protected and visible only to authorized patients.', style: TextStyle(color: Color(0xFF2C6D59), fontSize: 12, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243E92), Color(0xFF5D7CE2)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(150), width: 2),
                ),
                child: const Center(
                  child: Text('SC', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Color(0xFF55D5A5), shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF103F35), size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Dr. Sarah Collins', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text('Internal Medicine Specialist', style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 15)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: isAvailable ? const Color(0xFF55D5A5) : const Color(0xFFFFC66D), size: 9),
                const SizedBox(width: 7),
                Text(isAvailable ? 'Available for consultations' : 'Currently unavailable', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityControl extends StatelessWidget {
  const _AvailabilityControl({required this.isAvailable, required this.isUpdating, required this.onChanged});

  final bool isAvailable;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFEAF7F2), borderRadius: BorderRadius.circular(12)),
            child: Icon(isAvailable ? Icons.toggle_on_rounded : Icons.pause_circle_outline_rounded, color: isAvailable ? const Color(0xFF167A59) : const Color(0xFF9A6600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAvailable ? 'Accepting consultations' : 'Not accepting consultations', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(isAvailable ? 'Patients can see that you are available.' : 'Patients will see that you are unavailable.', style: const TextStyle(color: Color(0xFF66768E), fontSize: 12)),
              ],
            ),
          ),
          Switch(value: isAvailable, onChanged: isUpdating ? null : onChanged, activeColor: const Color(0xFF167A59)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE8EEFF), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: const Color(0xFF3159C9), size: 19),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF66768E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF66768E), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
