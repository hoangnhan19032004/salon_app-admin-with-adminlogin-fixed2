import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupportChatDetailScreen extends StatefulWidget {
  final String chatDocId;

  const SupportChatDetailScreen({super.key, required this.chatDocId});

  @override
  State<SupportChatDetailScreen> createState() => _SupportChatDetailScreenState();
}

class _SupportChatDetailScreenState extends State<SupportChatDetailScreen> {
  final _msgCtl = TextEditingController();
  final _scrollCtl = ScrollController();

  DocumentReference get _chatDoc =>
      FirebaseFirestore.instance.collection('support_chats').doc(widget.chatDocId);

  CollectionReference get _msgCol => _chatDoc.collection('messages');

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _msgCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtl.text.trim();
    if (text.isEmpty) return;
    _msgCtl.clear();

    final senderId = _user?.uid ?? "admin_local";
    final senderName = _user?.displayName ?? "Admin";

    // update room meta
    await _chatDoc.set({
      "lastMessage": text,
      "updatedAt": FieldValue.serverTimestamp(),
      "status": "open",
    }, SetOptions(merge: true));

    await _msgCol.add({
      "text": text,
      "senderId": senderId,
      "senderRole": "staff",
      "senderName": senderName,
      "createdAt": FieldValue.serverTimestamp(),
      "type": "text",
    });

    await Future.delayed(const Duration(milliseconds: 120));
    if (_scrollCtl.hasClients) {
      _scrollCtl.animateTo(
        _scrollCtl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết chat"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _msgCol.orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Lỗi tải tin nhắn."));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollCtl,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = (docs[i].data() as Map<String, dynamic>?) ?? {};
                    final text = (data['text'] ?? '').toString();
                    final role = (data['senderRole'] ?? '').toString();
                    final isStaff = role == 'staff';

                    return Align(
                      alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: isStaff
                              ? const Color(0xff721c80).withOpacity(0.12)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtl,
                      decoration: const InputDecoration(
                        hintText: "Nhập phản hồi (staff)...",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: Color(0xff721c80)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
