import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:intl/intl.dart';
import 'package:salon_app/components/carousel.dart';

class HomeScreen extends StatelessWidget {
  /// Callback để điều hướng sang tab "Đặt lịch"
  final VoidCallback? onGoBooking;

  const HomeScreen({super.key, this.onGoBooking});

  static const Color _primary = Color(0xff721c80);
  static const Color _primary2 = Color.fromARGB(255, 196, 103, 169);

  // Chiều cao list dịch vụ
  static const double _serviceListHeight = 210;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffaf7fb),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // =========================
              // HEADER + SEARCH
              // =========================
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primary, _primary2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(42),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            CupertinoIcons.location_solid,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "TP. Hồ Chí Minh, VN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            CupertinoIcons.person_alt_circle_fill,
                            color: Colors.white,
                            size: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Bạn muốn làm đẹp hôm nay?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ SEARCH HOẠT ĐỘNG THẬT
                      SalonSearchBarWidget(onGoBooking: onGoBooking),
                    ],
                  ),
                ),
              ),

              // =========================
              // CAROUSEL
              // =========================
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Carousel(onGoBooking: onGoBooking),
              ),

              // =========================
              // SERVICES
              // =========================
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    SectionHeader(
                      title: "Dịch vụ nổi bật",
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllServicesScreen(onGoBooking: onGoBooking),
                          ),
                        );
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('services').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              "Lỗi tải danh sách dịch vụ.",
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(14),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        // Nếu Firestore rỗng -> show sample
                        if (docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              height: _serviceListHeight,
                              child: ListView.separated(
                                padding: const EdgeInsets.only(
                                  left: 18,
                                  right: 18,
                                  bottom: 6,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: kSampleServices.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final item = kSampleServices[index];
                                  return ServiceCard.fromLocal(
                                    name: item["name"]!,
                                    img: item["img"]!,
                                    price: int.tryParse(item["price"] ?? ""),
                                    duration: int.tryParse(item["duration"] ?? ""),
                                    onTap: () {},
                                    onBook: onGoBooking,
                                    maxHeight: _serviceListHeight,
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: _serviceListHeight,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 18,
                              right: 18,
                              bottom: 6,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return ServiceCard(
                                e: docs[index] as QueryDocumentSnapshot<Object?>,
                                onTap: () {},
                                onBook: onGoBooking,
                                maxHeight: _serviceListHeight,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // =========================
              // WORKERS
              // =========================
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, top: 14),
                child: Column(
                  children: [
                    SectionHeader(
                      title: "Chuyên viên nổi bật",
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AllWorkersScreen()),
                        );
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('workers').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              "Lỗi tải danh sách chuyên viên.",
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text("Chưa có chuyên viên nào."),
                          );
                        }

                        return SizedBox(
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final data = (docs[index].data() as Map<String, dynamic>?) ?? {};
                              final img = (data["img"] as String?)?.trim() ??
                                  (data["imageUrl"] as String?)?.trim() ??
                                  "";
                              final name = (data["name"] as String?)?.trim() ?? "No name";
                              return _WorkerCard(img: img, name: name);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                height: 22,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color.fromARGB(255, 220, 218, 218),
                      width: 0.9,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// =========================
/// ✅ MÀN: TẤT CẢ DỊCH VỤ
/// =========================
class AllServicesScreen extends StatefulWidget {
  final VoidCallback? onGoBooking;
  const AllServicesScreen({super.key, this.onGoBooking});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic raw) {
    final n = (raw is num) ? raw.toInt() : int.tryParse("$raw") ?? 0;
    return "${NumberFormat.decimalPattern('vi_VN').format(n)}đ";
  }

  @override
  Widget build(BuildContext context) {
    const primary = HomeScreen._primary;

    return Scaffold(
      backgroundColor: const Color(0xfffaf7fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: const Text("Tất cả dịch vụ", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              controller: _searchCtl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Tìm dịch vụ...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải dịch vụ:\n${snapshot.error}"));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final q = _searchCtl.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((d) {
                  final m = (d.data() as Map<String, dynamic>? ?? {});
                  final name = (m["name"] ?? "").toString().toLowerCase();
                  final desc = (m["desc"] ?? "").toString().toLowerCase();
                  return q.isEmpty || name.contains(q) || desc.contains(q);
                }).toList();

                // sort theo tên
                docs.sort((a, b) {
                  final ma = (a.data() as Map<String, dynamic>? ?? {});
                  final mb = (b.data() as Map<String, dynamic>? ?? {});
                  return (ma["name"] ?? "").toString().toLowerCase().compareTo((mb["name"] ?? "").toString().toLowerCase());
                });

                if (docs.isEmpty) return const Center(child: Text("Không có dịch vụ."));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final doc = docs[i] as QueryDocumentSnapshot<Object?>;
                    final data = (doc.data() as Map<String, dynamic>? ?? {});
                    final name = (data["name"] ?? "Dịch vụ").toString();
                    final desc = (data["desc"] ?? "").toString();
                    final duration = (data["duration"] is num)
                        ? (data["duration"] as num).toInt()
                        : int.tryParse("${data["duration"]}") ?? 0;

                    final rawImg = ((data["imageUrl"] ??
                        data["img"] ??
                        data["imagePath"] ??
                        data["storagePath"]) as String?)
                        ?.trim() ??
                        "";

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 160,
                              width: double.infinity,
                              child: _ServiceImage(
                                raw: rawImg,
                                fallbackUrl: pickDefaultServiceImage(name),
                                width: double.infinity,
                                height: 160,
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _MiniChip(icon: Icons.payments_rounded, text: _formatPrice(data["price"]), color: primary),
                                      const SizedBox(width: 8),
                                      _MiniChip(icon: Icons.timer_rounded, text: "$duration phút", color: primary),
                                    ],
                                  ),
                                  if (desc.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      desc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black54, height: 1.25),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  if (widget.onGoBooking != null)
                                    SizedBox(
                                      height: 44,
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        onPressed: widget.onGoBooking,
                                        icon: const Icon(Icons.calendar_month, color: Colors.white),
                                        label: const Text("Đặt lịch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                ],
                              ),
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

/// =========================
/// ✅ MÀN: TẤT CẢ CHUYÊN VIÊN
/// =========================
class AllWorkersScreen extends StatefulWidget {
  const AllWorkersScreen({super.key});

  @override
  State<AllWorkersScreen> createState() => _AllWorkersScreenState();
}

class _AllWorkersScreenState extends State<AllWorkersScreen> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _openWorker(BuildContext context, Map<String, dynamic> data) async {
    final name = (data["name"] ?? "Chuyên viên").toString();
    final title = (data["title"] ?? data["jobTitle"] ?? "").toString();
    final img = (data["img"] ?? data["imageUrl"] ?? "").toString().trim();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (img.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _AnyImage(
                  raw: img,
                  fallbackUrl: "https://picsum.photos/seed/worker/800/500",
                  width: double.infinity,
                  height: 160,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(title.isEmpty ? "Chưa có mô tả/chức danh." : title),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffaf7fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: const Text("Tất cả chuyên viên", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              controller: _searchCtl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Tìm chuyên viên...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('workers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải chuyên viên:\n${snapshot.error}"));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final q = _searchCtl.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((d) {
                  final m = (d.data() as Map<String, dynamic>? ?? {});
                  final name = (m["name"] ?? "").toString().toLowerCase();
                  final title = (m["title"] ?? m["jobTitle"] ?? "").toString().toLowerCase();
                  return q.isEmpty || name.contains(q) || title.contains(q);
                }).toList();

                docs.sort((a, b) {
                  final ma = (a.data() as Map<String, dynamic>? ?? {});
                  final mb = (b.data() as Map<String, dynamic>? ?? {});
                  return (ma["name"] ?? "").toString().toLowerCase().compareTo((mb["name"] ?? "").toString().toLowerCase());
                });

                if (docs.isEmpty) return const Center(child: Text("Không có chuyên viên."));

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = (docs[i].data() as Map<String, dynamic>? ?? {});
                    final img = (data["img"] ?? data["imageUrl"] ?? "").toString().trim();
                    final name = (data["name"] ?? "No name").toString();
                    final title = (data["title"] ?? data["jobTitle"] ?? "").toString();

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openWorker(context, data),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _AnyImage(
                                      raw: img,
                                      fallbackUrl: "https://picsum.photos/seed/worker$i/800/500",
                                      width: double.infinity,
                                      height: double.infinity,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: 54,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 12,
                                      right: 12,
                                      bottom: 10,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                          ),
                                          if (title.trim().isNotEmpty)
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                child: Row(
                                  children: const [
                                    Text("Xem chi tiết", style: TextStyle(fontWeight: FontWeight.w800)),
                                    Spacer(),
                                    Icon(Icons.chevron_right_rounded, color: Colors.black38),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

/// chip nhỏ dùng cho màn AllServices
class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniChip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// =========================
/// ✅ SEARCH BAR + SEARCH DELEGATE (TÌM THẬT)
/// =========================
enum _SearchFilter { all, services, workers }

class SalonSearchBarWidget extends StatelessWidget {
  final VoidCallback? onGoBooking;

  const SalonSearchBarWidget({super.key, this.onGoBooking});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async {
        await showSearch(
          context: context,
          delegate: _SalonSearchDelegate(onGoBooking: onGoBooking),
        );
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Tìm kiếm dịch vụ, chuyên viên...",
                style: TextStyle(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              CupertinoIcons.slider_horizontal_3,
              color: HomeScreen._primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SalonSearchDelegate extends SearchDelegate<void> {
  final VoidCallback? onGoBooking;

  _SalonSearchDelegate({this.onGoBooking});

  _SearchFilter _filter = _SearchFilter.all;

  late final Future<_SearchCache> _cacheFuture = _loadCache();

  Future<_SearchCache> _loadCache() async {
    final fs = FirebaseFirestore.instance;
    final servicesSnap = await fs.collection('services').get();
    final workersSnap = await fs.collection('workers').get();

    final services = servicesSnap.docs.map((d) {
      final m = (d.data() as Map<String, dynamic>? ?? {});
      return _SearchItem(
        type: _ItemType.service,
        id: d.id,
        name: (m['name'] ?? '').toString(),
        subtitle: (m['desc'] ?? '').toString(),
        imageUrl: ((m['imageUrl'] ?? m['img'] ?? m['imagePath'] ?? m['storagePath']) ?? '').toString(),
        raw: m,
      );
    }).toList();

    final workers = workersSnap.docs.map((d) {
      final m = (d.data() as Map<String, dynamic>? ?? {});
      return _SearchItem(
        type: _ItemType.worker,
        id: d.id,
        name: (m['name'] ?? '').toString(),
        subtitle: (m['title'] ?? m['jobTitle'] ?? '').toString(),
        imageUrl: ((m['img'] ?? m['imageUrl']) ?? '').toString(),
        raw: m,
      );
    }).toList();

    services.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    workers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return _SearchCache(services: services, workers: workers);
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final t = Theme.of(context);
    return t.copyWith(
      appBarTheme: t.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    IconData icon() {
      switch (_filter) {
        case _SearchFilter.all:
          return Icons.filter_alt_outlined;
        case _SearchFilter.services:
          return Icons.content_cut;
        case _SearchFilter.workers:
          return Icons.people_alt_outlined;
      }
    }

    String tip() {
      switch (_filter) {
        case _SearchFilter.all:
          return "Đang lọc: Tất cả";
        case _SearchFilter.services:
          return "Đang lọc: Dịch vụ";
        case _SearchFilter.workers:
          return "Đang lọc: Chuyên viên";
      }
    }

    return [
      IconButton(
        tooltip: tip(),
        icon: Icon(icon()),
        onPressed: () {
          if (_filter == _SearchFilter.all) {
            _filter = _SearchFilter.services;
          } else if (_filter == _SearchFilter.services) {
            _filter = _SearchFilter.workers;
          } else {
            _filter = _SearchFilter.all;
          }
          showSuggestions(context);
        },
      ),
      if (query.isNotEmpty)
        IconButton(
          tooltip: "Xoá",
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = "";
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: "Đóng",
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  List<_SearchItem> _filterItems(_SearchCache cache) {
    final kw = query.trim().toLowerCase();

    List<_SearchItem> src;
    if (_filter == _SearchFilter.services) {
      src = cache.services;
    } else if (_filter == _SearchFilter.workers) {
      src = cache.workers;
    } else {
      src = [...cache.services, ...cache.workers];
    }

    if (kw.isEmpty) return src.take(20).toList();

    final out = src.where((e) {
      return e.name.toLowerCase().contains(kw) || e.subtitle.toLowerCase().contains(kw);
    }).toList();

    return out.take(50).toList();
  }

  Future<void> _openItem(BuildContext context, _SearchItem item) async {
    const primary = HomeScreen._primary;

    if (item.type == _ItemType.service) {
      final priceRaw = item.raw['price'];
      final durationRaw = item.raw['duration'];
      final price = (priceRaw is num) ? priceRaw.toInt() : int.tryParse("$priceRaw") ?? 0;
      final duration = (durationRaw is num) ? durationRaw.toInt() : int.tryParse("$durationRaw") ?? 0;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(item.name.isEmpty ? "Dịch vụ" : item.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _ServiceImage(
                    raw: item.imageUrl,
                    fallbackUrl: pickDefaultServiceImage(item.name),
                    width: double.infinity,
                    height: 160,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(item.subtitle.isEmpty ? "Không có mô tả." : item.subtitle),
              const SizedBox(height: 10),
              Text("Giá: $price đ"),
              Text("Thời lượng: $duration phút"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
            if (onGoBooking != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                onPressed: () {
                  Navigator.pop(context);
                  close(context, null);
                  onGoBooking?.call();
                },
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                label: const Text("Đặt lịch", style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(item.name.isEmpty ? "Chuyên viên" : item.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(item.subtitle.isEmpty ? "Chưa có mô tả/chức danh." : item.subtitle),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildList(BuildContext context, AsyncSnapshot<_SearchCache> snap) {
    if (snap.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("Lỗi tải dữ liệu tìm kiếm:\n${snap.error}"),
        ),
      );
    }
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());

    final items = _filterItems(snap.data!);
    if (items.isEmpty) return const Center(child: Text("Không tìm thấy kết quả."));

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final it = items[i];
        final icon = it.type == _ItemType.service ? Icons.content_cut : Icons.person;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: HomeScreen._primary.withOpacity(0.12),
            child: Icon(icon, color: HomeScreen._primary),
          ),
          title: Text(
            it.name.isEmpty ? (it.type == _ItemType.service ? "Dịch vụ" : "Chuyên viên") : it.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: it.subtitle.trim().isEmpty ? null : Text(it.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openItem(context, it),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<_SearchCache>(future: _cacheFuture, builder: _buildList);
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<_SearchCache>(future: _cacheFuture, builder: _buildList);
  }
}

enum _ItemType { service, worker }

class _SearchItem {
  final _ItemType type;
  final String id;
  final String name;
  final String subtitle;
  final String imageUrl;
  final Map<String, dynamic> raw;

  _SearchItem({
    required this.type,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.raw,
  });
}

class _SearchCache {
  final List<_SearchItem> services;
  final List<_SearchItem> workers;

  _SearchCache({required this.services, required this.workers});
}

/// =========================
/// SECTION HEADER
/// =========================
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: HomeScreen._primary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text("Xem tất cả", style: TextStyle(color: Colors.grey)),
                SizedBox(width: 4),
                Icon(
                  Icons.double_arrow_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================
/// ✅ ẢNH: URL hoặc STORAGE PATH
/// =========================
class _StorageUrlCache {
  static final Map<String, Future<String>> _cache = {};

  static Future<String> getDownloadUrl(String path) {
    return _cache.putIfAbsent(path, () => FirebaseStorage.instance.ref(path).getDownloadURL());
  }
}

class _AnyImage extends StatelessWidget {
  final String raw;
  final String fallbackUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _AnyImage({
    required this.raw,
    required this.fallbackUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  Widget _img(String url) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 34),
      ),
      loadingBuilder: (context, child, prog) {
        if (prog == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: const Center(
            child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = raw.trim();
    if (v.isEmpty) return ClipRRect(borderRadius: borderRadius, child: _img(fallbackUrl));
    if (v.startsWith("http://") || v.startsWith("https://")) {
      return ClipRRect(borderRadius: borderRadius, child: _img(v));
    }
    // storage path
    return ClipRRect(
      borderRadius: borderRadius,
      child: FutureBuilder<String>(
        future: _StorageUrlCache.getDownloadUrl(v),
        builder: (context, snap) {
          if (snap.hasError) return _img(fallbackUrl);
          if (!snap.hasData) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade100,
              child: const Center(
                child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          return _img(snap.data!);
        },
      ),
    );
  }
}

/// Dành riêng cho services (giữ lại logic fallback theo tên)
class _ServiceImage extends StatelessWidget {
  final String raw; // URL hoặc Storage path
  final String fallbackUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _ServiceImage({
    required this.raw,
    required this.fallbackUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return _AnyImage(
      raw: raw,
      fallbackUrl: fallbackUrl,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// =========================
/// SERVICE CARD
/// =========================
class ServiceCard extends StatelessWidget {
  final QueryDocumentSnapshot<Object?>? e;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final double maxHeight;

  final String? _localName;
  final String? _localImg;
  final int? _localPrice;
  final int? _localDuration;

  const ServiceCard({
    super.key,
    required QueryDocumentSnapshot<Object?> this.e,
    this.onTap,
    this.onBook,
    this.maxHeight = 210,
  })  : _localName = null,
        _localImg = null,
        _localPrice = null,
        _localDuration = null;

  const ServiceCard.fromLocal({
    super.key,
    required String name,
    required String img,
    int? price,
    int? duration,
    this.onTap,
    this.onBook,
    this.maxHeight = 210,
  })  : e = null,
        _localName = name,
        _localImg = img,
        _localPrice = price,
        _localDuration = duration;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = e != null
        ? ((e!.data() as Map<String, dynamic>?) ?? {})
        : <String, dynamic>{
      "name": _localName ?? "",
      "img": _localImg ?? "",
      "price": _localPrice,
      "duration": _localDuration,
    };

    final name = (data["name"] as String?)?.trim() ?? "No name";

    final rawImg = ((data["imageUrl"] ?? data["img"] ?? data["imagePath"] ?? data["storagePath"]) as String?)
        ?.trim() ??
        "";

    final fallback = pickDefaultServiceImage(name);

    final price = (data["price"] is num) ? (data["price"] as num).toInt() : _localPrice;
    final priceText = price != null ? NumberFormat.decimalPattern('vi_VN').format(price) : null;

    void goBooking() {
      if (onBook != null) {
        onBook!();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chưa cấu hình điều hướng Đặt lịch.")),
      );
    }

    final double cardHeight = (maxHeight - 12).clamp(180, 205);

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: 168, height: cardHeight),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 104,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ServiceImage(
                        raw: rawImg,
                        fallbackUrl: fallback,
                        width: double.infinity,
                        height: 104,
                        borderRadius: BorderRadius.zero,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 9,
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (priceText != null)
                        _InfoChip(
                          icon: Icons.payments_rounded,
                          text: "$priceTextđ",
                        ),
                      _InfoChip(
                        icon: Icons.calendar_month_rounded,
                        text: "Đặt lịch",
                        onTap: goBooking,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoChip({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: HomeScreen._primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: HomeScreen._primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: HomeScreen._primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      ),
    );
  }
}

/// =========================
/// WORKER CARD (Home)
/// =========================
class _WorkerCard extends StatelessWidget {
  final String img;
  final String name;

  const _WorkerCard({required this.img, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AnyImage(
              raw: img,
              fallbackUrl: "https://sf-static.upanhlaylink.com/img/image_2026010677648ce1de49c037e55b20573d69de05.jpg",
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                  ),
                ),
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =========================
/// ẢNH MẶC ĐỊNH
/// =========================
String pickDefaultServiceImage(String name) {
  final n = name.toLowerCase();

  if (n.contains('cắt') || n.contains('cat') || n.contains('haircut')) {
    return 'https://sf-static.upanhlaylink.com/img/image_202601066b6fb497c05cfe92e5e78b7759c3d134.jpg';
  }
  if (n.contains('nhuộm') || n.contains('nhuom') || n.contains('dye')) {
    return 'https://sf-static.upanhlaylink.com/img/image_202601061666968712f8657b806067c4c45da111.jpg';
  }
  if (n.contains('uốn') || n.contains('uon') || n.contains('perm') || n.contains('curl')) {
    return 'https://sf-static.upanhlaylink.com/img/image_20260106075d7ab3517b4e8f44c283a054fcb4e9.jpg';
  }
  if (n.contains('duỗi') || n.contains('duoi') || n.contains('keratin') || n.contains('straight')) {
    return 'https://sf-static.upanhlaylink.com/img/image_20260106075d7ab3517b4e8f44c283a054fcb4e9.jpg';
  }
  if (n.contains('gội') || n.contains('goi') || n.contains('wash') || n.contains('shampoo')) {
    return 'https://sf-static.upanhlaylink.com/img/image_20260106075d7ab3517b4e8f44c283a054fcb4e9.jpg';
  }
  if (n.contains('tạo kiểu') || n.contains('tao kieu') || n.contains('styling')) {
    return 'https://sf-static.upanhlaylink.com/img/image_202601065974389bd6e3f7245162219314957759.jpg';
  }

  return 'https://sf-static.upanhlaylink.com/img/image_202601065974389bd6e3f7245162219314957759.jpg';
}

/// =========================
/// SAMPLE SERVICES
/// =========================
const List<Map<String, String>> kSampleServices = [
  {
    "name": "Cắt tóc",
    "img": "https://picsum.photos/seed/haircut/800/500",
    "price": "60000",
    "duration": "30",
  },
  {
    "name": "Nhuộm tóc",
    "img": "https://picsum.photos/seed/hairdye/800/500",
    "price": "250000",
    "duration": "90",
  },
  {
    "name": "Uốn tóc",
    "img": "https://picsum.photos/seed/hairperm/800/500",
    "price": "300000",
    "duration": "120",
  },
  {
    "name": "Gội đầu thư giãn",
    "img": "https://picsum.photos/seed/hairwash/800/500",
    "price": "80000",
    "duration": "25",
  },
];
