import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends ConsumerState<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _symptomsController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            phone: _phoneController.text.trim(),
            symptoms: _symptomsController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created and consultation requested. Please log in.'),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  InputDecoration _fieldDecoration({required String label, required IconData icon, Widget? suffixIcon, bool alignLabelWithHint = false}) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: Icon(icon, color: const Color(0xFF52647C)),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE8EBF3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF3159C9), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FC),
        surfaceTintColor: Colors.transparent,
        title: const Text('Request care'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
                  const _RegisterHero(),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your details', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text('This helps the doctor prepare for your consultation.', style: TextStyle(color: Colors.blueGrey.shade600)),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: _fieldDecoration(label: 'Full name', icon: Icons.person_outline_rounded),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Full name is required' : null,
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: _fieldDecoration(label: 'Age', icon: Icons.cake_outlined),
                                  validator: (value) {
                                    final age = int.tryParse(value?.trim() ?? '');
                                    if (age == null || age <= 0 || age > 130) return 'Valid age required';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  autofillHints: const [AutofillHints.telephoneNumber],
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: _fieldDecoration(label: 'Phone number', icon: Icons.phone_outlined),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Phone is required';
                                    final phone = value.trim();
                                    if (phone.length != 10) return 'Enter a valid 10-digit phone number';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: _fieldDecoration(label: 'Email address', icon: Icons.mail_outline_rounded),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email is required';
                              final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                              return emailRegex.hasMatch(value.trim()) ? null : 'Enter a valid email';
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: _fieldDecoration(
                              label: 'Create password',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Password is required';
                              return value.length < 6 ? 'Use at least 6 characters' : null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _symptomsController,
                            minLines: 3,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _fieldDecoration(
                              label: 'What would you like help with?',
                              icon: Icons.notes_rounded,
                              alignLabelWithHint: true,
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please describe your symptoms or reason for care' : null,
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF3159C9),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: authState.isLoading ? null : _submit,
                              icon: authState.isLoading
                                  ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded),
                              label: Text(authState.isLoading ? 'Sending request...' : 'Create account & request care'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _WhatHappensNext(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0F1D),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.favorite_border_rounded, color: Color(0xFF60A5FA), size: 26),
          ),
          const SizedBox(height: 18),
          const Text('Care starts with a conversation.', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text('Share a few details and request your secure MedSphere consultation.', style: TextStyle(color: Colors.white.withAlpha(220), height: 1.35)),
          const SizedBox(height: 20),
          const Row(
            children: [
              _StepDot(number: '1', label: 'Your details'),
              _StepLine(),
              _StepDot(number: '2', label: 'Doctor review'),
              _StepLine(),
              _StepDot(number: '3', label: 'Video call'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Text(number, style: const TextStyle(color: Color(0xFF176C72), fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return const Expanded(child: Padding(padding: EdgeInsets.only(bottom: 19), child: Divider(color: Color(0x99FFFFFF), thickness: 1)));
  }
}

class _WhatHappensNext extends StatelessWidget {
  const _WhatHappensNext();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEAF7F2), borderRadius: BorderRadius.circular(18)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF167A59)),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What happens next?', style: TextStyle(color: Color(0xFF126248), fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Dr. Sarah Collins will review your request. Once approved, the doctor will start your video consultation.', style: TextStyle(color: Color(0xFF2C6D59), fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
