import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_chat_detail_screen.dart';

class ManageChatsScreen extends StatefulWidget {
  const ManageChatsScreen({super.key});

  @override
  State<ManageChatsScreen> createState() => _ManageChatsScreenState();
}

class _ManageChatsScreenState extends State<ManageChatsScreen> {
  String _filter = "open"; // open | closed | all
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  // ✅ Ưu tiên updatedAt -> createdAt -> chatId
  // Vì Firestore không cho "orderBy field A nếu thiếu" một cách an toàn,
  // ta chọn 1 field chắc có. Nếu bạn đảm bảo updatedAt luôn có thì giữ updatedAt.
  Query<Map<String, dynamic>> _baseQuery() {
    // Nếu bạn đã đảm bảo tất cả support_chats đều có updatedAt:
    return FirebaseFirestore.instance
        .collection('support_chats')
        .orderBy('updatedAt', descending: true);

    // Nếu bạn đang bị lỗi do doc thiếu updatedAt, hãy đổi sang createdAt:
    // return FirebaseFirestore.instance
    //     .collection('support_chats')
    //     .orderBy('createdAt', descending: true);
  }

  bool _matchSearch(Map<String, dynamic> d, String kw) {
    if (kw.isEmpty) return true;
    final s = kw.toLowerCase();

    final userName = (d['userName'] ?? '').toString().toLowerCase();
    final userEmail = (d['userEmail'] ?? '').toString().toLowerCase();
    final lastMessage = (d['lastMessage'] ?? '').toString().toLowerCase();
    final chatId = (d['chatId'] ?? '').toString().toLowerCase();

    return userName.contains(s) ||
        userEmail.contains(s) ||
        lastMessage.contains(s) ||
        chatId.contains(s);
  }

  bool _matchFilter(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'open').toString();
    if (_filter == "all") return true;
    return status == _filter;
  }

  // ✅ Dùng để sort tại client khi có doc thiếu updatedAt
  int _sortTime(Map<String, dynamic> d) {
    final updatedAt = d['updatedAt'];
    final createdAt = d['createdAt'];

    int toMs(dynamic ts) {
      if (ts is Timestamp) return ts.millisecondsSinceEpoch;
      return 0;
    }

    final u = toMs(updatedAt);
    if (u != 0) return u;

    final c = toMs(createdAt);
    if (c != 0) return c;

    // fallback: clientAt nếu có
    final clientAt = d['clientAt'];
    if (clientAt is int) return clientAt;

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xff721c80);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Quản lý Chat"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "open", label: Text("Đang mở")),
                          ButtonSegment(value: "closed", label: Text("Đã đóng")),
                          ButtonSegment(value: "all", label: Text("Tất cả")),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (s) => setState(() => _filter = s.first),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: "Tìm theo tên, email, nội dung cuối…",
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _baseQuery().snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  final err = snap.error.toString();

                  // ✅ Hiển thị nguyên nhân rõ ràng để bạn biết fix gì
                  String hint = "Lỗi Firestore.";
                  if (err.contains("permission-denied")) {
                    hint =
                    "Bạn chưa có quyền ADMIN.\nHãy set users/{adminUid}.role = \"admin\".";
                  } else if (err.contains("requires an index") ||
                      err.contains("FAILED_PRECONDITION")) {
                    hint =
                    "Query cần Index.\nVào Firebase Console → Firestore → Indexes để tạo theo link log.";
                  } else if (err.contains("orderBy") && err.contains("updatedAt")) {
                    hint =
                    "Có document thiếu updatedAt/createdAt.\nHãy đảm bảo support_chats luôn có updatedAt hoặc đổi sang orderBy(createdAt).";
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Lỗi tải danh sách chat",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(hint, textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          Text(
                            err.length > 260 ? "${err.substring(0, 260)}..." : err,
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

                final kw = _searchCtl.text.trim();

                // ✅ lọc ở client
                final docs = snap.data!.docs
                    .where((e) => _matchFilter(e.data()))
                    .where((e) => _matchSearch(e.data(), kw))
                    .toList();

                // ✅ sort lại ở client bằng updatedAt/createdAt fallback (đỡ lỗi data bẩn)
                docs.sort((a, b) => _sortTime(b.data()).compareTo(_sortTime(a.data())));

                if (docs.isEmpty) {
                  return const Center(child: Text("Không có phòng chat nào."));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d = doc.data();

                    final chatId = doc.id;
                    final userName = (d['userName'] ?? 'User').toString();
                    final userEmail = (d['userEmail'] ?? '').toString();
                    final lastMessage = (d['lastMessage'] ?? '').toString();
                    final status = (d['status'] ?? 'open').toString();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withOpacity(0.12),
                        child: Icon(
                          status == "open"
                              ? Icons.mark_chat_unread
                              : Icons.mark_chat_read,
                          color: primary,
                        ),
                      ),
                      title: Text(userName,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (userEmail.isNotEmpty)
                            Text(userEmail,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (lastMessage.isNotEmpty)
                            Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(status == "open" ? "OPEN" : "CLOSED"),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminChatDetailScreen(chatId: chatId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
