import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _initialized = false;

  FirebaseAuth? get auth => _auth;
  FirebaseFirestore? get firestore => _firestore;

  Future<void> initialize() async {
    try {
      // On web Firebase requires generated FirebaseOptions. If not present
      // initialization will fail; catch and continue so the app can still run
      // in a demo/local mode.
      await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _initialized = true;
    } catch (e) {
      // Log and continue without Firebase for local/demo runs.
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firebase initialization skipped or failed: $e');
      }
      _initialized = false;
    }
  }

  bool get isInitialized => _initialized;

  Stream<User?> authStateChanges() => _initialized ? _auth!.authStateChanges() : Stream.value(null);
}
