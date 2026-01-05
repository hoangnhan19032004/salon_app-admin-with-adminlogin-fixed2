import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManagePromotionsScreen extends StatefulWidget {
  const ManagePromotionsScreen({super.key});

  @override
  State<ManagePromotionsScreen> createState() => _ManagePromotionsScreenState();
}

class _ManagePromotionsScreenState extends State<ManagePromotionsScreen> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _openEditor({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final data = doc?.data() ?? {};
    final titleCtl = TextEditingController(text: (data['title'] ?? '').toString());
    final bodyCtl = TextEditingController(text: (data['body'] ?? '').toString());
    final imgCtl = TextEditingController(text: (data['imageUrl'] ?? '').toString());
    bool active = (data['active'] ?? true) == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc == null ? "Thêm ưu đãi" : "Sửa ưu đãi"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtl,
                decoration: const InputDecoration(labelText: "Tiêu đề"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Nội dung"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imgCtl,
                decoration: const InputDecoration(
                  labelText: "Ảnh (URL) - optional",
                  hintText: "https://...",
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: active,
                onChanged: (v) => setState(() => active = v),
                title: const Text("Đang hoạt động"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Lưu")),
        ],
      ),
    );

    if (ok != true) return;

    final payload = <String, dynamic>{
      'title': titleCtl.text.trim(),
      'body': bodyCtl.text.trim(),
      'imageUrl': imgCtl.text.trim(),
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      if (doc == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    final col = FirebaseFirestore.instance.collection('promotions');
    if (doc == null) {
      await col.add(payload);
    } else {
      await doc.reference.set(payload, SetOptions(merge: true));
    }
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final d = doc.data();
    final title = (d['title'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa ưu đãi"),
        content: Text("Bạn chắc chắn muốn xóa: ${title.isEmpty ? '(không tiêu đề)' : title}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa")),
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
        title: const Text("Admin - Quản lý ưu đãi"),
        actions: [
          IconButton(
            tooltip: "Thêm ưu đãi",
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: "Tìm theo tiêu đề / nội dung",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('promotions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text("Lỗi tải dữ liệu:\n${snap.error}"));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final kw = _searchCtl.text.trim().toLowerCase();
                final docs = snap.data!.docs.where((e) {
                  final d = e.data();
                  final t = (d['title'] ?? '').toString().toLowerCase();
                  final b = (d['body'] ?? '').toString().toLowerCase();
                  return kw.isEmpty || t.contains(kw) || b.contains(kw);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Chưa có ưu đãi."));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d = doc.data();
                    final title = (d['title'] ?? '').toString();
                    final body = (d['body'] ?? '').toString();
                    final active = (d['active'] ?? true) == true;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withOpacity(0.12),
                        child: Icon(active ? Icons.campaign : Icons.campaign_outlined, color: primary),
                      ),
                      title: Text(title.isEmpty ? "(Không tiêu đề)" : title),
                      subtitle: Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          Chip(label: Text(active ? "ON" : "OFF")),
                          IconButton(
                            tooltip: "Sửa",
                            onPressed: () => _openEditor(doc: doc),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            tooltip: "Xóa",
                            onPressed: () => _delete(doc),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
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
