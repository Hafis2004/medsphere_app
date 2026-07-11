import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/patient_register_screen.dart';
import '../../features/dashboard/patient_dashboard_screen.dart';
import '../../features/video_call/video_call_screen.dart';
import '../../widgets/app_shell.dart';
import '../constants/app_constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final isRegistering = ref.watch(registrationInProgressProvider);
  final isLoggedIn = authState.whenOrNull(data: (user) => user != null) ?? false;
  final email = authState.whenOrNull(data: (user) => user?.email);
  final isDoctor = email == AppConstants.doctorEmail;

  return GoRouter(
    initialLocation: isLoggedIn
        ? (isDoctor ? '/dashboard' : '/patient-dashboard')
        : '/login',
    redirect: (context, state) {
      if (isRegistering) {
        return null;
      }
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return isDoctor ? '/dashboard' : '/patient-dashboard';
      }
      if (state.matchedLocation == '/call' && !isDoctor) {
        return '/patient-dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const PatientRegisterScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const AppShell()),
      GoRoute(path: '/patient-dashboard', builder: (context, state) => const PatientDashboardScreen()),
      GoRoute(path: '/notes', builder: (context, state) => const AppShell(initialIndex: 1)),
      GoRoute(path: '/call', builder: (context, state) => const VideoCallScreen()),
    ],
  );
});
