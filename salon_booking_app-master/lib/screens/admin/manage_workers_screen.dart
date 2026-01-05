import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageWorkersScreen extends StatefulWidget {
  const ManageWorkersScreen({super.key});

  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen> {
  static const String kDefaultWorkerId = 'G9ZvAbTR9HvoiMChKrTA';
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _ensureDefaultWorker() async {
    final ref = FirebaseFirestore.instance.collection('workers').doc(kDefaultWorkerId);
    final snap = await ref.get();
    if (snap.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Worker mặc định đã tồn tại.")),
      );
      return;
    }

    await ref.set({
      'name': 'Chuyên viên mặc định',
      'img': '',
      'phone': '',
      'specialty': 'Salon',
      'active': true,
      'booked': <dynamic>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã tạo worker mặc định cho BookingScreen.")),
    );
  }

  Color _chipColor(bool active) => active ? Colors.green : Colors.red;

  Future<void> _openEditor({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final data = doc?.data() ?? {};

    final idCtl = TextEditingController(text: doc?.id ?? "");
    final nameCtl = TextEditingController(text: (data['name'] ?? '').toString());
    final phoneCtl = TextEditingController(text: (data['phone'] ?? '').toString());
    final specCtl = TextEditingController(text: (data['specialty'] ?? '').toString());
    final imgCtl = TextEditingController(text: (data['img'] ?? '').toString());
    bool active = (data['active'] ?? true) == true;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            final img = imgCtl.text.trim();

            Widget preview() {
              if (img.isEmpty) {
                return Container(
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x11000000)),
                  ),
                  child: const Text("Chưa có ảnh"),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  img,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x11000000)),
                    ),
                    child: const Text("Không tải được ảnh"),
                  ),
                ),
              );
            }

            return AlertDialog(
              title: Text(doc == null ? "Thêm chuyên viên" : "Sửa chuyên viên"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    preview(),
                    const SizedBox(height: 10),

                    // ID
                    TextField(
                      controller: idCtl,
                      enabled: doc == null,
                      decoration: InputDecoration(
                        labelText: "ID (để trống sẽ tự sinh)",
                        hintText: "Ví dụ: $kDefaultWorkerId",
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tên
                    TextField(
                      controller: nameCtl,
                      decoration: InputDecoration(
                        labelText: "Tên chuyên viên",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // SĐT + Chuyên môn
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneCtl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Số điện thoại",
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: specCtl,
                            decoration: InputDecoration(
                              labelText: "Chuyên môn",
                              prefixIcon: const Icon(Icons.star_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Ảnh
                    TextField(
                      controller: imgCtl,
                      onChanged: (_) => setDlg(() {}),
                      decoration: InputDecoration(
                        labelText: "Ảnh (URL)",
                        hintText: "https://...",
                        prefixIcon: const Icon(Icons.image_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: active,
                      onChanged: (v) => setDlg(() => active = v),
                      title: const Text("Đang hoạt động"),
                      secondary: Icon(active ? Icons.toggle_on : Icons.toggle_off),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Hủy"),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.save),
                  label: const Text("Lưu"),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    final payload = <String, dynamic>{
      'name': nameCtl.text.trim(),
      'phone': phoneCtl.text.trim(),
      'specialty': specCtl.text.trim(),
      'img': imgCtl.text.trim(),
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      if (doc == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    final col = FirebaseFirestore.instance.collection('workers');

    if (doc == null) {
      final id = idCtl.text.trim();
      if (id.isEmpty) {
        await col.add({...payload, 'booked': <dynamic>[]});
      } else {
        await col.doc(id).set({...payload, 'booked': <dynamic>[]}, SetOptions(merge: true));
      }
    } else {
      await doc.reference.set(payload, SetOptions(merge: true));
    }
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final name = (data['name'] ?? 'chuyên viên').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa chuyên viên"),
        content: Text("Bạn chắc chắn muốn xóa: $name ?"),
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

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff721c80);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Quản lý chuyên viên"),
        actions: [
          IconButton(
            tooltip: "Tạo worker mặc định",
            onPressed: _ensureDefaultWorker,
            icon: const Icon(Icons.build_circle_outlined),
          ),
          IconButton(
            tooltip: "Thêm chuyên viên",
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner hướng dẫn (đẹp kiểu card)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0x11000000)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: primary.withOpacity(0.12),
                      child: const Icon(Icons.info_outline, color: primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "BookingScreen đang dùng workerId mặc định:\n$kDefaultWorkerId\n"
                            "Nếu bạn chưa có worker ID này, bấm nút 🔧 trên AppBar để tạo.",
                        style: const TextStyle(height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: "Tìm theo tên / SĐT / ID",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('workers').snapshots(),
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
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final phone = (data['phone'] ?? '').toString().toLowerCase();
                  final id = d.id.toLowerCase();
                  return q.isEmpty || name.contains(q) || phone.contains(q) || id.contains(q);
                }).toList();

                // sort updatedAt desc
                docs.sort((a, b) {
                  final ta = a.data()['updatedAt'];
                  final tb = b.data()['updatedAt'];
                  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                  return 0;
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có chuyên viên."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();

                    final name = (data['name'] ?? '').toString();
                    final phone = (data['phone'] ?? '').toString();
                    final specialty = (data['specialty'] ?? '').toString();
                    final img = (data['img'] ?? '').toString();
                    final active = (data['active'] ?? true) == true;
                    final c = _chipColor(active);

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
                                // Avatar/ảnh
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    color: primary.withOpacity(0.10),
                                    child: img.isEmpty
                                        ? Center(
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                                        style: const TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                    )
                                        : Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                                          style: const TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Info
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
                                        "ID: ${doc.id}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),

                                // Chip trạng thái
                                Chip(
                                  label: Text(
                                    active ? "Đang hoạt động" : "Tạm ẩn",
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

                            if (phone.trim().isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 18, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text("SĐT: $phone")),
                                ],
                              ),

                            if (specialty.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_outline, size: 18, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text("Chuyên môn: $specialty")),
                                ],
                              ),
                            ],

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            // Actions row (giống services/bookings)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openEditor(doc: doc),
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Sửa"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: BorderSide(color: primary.withOpacity(0.35)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
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
