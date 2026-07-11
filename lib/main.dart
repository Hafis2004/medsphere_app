import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/medsphere_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.instance.initialize();

  runApp(
    const ProviderScope(
      child: MedSphereApp(),
    ),
  );
}

class MedSphereApp extends ConsumerStatefulWidget {
  const MedSphereApp({super.key});

  @override
  ConsumerState<MedSphereApp> createState() => _MedSphereAppState();
}

class _MedSphereAppState extends ConsumerState<MedSphereApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MedSphere',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: MedSphereSplashScreen(
          onComplete: () {
            if (mounted) {
              setState(() {
                _showSplash = false;
              });
            }
          },
        ),
      );
    }

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MedSphere',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}