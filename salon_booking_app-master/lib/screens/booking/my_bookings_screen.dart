import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  DateTime? _bookingDateTime(Map<String, dynamic> data) {
    final dateKey = (data['dateKey'] ?? '').toString().trim(); // yyyyMMdd
    final time = (data['time'] ?? '').toString().trim(); // HH:mm
    if (dateKey.length != 8 || !time.contains(':')) return null;

    final y = int.tryParse(dateKey.substring(0, 4));
    final m = int.tryParse(dateKey.substring(4, 6));
    final d = int.tryParse(dateKey.substring(6, 8));

    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hh = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);

    if ([y, m, d, hh, mm].any((e) => e == null)) return null;
    return DateTime(y!, m!, d!, hh!, mm!);
  }

  String _fmtDateFromKey(String dateKey) {
    final k = dateKey.trim();
    if (k.length != 8) return k;
    final yyyy = k.substring(0, 4);
    final mm = k.substring(4, 6);
    final dd = k.substring(6, 8);
    return "$dd/$mm/$yyyy";
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _cancelBooking(
      BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final data = doc.data() ?? {};
    final status = (data['status'] ?? '').toString().toLowerCase().trim();
    if (status == 'cancelled') {
      _snack(context, "Lịch này đã huỷ rồi.");
      return;
    }

    // Không cho huỷ lịch đã qua
    final when = _bookingDateTime(data);
    if (when != null && when.isBefore(DateTime.now())) {
      _snack(context, "Lịch đã qua, không thể huỷ.");
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Huỷ lịch hẹn"),
        content: const Text("Bạn chắc chắn muốn huỷ lịch hẹn này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Không")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Huỷ lịch")),
        ],
      ),
    );
    if (ok != true) return;

    final workerId = (data['workerId'] ?? '').toString().trim();
    final serviceId = (data['serviceId'] ?? '').toString().trim();
    final time = (data['time'] ?? '').toString().trim();
    final dateKey = (data['dateKey'] ?? '').toString().trim();

    if (workerId.isEmpty || time.isEmpty || dateKey.length != 8) {
      _snack(context, "Thiếu dữ liệu booking (workerId/time/dateKey) để huỷ.");
      return;
    }

    // key mới: yyyyMMdd|HH:mm
    final k2 = "$dateKey|$time";

    // key cũ: dd/MM/yyyy|HH:mm|serviceId (để tương thích, nếu có serviceId)
    final dateText = (data['date'] ?? '').toString().trim();
    final dateV1 = dateText.isNotEmpty ? dateText : _fmtDateFromKey(dateKey);
    final String? k1 = serviceId.isNotEmpty ? "$dateV1|$time|$serviceId" : null;

    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(doc.id);
    final workerRef = FirebaseFirestore.instance.collection('workers').doc(workerId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        // Double check trạng thái booking hiện tại
        final bSnap = await tx.get(bookingRef);
        final bData = bSnap.data() as Map<String, dynamic>? ?? {};
        final st = (bData['status'] ?? '').toString().toLowerCase().trim();
        if (st == 'cancelled') return;

        // 1) Update booking -> cancelled
        tx.set(
          bookingRef,
          {
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 2) Remove slot khỏi worker.booked (arrayRemove)
        final removeList = <String>[k2];
        if (k1 != null) removeList.add(k1);

        tx.set(
          workerRef,
          {
            'booked': FieldValue.arrayRemove(removeList),
          },
          SetOptions(merge: true),
        );
      });

      _snack(context, "Đã huỷ lịch hẹn.");
    } catch (e) {
      _snack(context, "Huỷ thất bại: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xfffaf7fb),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          surfaceTintColor: Colors.white,
          title: const Text(
            "Lịch hẹn của tôi",
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xff721c80)),
          ),
          bottom: const TabBar(
            labelColor: Color(0xff721c80),
            indicatorColor: Color(0xff721c80),
            tabs: [
              Tab(text: "Sắp tới"),
              Tab(text: "Đã qua / Huỷ"),
            ],
          ),
        ),
        body: user == null
            ? const Center(child: Text("Bạn chưa đăng nhập."))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text("Lỗi: ${snap.error}"));
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text("Bạn chưa đặt lịch nào."));
            }

            final now = DateTime.now();

            final upcoming = <DocumentSnapshot<Map<String, dynamic>>>[];
            final history = <DocumentSnapshot<Map<String, dynamic>>>[];

            for (final d in docs) {
              final data = d.data();
              final status = (data['status'] ?? '').toString().toLowerCase().trim();
              final when = _bookingDateTime(data);

              final isUpcoming = when != null ? when.isAfter(now) : true;
              final isCancelled = status == 'cancelled';

              if (!isCancelled && isUpcoming) {
                upcoming.add(d);
              } else {
                history.add(d);
              }
            }

            Widget buildList(
                List<DocumentSnapshot<Map<String, dynamic>>> list, {
                  required bool showCancel,
                }) {
              if (list.isEmpty) {
                return const Center(child: Text("Không có lịch nào."));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final doc = list[i];
                  final data = doc.data() ?? {};

                  final serviceName = (data['serviceName'] ?? 'Dịch vụ').toString();
                  final workerName = (data['workerName'] ?? 'Chuyên viên').toString();
                  final time = (data['time'] ?? '').toString().trim();

                  final date = (data['date'] ?? '').toString().trim();
                  final dateKey = (data['dateKey'] ?? '').toString().trim();
                  final dateShow = date.isNotEmpty ? date : _fmtDateFromKey(dateKey);

                  final phone = (data['phone'] ?? '').toString().trim();
                  final note = (data['note'] ?? '').toString().trim();
                  final status = (data['status'] ?? '').toString().toLowerCase().trim();
                  final isCancelled = status == 'cancelled';

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  serviceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isCancelled)
                                const Text(
                                  "ĐÃ HUỶ",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "📅 $dateShow  •  ⏰ $time",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("👤 $workerName", style: const TextStyle(color: Colors.black54)),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text("📞 $phone", style: const TextStyle(color: Colors.black54)),
                          ],
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text("📝 $note", style: const TextStyle(color: Colors.black54)),
                          ],
                          if (showCancel && !isCancelled) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () => _cancelBooking(context, doc),
                                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                label: const Text(
                                  "Huỷ lịch",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return TabBarView(
              children: [
                buildList(upcoming, showCancel: true),
                buildList(history, showCancel: false),
              ],
            );
          },
        ),
      ),
    );
  }
}
