// lib/services/vnpay_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

Future<void> startVnpayPayment({
  required String bookingId,
  required int amountVnd,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("NOT_LOGGED_IN");

  // 1) đọc cấu hình từ Firestore
  final cfg = await FirebaseFirestore.instance
      .collection('app_config')
      .doc('payment')
      .get();

  final payUrl = (cfg.data()?['vnpayPayUrl'] ?? '').toString().trim();
  if (payUrl.isEmpty) {
    throw Exception("Chưa cấu hình link VNPAY. Hãy set app_config/payment.vnpayPayUrl");
  }

  // 2) gọi backend để lấy paymentUrl
  final res = await http.post(
    Uri.parse(payUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "bookingId": bookingId,
      "amount": amountVnd,
      "userId": user.uid,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("Backend lỗi ${res.statusCode}: ${res.body}");
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final paymentUrl = (data["paymentUrl"] ?? "").toString();
  if (paymentUrl.isEmpty) throw Exception("Backend không trả paymentUrl");

  // 3) mở trang thanh toán VNPAY
  final uri = Uri.parse(paymentUrl);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) throw Exception("Không mở được trang thanh toán");
}
