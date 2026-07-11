import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/exceptions.dart';
import '../auth/auth_controller.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({super.key, this.patientName});

  final String? patientName;

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen>
    with TickerProviderStateMixin {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isConnected = false;
  String _status = 'Initializing';

  Timer? _callTimer;
  int _secondsElapsed = 0;

  // Lifecycle & simulator states
  bool _isRemoteSpeaking = false;
  List<double> _speechWaveValues = List.filled(5, 0.0);
  Timer? _speechSimulationTimer;
  Timer? _autofocusTimer;

  // Animations
  late final AnimationController _idleController;
  late final AnimationController _speechController;
  late final AnimationController _focusController;

  bool _isRenderersDisposed = false;

  @override
  void initState() {
    super.initState();
    
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    
    _speechController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _initialize();
    _startCallTimer();
    _startSpeechSimulation();
    _startAutofocusSimulation();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isConnected) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  void _startSpeechSimulation() {
    _speechSimulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isConnected) return;
      
      final rand = math.Random();
      if (_isRemoteSpeaking) {
        if (rand.nextDouble() < 0.2) {
          setState(() {
            _isRemoteSpeaking = false;
            _speechWaveValues = List.filled(5, 0.0);
          });
          _speechController.stop();
        } else {
          setState(() {
            _speechWaveValues = List.generate(5, (_) => 0.1 + rand.nextDouble() * 0.9);
          });
        }
      } else {
        if (rand.nextDouble() < 0.15) {
          setState(() {
            _isRemoteSpeaking = true;
          });
          _speechController.repeat(reverse: true);
        }
      }
    });
  }

  void _startAutofocusSimulation() {
    _autofocusTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && _isConnected) {
        _focusController.forward(from: 0.0);
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _initialize() async {
    try {
      await _requestPermissions();
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      final localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      _localRenderer.srcObject = localStream;
      setState(() {
        _status = 'Connected';
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _status = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera] != PermissionStatus.granted) {
      throw const PermissionException('Camera permission denied.');
    }
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      throw const PermissionException('Microphone permission denied.');
    }
  }

  Future<void> _toggleMic() async {
    if (_localRenderer.srcObject == null) return;
    final audioTracks = _localRenderer.srcObject!.getAudioTracks();
    for (final track in audioTracks) {
      track.enabled = !_micEnabled;
    }
    setState(() => _micEnabled = !_micEnabled);
  }

  Future<void> _toggleCamera() async {
    if (_localRenderer.srcObject == null) return;
    final videoTracks = _localRenderer.srcObject!.getVideoTracks();
    for (final track in videoTracks) {
      track.enabled = !_cameraEnabled;
    }
    setState(() => _cameraEnabled = !_cameraEnabled);
  }

  Future<void> _switchCamera() async {
    final videoTracks = _localRenderer.srcObject?.getVideoTracks() ?? <MediaStreamTrack>[];
    for (final track in videoTracks) {
      await Helper.switchCamera(track);
    }
  }

  Future<void> _stopTracks() async {
    final tracks = <MediaStreamTrack>[];
    _localRenderer.srcObject?.getTracks().forEach(tracks.add);
    _remoteRenderer.srcObject?.getTracks().forEach(tracks.add);
    for (final track in tracks) {
      await track.stop();
    }
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
  }

  Future<void> _disposeRenderers() async {
    if (_isRenderersDisposed) return;
    _isRenderersDisposed = true;
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
  }

  Future<void> _endCall() async {
    _callTimer?.cancel();
    await _stopTracks();
    await _disposeRenderers();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _speechSimulationTimer?.cancel();
    _autofocusTimer?.cancel();
    _idleController.dispose();
    _speechController.dispose();
    _focusController.dispose();
    _stopTracks();
    _disposeRenderers();
    super.dispose();
  }

  Widget _buildRemoteVideo(String remoteImage, bool isDoctor) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _speechController,
          _focusController,
        ]),
        builder: (context, child) {
          // 1. Breathing Calculations
          final breathingScale = 1.60 + (_idleController.value * 0.04);
          final breathingY = _idleController.value * 4.0;
          
          // 3. Speech movement calculations
          double speechX = 0.0;
          double speechY = 0.0;
          double speechRotation = 0.0;
          if (_isRemoteSpeaking) {
            final speechAngle = _speechController.value * 2 * math.pi;
            speechY = math.sin(speechAngle) * 3.5;
            speechX = math.cos(speechAngle * 0.7) * 1.5;
            speechRotation = math.sin(speechAngle) * 0.008;
          }
          
          // 4. Autofocus scale/blur calculations
          double focusBlur = 0.0;
          double focusScaleBonus = 0.0;
          if (_focusController.isAnimating) {
            final focusProgress = (0.5 - (0.5 - _focusController.value).abs()) * 2.0;
            focusBlur = focusProgress * 3.5;
            focusScaleBonus = focusProgress * -0.015;
          }
          
          // Combine transformations
          final totalScale = breathingScale + focusScaleBonus;
          final totalX = speechX;
          final totalY = breathingY + speechY;
          final totalRotation = speechRotation;
          
          // 5. Light/Exposure Shift
          final exposureValue = 0.96 + (_idleController.value * 0.08);
          
          Widget videoWidget = Transform.translate(
            offset: Offset(totalX, totalY),
            child: Transform.rotate(
              angle: totalRotation,
              child: Transform.scale(
                scale: totalScale,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          );
          
          if (focusBlur > 0.01) {
            videoWidget = ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: focusBlur, sigmaY: focusBlur),
              child: videoWidget,
            );
          }
          
          videoWidget = ColorFiltered(
            colorFilter: ColorFilter.matrix([
              exposureValue, 0, 0, 0, 0,
              0, exposureValue, 0, 0, 0,
              0, 0, exposureValue, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: videoWidget,
          );
          
          return videoWidget;
        },
        child: Image.asset(remoteImage, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final isDoctor = user?.email == AppConstants.doctorEmail;

    final remoteImage = isDoctor
        ? 'assets/images/simulated_patient.png'
        : 'assets/images/simulated_doctor.png';

    final remoteName = isDoctor
        ? 'Patient: ${widget.patientName ?? 'Patient'}'
        : 'Doctor: Dr. Sarah Collins';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote View (Simulated Live Video)
            if (_isConnected)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildRemoteVideo(remoteImage, isDoctor),
                    // Simulated overlay grid/scanlines for webcam realism
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha((0.6 * 255).round()),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withAlpha((0.8 * 255).round()),
                          ],
                          stops: const [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Initializing consultation call...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),

            // Top Status Bar Overlay
            if (_isConnected)
              Positioned(
                left: 16,
                top: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.5 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _PulseDot(),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_secondsElapsed),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.5 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.signal_cellular_4_bar, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _status,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Local PiP View (Top Right, slightly below the status bar)
            Positioned(
              right: 16,
              top: 70,
              width: 120,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    border: Border.all(color: Colors.white30, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _cameraEnabled
                      ? RTCVideoView(_localRenderer, mirror: true)
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off, color: Colors.white54, size: 24),
                              SizedBox(height: 4),
                              Text(
                                'Camera Off',
                                style: TextStyle(color: Colors.white54, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            // Participant Name Overlay (Bottom Left)
            if (_isConnected)
              Positioned(
                left: 20,
                bottom: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          remoteName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black54, offset: Offset(0, 1.5), blurRadius: 4)],
                          ),
                        ),
                        if (_isRemoteSpeaking) ...[
                          const SizedBox(width: 8),
                          _VoiceWaveformIndicator(waveValues: _speechWaveValues),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.grey[400], size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'End-to-End Encrypted',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2)],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Bottom Controls Bar (Center aligned)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'mic',
                    backgroundColor: _micEnabled ? Colors.white24 : Colors.red,
                    foregroundColor: Colors.white,
                    onPressed: _toggleMic,
                    child: Icon(_micEnabled ? Icons.mic : Icons.mic_off),
                  ),
                  FloatingActionButton(
                    heroTag: 'camera',
                    backgroundColor: _cameraEnabled ? Colors.white24 : Colors.red,
                    foregroundColor: Colors.white,
                    onPressed: _toggleCamera,
                    child: Icon(_cameraEnabled ? Icons.videocam : Icons.videocam_off),
                  ),
                  FloatingActionButton(
                    heroTag: 'switch',
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    onPressed: _switchCamera,
                    child: const Icon(Icons.cameraswitch),
                  ),
                  FloatingActionButton(
                    heroTag: 'end',
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    onPressed: _endCall,
                    child: const Icon(Icons.call_end),
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

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _VoiceWaveformIndicator extends StatelessWidget {
  const _VoiceWaveformIndicator({required this.waveValues});

  final List<double> waveValues;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(waveValues.length, (index) {
          final height = 4.0 + (waveValues[index] * 16.0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 3.5,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withAlpha((0.9 * 255).round()),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withAlpha((0.4 * 255).round()),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}
