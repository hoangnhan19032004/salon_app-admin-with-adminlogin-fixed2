import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  final _searchCtl = TextEditingController();

  static const _statusKeys = ["pending", "confirmed", "done", "cancel"];

  // ✅ Map hiển thị tiếng Việt
  static const Map<String, String> _statusLabel = {
    "pending": "Chờ xác nhận",
    "confirmed": "Đã xác nhận",
    "done": "Hoàn tất",
    "cancel": "Đã hủy",
  };

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _setStatus(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      String status,
      ) async {
    await doc.reference.set(
      {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final name = (data['serviceName'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa lịch hẹn"),
        content:
        Text("Xóa lịch hẹn: ${name.isEmpty ? '(không rõ dịch vụ)' : name} ?"),
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

  Color _statusColor(String status) {
    switch (status) {
      case "confirmed":
        return Colors.blue;
      case "done":
        return Colors.green;
      case "cancel":
        return Colors.red;
      case "pending":
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "confirmed":
        return Icons.verified_outlined;
      case "done":
        return Icons.check_circle_outline;
      case "cancel":
        return Icons.cancel_outlined;
      case "pending":
      default:
        return Icons.hourglass_bottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff721c80);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Quản lý lịch hẹn"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: "Tìm theo dịch vụ / user / SĐT / chuyên viên",
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
              stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
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
                  final service =
                  (data['serviceName'] ?? '').toString().toLowerCase();
                  final user = (data['userName'] ?? data['userEmail'] ?? '')
                      .toString()
                      .toLowerCase();
                  final phone = (data['phone'] ?? '').toString().toLowerCase();
                  final worker = (data['workerName'] ?? data['workerId'] ?? '')
                      .toString()
                      .toLowerCase();

                  return q.isEmpty ||
                      service.contains(q) ||
                      user.contains(q) ||
                      phone.contains(q) ||
                      worker.contains(q);
                }).toList();

                docs.sort((a, b) {
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                  return 0;
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có lịch hẹn."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();

                    final service = (data['serviceName'] ?? '').toString();
                    final date = (data['date'] ?? '').toString();
                    final time = (data['time'] ?? '').toString();
                    final user =
                    (data['userName'] ?? data['userEmail'] ?? '').toString();
                    final phone = (data['phone'] ?? '').toString();

                    // ✅ workerName / workerId
                    final workerName = (data['workerName'] ?? '').toString().trim();
                    final workerId = (data['workerId'] ?? '').toString().trim();
                    final workerText = workerName.isNotEmpty
                        ? workerName
                        : (workerId.isNotEmpty ? "(ID: $workerId)" : "(không rõ)");

                    String status = (data['status'] ?? 'pending').toString();
                    if (!_statusKeys.contains(status)) status = "pending";

                    final c = _statusColor(status);

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
                            // Header row: icon + service + chip
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primary.withOpacity(0.12),
                                  child:
                                  const Icon(Icons.event_available, color: primary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    service.isEmpty ? "(Không rõ dịch vụ)" : service,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Chip(
                                  avatar: Icon(_statusIcon(status),
                                      size: 16, color: c),
                                  label: Text(
                                    _statusLabel[status] ?? status,
                                    style: TextStyle(
                                        color: c, fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: c.withOpacity(0.10),
                                  side: BorderSide(color: c.withOpacity(0.25)),
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // User
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    user.isEmpty ? "User: (không rõ)" : "User: $user",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // ✅ Worker
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Chuyên viên: $workerText",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Date time
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "$date • $time",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Phone
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    phone.isEmpty ? "SĐT: (trống)" : "SĐT: $phone",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            // Actions: dropdown + delete
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color(0x22000000)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: status,
                                        isDense: true,
                                        icon: const Icon(Icons.expand_more),
                                        items: _statusKeys.map((k) {
                                          return DropdownMenuItem(
                                            value: k,
                                            child: Text(_statusLabel[k] ?? k),
                                          );
                                        }).toList(),
                                        onChanged: (v) async {
                                          if (v == null) return;
                                          await _setStatus(doc, v);
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
