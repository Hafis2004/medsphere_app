import 'dart:async';

import 'package:flutter/material.dart';

class MedSphereSplashScreen extends StatefulWidget {
  const MedSphereSplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<MedSphereSplashScreen> createState() => _MedSphereSplashScreenState();
}

class _MedSphereSplashScreenState extends State<MedSphereSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..forward();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0F1D),
              Color(0xFF111827),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Color(0xFF60A5FA),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MedSphere',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Care, connected.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
