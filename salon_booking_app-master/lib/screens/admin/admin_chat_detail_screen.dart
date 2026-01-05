import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String chatId;

  const AdminChatDetailScreen({super.key, required this.chatId});

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final _msgCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  bool _sending = false;

  DocumentReference<Map<String, dynamic>> get _chatDoc =>
      FirebaseFirestore.instance.collection('support_chats').doc(widget.chatId);

  CollectionReference<Map<String, dynamic>> get _msgCol =>
      _chatDoc.collection('messages');

  @override
  void dispose() {
    _msgCtl.dispose();
    _scrollCtl.dispose();
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

  Future<void> _sendStaff() async {
    final text = _msgCtl.text.trim();
    if (text.isEmpty || _sending) return;

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) {
      _snack("Bạn chưa đăng nhập admin.");
      return;
    }

    setState(() => _sending = true);
    _msgCtl.clear();

    try {
      await _msgCol.add({
        "text": text,
        "senderId": admin.uid,
        "senderRole": "staff",
        "createdAt": FieldValue.serverTimestamp(),
        "clientAt": DateTime.now().millisecondsSinceEpoch,
        "type": "text",
      });

      await _chatDoc.set({
        "lastMessage": text,
        "updatedAt": FieldValue.serverTimestamp(),
        "status": "open",
      }, SetOptions(merge: true));

      await _scrollToBottom();
    } on FirebaseException catch (e) {
      _snack("Gửi thất bại (${e.code}).");
    } catch (e) {
      _snack("Gửi thất bại: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      await _chatDoc.set({
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      _snack("Không đổi trạng thái (${e.code}).");
    }
  }

  Future<void> _deleteRoom() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa phòng chat"),
        content: const Text("Bạn muốn xóa phòng chat này? (chỉ xóa metadata, messages cần xóa riêng)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // Lưu ý: xóa messages hàng loạt cần Cloud Function hoặc script.
      await _chatDoc.delete();
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      _snack("Xóa thất bại (${e.code}).");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff721c80);

    return Scaffold(
      appBar: AppBar(
        title: Text("Phòng: ${widget.chatId}"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == "open") _setStatus("open");
              if (v == "closed") _setStatus("closed");
              if (v == "delete") _deleteRoom();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "open", child: Text("Mở phòng")),
              PopupMenuItem(value: "closed", child: Text("Đóng phòng")),
              PopupMenuDivider(),
              PopupMenuItem(value: "delete", child: Text("Xóa phòng (metadata)")),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Room header info
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _chatDoc.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final d = snap.data!.data();
              if (d == null) return const SizedBox.shrink();

              final name = (d["userName"] ?? "User").toString();
              final email = (d["userEmail"] ?? "").toString();
              final status = (d["status"] ?? "open").toString();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x11000000)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primary.withOpacity(0.12),
                      child: const Icon(Icons.person, color: primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (email.isNotEmpty)
                            Text(email, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    Chip(label: Text(status.toUpperCase())),
                  ],
                ),
              );
            },
          ),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // chỉ orderBy 1 field để tránh yêu cầu index
              stream: _msgCol.orderBy("createdAt", descending: false).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text("Lỗi tải tin nhắn:\n${snap.error}"));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có tin nhắn."));
                }

                return ListView.builder(
                  controller: _scrollCtl,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final text = (m["text"] ?? "").toString();
                    final role = (m["senderRole"] ?? "").toString(); // user/staff
                    final isStaff = role == "staff";

                    return Align(
                      alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.80,
                        ),
                        decoration: BoxDecoration(
                          color: isStaff ? const Color(0xFFEEE7FF) : const Color(0xFFE9F7EF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x11000000)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isStaff ? "Admin/Staff" : "User",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
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

          // Input staff
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendStaff(),
                    decoration: InputDecoration(
                      hintText: "Nhập phản hồi cho khách...",
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _sendStaff,
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
          ),
        ],
      ),
    );
  }
}
