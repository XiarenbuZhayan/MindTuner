import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseConfig {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
      
      // 检查 Firebase Auth 是否可用
      final auth = FirebaseAuth.instance;
      debugPrint('Firebase Auth instance created successfully');
      
      // 检查 Firestore 是否可用
      final firestore = FirebaseFirestore.instance;
      debugPrint('Firebase Firestore instance created successfully');
      
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      debugPrint('Error type: ${e.runtimeType}');
    }
  }
} 