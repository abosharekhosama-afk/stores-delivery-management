import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 1. طلب الإذن (مهم جداً لأجهزة iOS وأندرويد 13+)
  static Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  // 2. جلب التوكن وتخزينه في Firestore
  static Future<void> updateTokenInFirestore() async {
    try {
      String? token = await _messaging.getToken();
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (token != null && userId != null) {
        await FirebaseFirestore.instance
            .collection('Stores') // تأكد أن هذا هو اسم الكولكشن عندك
            .doc(userId)
            .update({
              'fcmToken': token,
              'lastUpdate': FieldValue.serverTimestamp(),
            });
        debugPrint("FCM Token Updated: $token");
      }
    } catch (e) {
      debugPrint("Error updating token: $e");
    }
  }
}
