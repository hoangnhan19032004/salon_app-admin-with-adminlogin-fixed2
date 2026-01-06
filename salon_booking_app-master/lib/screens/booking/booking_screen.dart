import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;

  // ✅ chọn theo id để không bị lệch index
  String? _selectedServiceId;
  String? _selectedWorkerId;

  final _phoneCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  final List<String> _timeSlots = const [
    "09:00",
    "09:30",
    "10:00",
    "10:30",
    "11:00",
    "11:30",
    "13:00",
    "13:30",
    "14:00",
    "14:30",
    "15:00",
    "15:30",
    "16:00",
    "16:30",
    "17:00",
    "17:30",
    "18:00",
    "18:30",
    "19:00",
    "19:30",
    "20:00",
    "20:30",
    "21:00",
  ];

  @override
  void initState() {
    super.initState();
    _seedServicesIfEmpty(); // ✅ tạo dịch vụ mẫu nếu services rỗng
  }

  @override
  void dispose() {
    _phoneCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return "$dd/$mm/$yyyy";
  }

  // ✅ dùng key ngày ổn định để lưu booking (yyyyMMdd)
  String _dateKey(DateTime d) {
    final yyyy = d.year.toString();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "$yyyy$mm$dd";
  }

  String _formatVnd(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return "${buf.toString()}đ";
  }

  // ✅ Parse "HH:mm" => (hour, minute)
  (int, int)? _parseHHmm(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  // ✅ Không cho chọn giờ trong quá khứ (đặc biệt khi chọn ngày hôm nay)
  bool _isSlotInPast(DateTime date, String time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d0 = DateTime(date.year, date.month, date.day);

    if (d0.isBefore(today)) return true; // (thực tế datePicker đã chặn)
    if (d0.isAfter(today)) return false;

    // cùng ngày hôm nay => check giờ
    final parsed = _parseHHmm(time);
    if (parsed == null) return false;
    final (hh, mm) = parsed;
    final slot = DateTime(date.year, date.month, date.day, hh, mm);
    return slot.isBefore(now);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(first) ? first : _selectedDate,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // đổi ngày => reset giờ
      });
    }
  }

  /// ✅ Seed dịch vụ mẫu nếu `services` trống
  Future<void> _seedServicesIfEmpty() async {
    final col = FirebaseFirestore.instance.collection('services');
    try {
      final snap = await col.limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = FieldValue.serverTimestamp();
      final samples = [
        {
          'name': 'Cắt tóc',
          'price': 70000,
          'duration': 30,
          'desc': 'Cắt tóc nam/nữ theo yêu cầu.',
          'imageUrl': '',
          'active': true,
          'createdAt': now,
          'updatedAt': now,
        },
        {
          'name': 'Gội đầu + massage',
          'price': 100000,
          'duration': 30,
          'desc': 'Gội sạch + massage thư giãn.',
          'imageUrl': '',
          'active': true,
          'createdAt': now,
          'updatedAt': now,
        },
        {
          'name': 'Uốn / Duỗi',
          'price': 250000,
          'duration': 90,
          'desc': 'Uốn/duỗi cơ bản (tùy độ dài tóc).',
          'imageUrl': '',
          'active': true,
          'createdAt': now,
          'updatedAt': now,
        },
        {
          'name': 'Nhuộm',
          'price': 300000,
          'duration': 120,
          'desc': 'Nhuộm màu theo bảng màu salon.',
          'imageUrl':
          'https://sf-static.upanhlaylink.com/img/image_202601061666968712f8657b806067c4c45da111.jpg',
          'active': true,
          'createdAt': now,
          'updatedAt': now,
        },
      ];

      final batch = FirebaseFirestore.instance.batch();
      for (final s in samples) {
        batch.set(col.doc(), s, SetOptions(merge: true));
      }
      await batch.commit();

      _snack("Đã tạo dịch vụ mẫu trong Firestore (services).");
    } catch (e) {
      debugPrint("Seed services error: $e");
      _snack("Không tạo được dịch vụ mẫu: $e");
    }
  }

  // ✅ bookingKey mới: yyyyMMdd|HH:mm  (khóa theo worker + ngày + giờ)
  String _bookingKeyV2({required String time}) {
    return "${_dateKey(_selectedDate)}|$time";
  }

  // ⚠️ bookingKey cũ (để tương thích nếu bạn đã lưu kiểu cũ): dd/MM/yyyy|HH:mm|serviceId
  String _bookingKeyV1({required String time, required String serviceId}) {
    return "${_fmtDate(_selectedDate)}|$time|$serviceId";
  }

  bool _isBooked({
    required List<dynamic> bookedKeys,
    required String time,
    required String serviceId,
  }) {
    final k2 = _bookingKeyV2(time: time);
    final k1 = _bookingKeyV1(time: time, serviceId: serviceId);
    return bookedKeys.contains(k2) || bookedKeys.contains(k1);
  }

  Future<void> _book({
    required List<QueryDocumentSnapshot> serviceDocs,
    required List<dynamic> bookedKeys,
    required Map<String, dynamic>? workerData,
  }) async {
    final serviceId = _selectedServiceId;
    final workerId = _selectedWorkerId;

    if (serviceId == null) {
      _snack("Bạn chưa chọn dịch vụ.");
      return;
    }
    if (workerId == null) {
      _snack("Bạn chưa chọn chuyên viên.");
      return;
    }
    if (_selectedTime == null) {
      _snack("Bạn chưa chọn khung giờ.");
      return;
    }

    final time = _selectedTime!;
    if (_isSlotInPast(_selectedDate, time)) {
      _snack("Không thể chọn giờ trong quá khứ.");
      return;
    }

    final phone = _phoneCtl.text.trim();
    if (phone.isEmpty || !RegExp(r'^0\d{9}$').hasMatch(phone)) {
      _snack("Số điện thoại phải đủ 10 số và bắt đầu bằng 0.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack("Bạn cần đăng nhập trước khi đặt lịch.");
      return;
    }

    // ✅ tìm doc dịch vụ theo id
    QueryDocumentSnapshot? serviceDoc;
    for (final d in serviceDocs) {
      if (d.id == serviceId) {
        serviceDoc = d;
        break;
      }
    }
    if (serviceDoc == null) {
      _snack("Dịch vụ bạn chọn không tồn tại trong Firestore.");
      return;
    }

    final service = (serviceDoc.data() as Map<String, dynamic>? ?? {});
    final serviceName = (service['name'] ?? service['title'] ?? "Dịch vụ").toString();

    // ✅ tên chuyên viên (lấy từ workerData)
    final workerName = (workerData?['name'] ?? 'Chuyên viên').toString();

    // ✅ check bận theo worker + ngày + giờ
    final booked = List<dynamic>.from(bookedKeys);
    final isBusy = _isBooked(bookedKeys: booked, time: time, serviceId: serviceId);
    if (isBusy) {
      _snack("Chuyên viên đang bận khung giờ này. Vui lòng chọn giờ khác.");
      return;
    }

    final note = _noteCtl.text.trim();

    final workerRef = FirebaseFirestore.instance.collection('workers').doc(workerId);
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

    final k2 = _bookingKeyV2(time: time);
    final k1 = _bookingKeyV1(time: time, serviceId: serviceId); // thêm để tương thích

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(workerRef);
        final data = snap.data() as Map<String, dynamic>?;
        final List<dynamic> workerBooked = List<dynamic>.from(data?['booked'] ?? []);

        // ✅ chặn nếu bận (cả key mới và key cũ)
        if (workerBooked.contains(k2) || workerBooked.contains(k1)) {
          throw Exception("SLOT_ALREADY_BOOKED");
        }

        // ✅ add key mới + key cũ (để app cũ vẫn nhận bận)
        workerBooked.add(k2);
        workerBooked.add(k1);

        tx.set(workerRef, {'booked': workerBooked}, SetOptions(merge: true));

        tx.set(
          bookingRef,
          {
            'userId': user.uid,
            'userEmail': user.email,
            'userName': user.displayName,
            'phone': phone,
            'note': note,
            'workerId': workerId,
            'workerName': workerName,
            'serviceId': serviceId,
            'serviceName': serviceName,
            'date': _fmtDate(_selectedDate),
            'dateKey': _dateKey(_selectedDate),
            'time': time,
            'bookingKey': k2, // ✅ lưu key mới làm chuẩn
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      _snack("Đặt lịch thành công: $serviceName • $workerName • $time (${_fmtDate(_selectedDate)})");

      setState(() {
        _selectedTime = null;
        _noteCtl.clear();
      });
    } catch (e) {
      final msg = e.toString().contains("SLOT_ALREADY_BOOKED")
          ? "Khung giờ này vừa được người khác đặt. Chọn giờ khác nhé."
          : "Đặt lịch thất bại: $e";
      _snack(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ debug xem app đang dùng project nào
    final app = Firebase.app();
    debugPrint("✅ Firebase projectId = ${app.options.projectId}");

    final selectedWorkerId = _selectedWorkerId;
    final workerRef = selectedWorkerId == null
        ? null
        : FirebaseFirestore.instance.collection('workers').doc(selectedWorkerId);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== HEADER =====
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff721c80),
                      Color.fromARGB(255, 196, 103, 169),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 34, left: 18, right: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Đặt lịch hẹn",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                "Ngày: ${_fmtDate(_selectedDate)}",
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Chọn dịch vụ, chọn chuyên viên, chọn giờ trống và xác nhận.",
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== SERVICES =====
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  "Dịch vụ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('services').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text("Firestore error: ${snapshot.error}"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text("Không có document nào trong collection: services."),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: List.generate(docs.length, (i) {
                        final doc = docs[i];
                        final data = doc.data() as Map<String, dynamic>? ?? {};

                        final id = doc.id;
                        final name = (data['name'] ?? 'Dịch vụ').toString();
                        final desc = (data['desc'] ?? '').toString();
                        final imageUrl = (data['imageUrl'] ?? data['img'] ?? '').toString();

                        final priceRaw = data['price'] ?? 0;
                        final durationRaw = data['duration'] ?? 0;

                        final price = (priceRaw is num) ? priceRaw : (num.tryParse("$priceRaw") ?? 0);
                        final duration = (durationRaw is num)
                            ? durationRaw.toInt()
                            : (int.tryParse("$durationRaw") ?? 0);

                        final isSelected = id == _selectedServiceId;

                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedServiceId = id;
                            _selectedTime = null; // đổi dịch vụ => reset giờ
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0x11721c80) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xff721c80) : Colors.black12,
                                width: isSelected ? 1.2 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                  color: Color(0x14000000),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.black12,
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(imageUrl, fit: BoxFit.cover)
                                        : const Icon(Icons.content_cut, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _formatVnd(price),
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "$duration phút",
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                      if (desc.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          desc,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                                  color: isSelected ? const Color(0xff721c80) : Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // ===== WORKERS (NEW) =====
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  "Chuyên viên thực hiện",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('workers').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text("Worker Firestore error: ${snapshot.error}"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text("Chưa có chuyên viên trong collection: workers."),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: List.generate(docs.length, (i) {
                        final doc = docs[i];
                        final data = doc.data() as Map<String, dynamic>? ?? {};

                        final id = doc.id;
                        final name = (data['name'] ?? 'Chuyên viên').toString();
                        final title = (data['title'] ?? data['jobTitle'] ?? '').toString();
                        final img = (data['img'] ?? data['imageUrl'] ?? '').toString().trim();

                        final isSelected = id == _selectedWorkerId;

                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedWorkerId = id;
                            _selectedTime = null; // đổi worker => reset giờ
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0x11721c80) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xff721c80) : Colors.black12,
                                width: isSelected ? 1.2 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                  color: Color(0x14000000),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.black12,
                                    child: img.isNotEmpty
                                        ? Image.network(img, fit: BoxFit.cover)
                                        : const Icon(Icons.person, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                      if (title.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                                  color: isSelected ? const Color(0xff721c80) : Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // ===== TIME SLOTS (worker busy + past time disabled) =====
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  "Khung giờ trống",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              if (workerRef == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _timeSlots.map((t) {
                      final inPast = _isSlotInPast(_selectedDate, t);
                      return InkWell(
                        onTap: () => _snack("Vui lòng chọn chuyên viên trước."),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: inPast ? Colors.black26 : Colors.black38,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                StreamBuilder<DocumentSnapshot>(
                  stream: workerRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text("Worker Firestore error: ${snapshot.error}"),
                      );
                    }

                    final wdata = snapshot.data?.data() as Map<String, dynamic>?;
                    final bookedKeys = List<dynamic>.from(wdata?['booked'] ?? []);

                    final canPick = _selectedServiceId != null && _selectedWorkerId != null;
                    final serviceId = _selectedServiceId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _timeSlots.map((t) {
                          final inPast = _isSlotInPast(_selectedDate, t);

                          final isBooked = (canPick && serviceId != null)
                              ? _isBooked(bookedKeys: bookedKeys, time: t, serviceId: serviceId)
                              : false;

                          final isSelected = _selectedTime == t;

                          final disabled = !canPick || inPast || isBooked;

                          return InkWell(
                            onTap: () {
                              if (!canPick) {
                                _snack("Vui lòng chọn dịch vụ và chuyên viên trước.");
                                return;
                              }
                              if (inPast) {
                                _snack("Không thể chọn giờ trong quá khứ.");
                                return;
                              }
                              if (isBooked) {
                                _snack("Chuyên viên bận giờ này, chọn giờ khác nhé.");
                                return;
                              }
                              setState(() => _selectedTime = t);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: !canPick
                                    ? Colors.black12
                                    : (disabled
                                    ? Colors.black12
                                    : (isSelected ? const Color(0xff721c80) : Colors.white)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  color: !canPick
                                      ? Colors.black38
                                      : disabled
                                      ? Colors.black38
                                      : (isSelected ? Colors.white : Colors.black87),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 18),

              // ===== CONTACT INFO =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Thông tin liên hệ",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneCtl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Số điện thoại",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Ghi chú (tuỳ chọn)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ===== CONFIRM BUTTON =====
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('services').snapshots(),
                builder: (context, servicesSnap) {
                  final serviceDocs = servicesSnap.data?.docs ?? const <QueryDocumentSnapshot>[];

                  // lấy worker doc realtime (để check bận đúng worker)
                  if (workerRef == null) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black12,
                            foregroundColor: Colors.black54,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          onPressed: null,
                          child: const Text(
                            "Xác nhận đặt lịch",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<DocumentSnapshot>(
                    stream: workerRef.snapshots(),
                    builder: (context, workerSnap) {
                      final wdata = workerSnap.data?.data() as Map<String, dynamic>?;
                      final bookedKeys = List<dynamic>.from(wdata?['booked'] ?? []);

                      final enabled = serviceDocs.isNotEmpty &&
                          _selectedServiceId != null &&
                          _selectedWorkerId != null &&
                          _selectedTime != null &&
                          !_isSlotInPast(_selectedDate, _selectedTime!);

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: enabled ? const Color(0xff721c80) : Colors.black12,
                              foregroundColor: enabled ? Colors.white : Colors.black54,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: enabled ? 2 : 0,
                            ),
                            onPressed: enabled
                                ? () => _book(
                              serviceDocs: serviceDocs,
                              bookedKeys: bookedKeys,
                              workerData: wdata,
                            )
                                : null,
                            child: const Text(
                              "Xác nhận đặt lịch",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
