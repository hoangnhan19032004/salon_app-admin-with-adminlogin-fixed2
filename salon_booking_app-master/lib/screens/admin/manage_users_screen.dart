import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _setRole(QueryDocumentSnapshot<Map<String, dynamic>> doc, String role) async {
    await doc.reference.set(
      {'role': role, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final email = (data['email'] ?? '').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa user (Firestore)"),
        content: Text(
          "Xóa document user trong Firestore: ${email.isEmpty ? '(không có email)' : email}\n"
              "Lưu ý: thao tác này KHÔNG xóa tài khoản trong FirebaseAuth.",
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
    if (ok == true) await doc.reference.delete();
  }

  Color _roleColor(String role) {
    return role == "admin" ? Colors.blue : Colors.green;
  }

  String _roleLabel(String role) {
    return role == "admin" ? "Quản trị" : "Người dùng";
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff721c80);

    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Quản lý người dùng")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: "Tìm theo tên / email / UID",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải dữ liệu:\n${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final q = _searchCtl.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data();
                  final name = (data['name'] ?? data['displayName'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final uid = d.id.toLowerCase();
                  return q.isEmpty || name.contains(q) || email.contains(q) || uid.contains(q);
                }).toList();

                // sort updatedAt desc (nếu có)
                docs.sort((a, b) {
                  final ta = a.data()['updatedAt'];
                  final tb = b.data()['updatedAt'];
                  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                  return 0;
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có user."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();

                    final name = (data['name'] ?? data['displayName'] ?? '').toString();
                    final email = (data['email'] ?? '').toString();
                    String role = (data['role'] ?? 'user').toString();
                    if (role != "admin" && role != "user") role = "user";

                    final c = _roleColor(role);

                    final avatarLetter = (name.trim().isNotEmpty)
                        ? name.trim()[0].toUpperCase()
                        : (email.trim().isNotEmpty ? email.trim()[0].toUpperCase() : "?");

                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0x11000000)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primary.withOpacity(0.12),
                                  child: Text(
                                    avatarLetter,
                                    style: const TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isEmpty ? "(Không tên)" : name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email.isEmpty ? "(không có email)" : email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),

                                Chip(
                                  label: Text(
                                    _roleLabel(role),
                                    style: TextStyle(
                                      color: c,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: c.withOpacity(0.10),
                                  side: BorderSide(color: c.withOpacity(0.25)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.fingerprint, size: 18, color: Colors.black54),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "UID: ${doc.id}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0x22000000)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: role,
                                        isDense: true,
                                        icon: const Icon(Icons.expand_more),
                                        items: const [
                                          DropdownMenuItem(value: "user", child: Text("Người dùng")),
                                          DropdownMenuItem(value: "admin", child: Text("Quản trị")),
                                        ],
                                        onChanged: (v) async {
                                          if (v == null) return;
                                          await _setRole(doc, v);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _delete(doc),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text("Xóa"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red.withOpacity(0.35)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
