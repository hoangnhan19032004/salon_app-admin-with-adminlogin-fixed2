import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _openEditor({QueryDocumentSnapshot? doc}) async {
    final data = (doc?.data() as Map<String, dynamic>?) ?? {};

    final nameCtl = TextEditingController(text: (data['name'] ?? '').toString());
    final priceCtl = TextEditingController(text: (data['price'] ?? '').toString());
    final durationCtl = TextEditingController(text: (data['duration'] ?? '').toString());
    final descCtl = TextEditingController(text: (data['desc'] ?? '').toString());
    final imgCtl = TextEditingController(
      text: (data['imageUrl'] ?? data['img'] ?? '').toString(),
    );

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
              title: Text(doc == null ? "Thêm dịch vụ" : "Sửa dịch vụ"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    preview(),
                    const SizedBox(height: 10),

                    TextField(
                      controller: imgCtl,
                      onChanged: (_) => setDlg(() {}),
                      decoration: InputDecoration(
                        labelText: "Ảnh (URL)",
                        hintText: "https://...",
                        prefixIcon: const Icon(Icons.image_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameCtl,
                      decoration: InputDecoration(
                        labelText: "Tên dịch vụ",
                        prefixIcon: const Icon(Icons.content_cut),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Giá (VND)",
                              prefixIcon: const Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: durationCtl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Thời lượng (phút)",
                              prefixIcon: const Icon(Icons.schedule),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: descCtl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Mô tả",
                        prefixIcon: const Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
      'price': int.tryParse(priceCtl.text.trim()) ?? 0,
      'duration': int.tryParse(durationCtl.text.trim()) ?? 0,
      'desc': descCtl.text.trim(),
      'imageUrl': imgCtl.text.trim(),
      'img': imgCtl.text.trim(),
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      if (doc == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    final col = FirebaseFirestore.instance.collection('services');
    if (doc == null) {
      await col.add(payload);
    } else {
      await doc.reference.set(payload, SetOptions(merge: true));
    }
  }

  Future<void> _delete(QueryDocumentSnapshot doc) async {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final name = (data['name'] ?? 'dịch vụ').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa dịch vụ"),
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
        title: const Text("Admin - Quản lý dịch vụ"),
        actions: [
          IconButton(
            tooltip: "Thêm dịch vụ",
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: "Tìm theo tên dịch vụ",
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải dữ liệu:\n${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final q = _searchCtl.text.trim().toLowerCase();

                final docs = snapshot.data!.docs.where((d) {
                  final data = (d.data() as Map<String, dynamic>?) ?? {};
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return q.isEmpty || name.contains(q);
                }).toList();

                docs.sort((a, b) {
                  final da = (a.data() as Map<String, dynamic>?) ?? {};
                  final db = (b.data() as Map<String, dynamic>?) ?? {};
                  final ta = da['updatedAt'];
                  final tb = db['updatedAt'];
                  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                  return 0;
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có dịch vụ."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i] as QueryDocumentSnapshot;
                    final data = (doc.data() as Map<String, dynamic>?) ?? {};

                    final name = (data['name'] ?? '').toString();
                    final price = (data['price'] is num)
                        ? (data['price'] as num).toInt()
                        : int.tryParse((data['price'] ?? '').toString()) ?? 0;
                    final duration = (data['duration'] is num)
                        ? (data['duration'] as num).toInt()
                        : int.tryParse((data['duration'] ?? '').toString()) ?? 0;
                    final desc = (data['desc'] ?? '').toString();
                    final img = (data['imageUrl'] ?? data['img'] ?? '').toString();
                    final active = (data['active'] ?? true) == true;

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
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    color: primary.withOpacity(0.10),
                                    child: img.isEmpty
                                        ? const Icon(Icons.image_outlined, color: primary)
                                        : Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image_outlined, color: primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Title + meta
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
                                        "Giá: $price đ • ${duration}p",
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),

                                // Active chip
                                Chip(
                                  label: Text(
                                    active ? "Đang hoạt động" : "Tạm ẩn",
                                    style: TextStyle(
                                      color: active ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor:
                                  (active ? Colors.green : Colors.red).withOpacity(0.10),
                                  side: BorderSide(
                                    color: (active ? Colors.green : Colors.red).withOpacity(0.25),
                                  ),
                                ),
                              ],
                            ),

                            if (desc.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

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
