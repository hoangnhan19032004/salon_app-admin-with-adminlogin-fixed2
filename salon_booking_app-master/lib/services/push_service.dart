import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> initPush() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseMessaging.instance.requestPermission();

  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  await FirebaseMessaging.instance.subscribeToTopic('promotions');
}
