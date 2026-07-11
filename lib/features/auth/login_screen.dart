import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/exceptions.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum UserRole { patient, doctor }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.patient;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setRole(UserRole role) {
    if (_selectedRole == role) return;
    setState(() {
      _selectedRole = role;
      _formKey.currentState?.reset();
      if (role == UserRole.doctor) {
        _emailController.text = 'doctor@medsphere.app';
        _passwordController.text = 'doctor123';
      } else {
        _emailController.text = '';
        _passwordController.text = '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final email = _emailController.text.trim();

      if (_selectedRole == UserRole.doctor && email != AppConstants.doctorEmail) {
        throw const AuthException('Only doctor accounts can sign in to the Doctor Workspace.');
      }

      if (_selectedRole == UserRole.patient && email == AppConstants.doctorEmail) {
        throw const AuthException('Doctor accounts must sign in using the Doctor Workspace tab.');
      }

      await ref.read(authControllerProvider.notifier).signIn(
            email: email,
            password: _passwordController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in successfully.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  InputDecoration _fieldDecoration({required String label, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF52647C)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE8EBF3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE74C3C))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                children: [
                  const _LoginHero(),
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
                          Row(
                            children: [
                              Expanded(
                                child: _RoleTabButton(
                                  isSelected: _selectedRole == UserRole.patient,
                                  label: 'Patient',
                                  icon: Icons.person_outline_rounded,
                                  onTap: () => _setRole(UserRole.patient),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RoleTabButton(
                                  isSelected: _selectedRole == UserRole.doctor,
                                  label: 'Doctor',
                                  icon: Icons.medical_services_outlined,
                                  onTap: () => _setRole(UserRole.doctor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _selectedRole == UserRole.doctor ? 'Doctor Login' : 'Patient Login',
                            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedRole == UserRole.doctor
                                ? 'Sign in to manage your care workspace.'
                                : 'Sign in to access your consultations.',
                            style: TextStyle(color: Colors.blueGrey.shade600),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: _fieldDecoration(label: 'Email address', icon: Icons.mail_outline_rounded),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email is required';
                              final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: _fieldDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Password is required';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: authState.isLoading ? null : _submit,
                              icon: authState.isLoading
                                  ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.login_rounded),
                              label: Text(authState.isLoading ? 'Signing in...' : 'Sign in securely'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _SecurityNote(),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedRole == UserRole.patient) ...[
                    const SizedBox(height: 18),
                    TextButton.icon(
                      onPressed: () => context.push('/register'),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('New patient? Request a consultation'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF60A5FA), size: 27),
          ),
          const SizedBox(height: 22),
          Text(AppConstants.appName, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text('A calmer, more connected way to deliver care.', style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 15)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, color: Color(0xFF60A5FA), size: 16),
                SizedBox(width: 7),
                Text('Private & secure care', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF66768E)),
        SizedBox(width: 8),
        Expanded(child: Text('Your credentials and consultations are protected with secure access controls.', style: TextStyle(color: Color(0xFF66768E), fontSize: 12, height: 1.35))),
      ],
    );
  }
}

class _RoleTabButton extends StatelessWidget {
  const _RoleTabButton({
    required this.isSelected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool isSelected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE0E8FF),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF3159C9),
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF3159C9),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
