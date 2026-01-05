import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  final _focusNode = FocusNode();

  bool _sending = false;
  bool _botTyping = false;

  // ✅ NEW: trạng thái đang xóa chat
  bool _deleting = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  // ✅ chỉ tạo chatId khi đã login
  String get _chatId => "support_${_user!.uid}";

  DocumentReference<Map<String, dynamic>> get _chatDoc =>
      FirebaseFirestore.instance.collection('support_chats').doc(_chatId);

  CollectionReference<Map<String, dynamic>> get _msgCol =>
      _chatDoc.collection('messages');

  @override
  void dispose() {
    _msgCtl.dispose();
    _scrollCtl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollCtl.hasClients) return;
    await Future.delayed(const Duration(milliseconds: 60));
    if (!_scrollCtl.hasClients) return;
    _scrollCtl.animateTo(
      _scrollCtl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  // ✅ NEW: Xóa toàn bộ đoạn chat (messages + room doc) bằng batch
  Future<void> _deleteChat() async {
    final user = _user;
    if (user == null) {
      _snack("Bạn cần đăng nhập để xóa chat.");
      return;
    }
    if (_deleting) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa đoạn chat?"),
        content: const Text(
          "Toàn bộ lịch sử chat sẽ bị xóa vĩnh viễn.\nBạn có chắc chắn muốn xóa không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _deleting = true);

    try {
      // 1) Xóa messages theo từng batch (<= 450 docs / commit)
      while (true) {
        final snap = await _msgCol.limit(450).get();
        if (snap.docs.isEmpty) break;

        final batch = FirebaseFirestore.instance.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }

      // 2) Xóa room doc
      await _chatDoc.delete();

      _snack("Đã xóa đoạn chat.");
    } on FirebaseException catch (e) {
      _snack("Không thể xóa chat (${e.code}). Kiểm tra Firestore Rules.");
    } catch (e) {
      _snack("Không thể xóa chat: $e");
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ====== Salon-only bot ======
  bool _isSalonTopic(String text) {
    final t = text.toLowerCase();

    const salonKeywords = <String>[
      "xin chào",
      "chào",
      "hi",
      "hello",
      "tóc",
      "salon",
      "cắt",
      "uốn",
      "nhuộm",
      "duỗi",
      "gội",
      "hấp",
      "phục hồi",
      "dưỡng",
      "keratin",
      "tẩy",
      "balayage",
      "ombre",
      "highlight",
      "layer",
      "bob",
      "undercut",
      "mullet",
      "pixie",
      "mái",
      "booking",
      "đặt lịch",
      "lịch hẹn",
      "giá",
      "phí",
      "dịch vụ",
      "thời gian",
      "mở cửa",
      "đóng cửa",
      "tư vấn",
      "da đầu",
      "rụng tóc",
      "gàu",
    ];

    return salonKeywords.any((k) => t.contains(k));
  }

  String _botReplySalon(String text) {
    final t = text.toLowerCase();

    if (t.contains("xin chào") ||
        t.contains("chào") ||
        t.contains("hi") ||
        t.contains("hello")) {
      return """
Xin chào 👋
Mình là tư vấn salon tóc. Bạn muốn hỏi về:
- Giá dịch vụ
- Giờ mở cửa
- Đặt lịch
- Tư vấn uốn / duỗi / nhuộm / cắt, phục hồi tóc
Bạn cần hỗ trợ gì ạ?
""";
    }

    if (t.contains("giá") || t.contains("phí") || t.contains("bao nhiêu")) {
      return """
Bảng giá tham khảo (tuỳ độ dài tóc & tình trạng tóc):
- Cắt tóc: 70.000đ – 100.000đ
- Uốn / Duỗi: 120.000đ – 250.000đ
- Nhuộm: 300.000đ – 600.000đ
- Gội đầu / Massage: 100.000đ – 150.000đ

Bạn cho mình biết tóc bạn dài ngắn + dịch vụ muốn làm để mình tư vấn chính xác hơn nhé.
""";
    }

    if (t.contains("mở cửa") || t.contains("giờ") || t.contains("đóng cửa")) {
      return """
Giờ làm việc:
- Thứ 2 – Thứ 6: 08:00 – 22:00
- Cuối tuần & ngày lễ: 07:00 – 21:00

Bạn muốn tới khung giờ nào để mình hướng dẫn đặt lịch ạ?
""";
    }

    if (t.contains("đặt lịch") || t.contains("booking") || t.contains("lịch hẹn")) {
      return """
Hướng dẫn đặt lịch:
Đặt lịch → Chọn ngày → Chọn dịch vụ → Chọn khung giờ → Điền thông tin liên hệ → Xác nhận.

Lưu ý: Salon sẽ liên hệ trước 1h để chuẩn bị cho bạn.
Bạn muốn đặt lịch ngày nào và làm dịch vụ gì ạ?
""";
    }

    if (t.contains("uốn")) {
      return """
Bạn muốn uốn kiểu nào ạ?
- Uốn lơi / Sóng nước
- Chữ C / Chữ S
- Uốn phồng chân tóc
- Uốn nóng / uốn lạnh

Bạn cho mình biết tóc bạn hiện có khô/xơ không để mình gợi ý gói phục hồi kèm theo nhé.
Bạn cứ nhắn kiểu mà mình mong muốn, tình trạng tóc và đợi một vài phút sẽ có nhân viên chat trực tiếp hỗ trợ cho bạn nhé !
""";
    }

    if (t.contains("nhuộm") || t.contains("màu")) {
      return """
Bạn muốn nhuộm màu gì ạ? (xanh đen, nâu tây, đỏ, tím, highlight/balayage…)
Bạn cho mình biết tóc bạn đã tẩy/nhuộm trước đó chưa để tư vấn lên màu chuẩn hơn nhé.
Bạn nhắn màu và tình trạng tóc sau đó sẽ có nhân viên hỗ trợ chat trực tiếp cho bạn nhá !
""";
    }

    if (t.contains("duỗi")) {
      return """
Bạn muốn:
- Duỗi thẳng tự nhiên
hay
- Duỗi cúp?

Tóc bạn có khô/xơ không để mình gợi ý phục hồi đi kèm cho mềm mượt hơn nhé.
Bạn cứ nhắn kiểu mà mình mong muốn, tình trạng tóc và đợi một vài phút sẽ có nhân viên chat trực tiếp hỗ trợ cho bạn nhé !
""";
    }

    // fallback salon topic
    return """
Mình hỗ trợ các chủ đề salon tóc: dịch vụ, giá, đặt lịch, tư vấn kiểu tóc & chăm sóc/phục hồi.
Bạn muốn làm gì cho tóc ạ?
""";
  }

  String _botReplyOffTopic() {
    return """
Mình chỉ hỗ trợ các chủ đề liên quan tới salon tóc (dịch vụ, giá, đặt lịch, tư vấn tóc, chăm sóc/phục hồi).
Bạn hỏi giúp mình về vấn đề tóc để mình hỗ trợ tốt nhất nhé 🙂.
""";
  }

  Future<void> _sendBotAutoReply(String userText) async {
    if (!mounted) return;

    setState(() => _botTyping = true);

    try {
      // giả lập thời gian tư vấn
      await Future.delayed(Duration(milliseconds: 450 + Random().nextInt(700)));

      final reply =
      _isSalonTopic(userText) ? _botReplySalon(userText) : _botReplyOffTopic();

      // add bot/staff message
      await _msgCol.add({
        "text": reply,
        "senderId": "staff_bot",
        "senderRole": "staff",
        "createdAt": FieldValue.serverTimestamp(),
        "clientAt": DateTime.now().millisecondsSinceEpoch,
        "type": "text",
      });

      // update room metadata
      await _chatDoc.set({
        "lastMessage": reply,
        "updatedAt": FieldValue.serverTimestamp(),
        "status": "open",
      }, SetOptions(merge: true));

      await _scrollToBottom();
    } on FirebaseException catch (e) {
      _snack("Bot không phản hồi (${e.code}). Kiểm tra Rules/Quyền.");
    } catch (e) {
      _snack("Bot không phản hồi: $e");
    } finally {
      if (mounted) setState(() => _botTyping = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtl.text.trim();
    if (text.isEmpty) return;

    final user = _user;
    if (user == null) {
      _snack("Bạn cần đăng nhập để chat.");
      return;
    }
    if (_sending || _deleting) return;

    setState(() => _sending = true);
    _msgCtl.clear();
    _focusNode.requestFocus();

    try {
      // update room metadata
      await _chatDoc.set({
        "chatId": _chatId,
        "userId": user.uid,
        "userName": user.displayName ?? "",
        "userEmail": user.email ?? "",
        "status": "open",
        "lastMessage": text,
        "updatedAt": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // add user message
      await _msgCol.add({
        "text": text,
        "senderId": user.uid,
        "senderRole": "user",
        "createdAt": FieldValue.serverTimestamp(),
        "clientAt": DateTime.now().millisecondsSinceEpoch,
        "type": "text",
      });

      await _scrollToBottom();

      // bot reply
      await _sendBotAutoReply(text);
    } on FirebaseException catch (e) {
      _snack("Không gửi được (${e.code}).");
    } catch (e) {
      _snack("Không gửi được: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final isLoggedIn = user != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thái Nhân Salon chat bot"),
        actions: [
          // ✅ NEW: nút xóa đoạn chat
          if (isLoggedIn)
            IconButton(
              tooltip: "Xóa đoạn chat",
              onPressed: _deleting ? null : _deleteChat,
              icon: _deleting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x11000000)),
              ),
              child: Text(
                isLoggedIn
                    ? "Bạn có thể hỏi về dịch vụ tóc, giá, giờ mở cửa, đặt lịch, chăm sóc/phục hồi tóc..."
                    : "Vui lòng đăng nhập để bắt đầu chat.",
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: !isLoggedIn
                  ? const Center(child: Text("Hãy đăng nhập để xem và gửi tin nhắn."))
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _msgCol.orderBy("createdAt", descending: false).snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    final err = snap.error.toString();
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Không tải được tin nhắn",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              err.length > 320 ? "${err.substring(0, 320)}..." : err,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh),
                              label: const Text("Thử lại"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  final total = docs.length + (_botTyping ? 1 : 0);

                  if (total == 0) {
                    return const Center(child: Text("Chưa có tin nhắn. Hãy nhắn để bắt đầu!"));
                  }

                  return ListView.builder(
                    controller: _scrollCtl,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: total,
                    itemBuilder: (context, i) {
                      if (_botTyping && i == docs.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F7EF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              "Tư vấn salon đang trả lời…",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        );
                      }

                      final m = docs[i].data();
                      final text = (m["text"] ?? "").toString();
                      final role = (m["senderRole"] ?? "").toString(); // user/staff
                      final isMe = role == "user";

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.80,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFEEE7FF) : const Color(0xFFE9F7EF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x11000000)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                const Text(
                                  "Tư vấn salon",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              if (!isMe) const SizedBox(height: 4),
                              Text(text),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _msgCtl,
                    enabled: isLoggedIn && !_sending && !_deleting,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: isLoggedIn ? "Nhập tin nhắn..." : "Đăng nhập để chat...",
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: "Gửi",
                  onPressed: (isLoggedIn && !_sending && !_deleting) ? _send : null,
                  icon: _sending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
