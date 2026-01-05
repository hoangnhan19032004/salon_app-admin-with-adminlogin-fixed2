import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Chiều cao list dịch vụ (tăng để hết overflow)
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
                      const SalonSearchBarWidget(),
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
                      onSeeAll: () {},
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('services')
                          .snapshots(),
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

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(14),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        // Nếu Firestore rỗng -> show sample cho đẹp
                        if (docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              height: _serviceListHeight, // ✅ 210
                              child: ListView.separated(
                                padding: const EdgeInsets.only(
                                  left: 18,
                                  right: 18,
                                  bottom: 6,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: kSampleServices.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final item = kSampleServices[index];
                                  return ServiceCard.fromLocal(
                                    name: item["name"]!,
                                    img: item["img"]!,
                                    price: int.tryParse(item["price"] ?? ""),
                                    duration:
                                    int.tryParse(item["duration"] ?? ""),
                                    onTap: () {},
                                    onBook: onGoBooking, // ✅ Đặt lịch
                                    maxHeight:
                                    _serviceListHeight, // ✅ chống overflow
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: _serviceListHeight, // ✅ 210
                          child: ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 18,
                              right: 18,
                              bottom: 6,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return ServiceCard(
                                e: docs[index]
                                as QueryDocumentSnapshot<Object?>,
                                onTap: () {},
                                onBook: onGoBooking, // ✅ Đặt lịch
                                maxHeight:
                                _serviceListHeight, // ✅ chống overflow
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
                      onSeeAll: () {},
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('workers')
                          .snapshots(),
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

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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

                        // ✅ cho dư chiều cao chút để tránh “đụng trần”
                        return SizedBox(
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final data = (docs[index].data()
                              as Map<String, dynamic>?) ??
                                  {};
                              final img = (data["img"] as String?)?.trim() ?? "";
                              final name =
                                  (data["name"] as String?)?.trim() ?? "No name";
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

/// Search bar
class SalonSearchBarWidget extends StatelessWidget {
  const SalonSearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          InkWell(
            onTap: () {},
            child: const Icon(
              CupertinoIcons.slider_horizontal_3,
              color: HomeScreen._primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header
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

/// Dịch vụ card
class ServiceCard extends StatelessWidget {
  final QueryDocumentSnapshot<Object?>? e;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  /// ✅ chiều cao tối đa của item trong list (để không bao giờ overflow)
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

    final rawImg = ((data["img"] ?? data["imageUrl"]) as String?)?.trim() ?? "";
    final isFirebaseStorage =
        rawImg.contains('firebasestorage.googleapis.com') ||
            rawImg.contains('storage.googleapis.com');

    final img = isFirebaseStorage ? rawImg : pickDefaultServiceImage(name);

    final price =
    (data["price"] is num) ? (data["price"] as num).toInt() : _localPrice;

    final priceText = price != null
        ? NumberFormat.decimalPattern('vi_VN').format(price)
        : null;

    void goBooking() {
      if (onBook != null) {
        onBook!();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chưa cấu hình điều hướng Đặt lịch.")),
      );
    }

    // ✅ cardHeight: thấp hơn maxHeight để còn “thở” (hết overflow)
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
                // ✅ giảm nhẹ ảnh để dư chỗ phần chip
                SizedBox(
                  height: 104,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (img.isNotEmpty)
                        Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey, size: 34),
                          ),
                          loadingBuilder: (context, child, prog) {
                            if (prog == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                  CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 34),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.55),
                              ],
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

                // ✅ giảm padding + chip nhỏ lại => hết overflow
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

/// Chip info (có thể bấm)
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoChip({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // ✅ nhỏ
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

/// Worker card
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
            if (img.isNotEmpty)
              Image.network(
                img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image,
                      color: Colors.grey, size: 36),
                ),
                loadingBuilder: (context, child, prog) {
                  if (prog == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              )
            else
              Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported,
                    color: Colors.grey, size: 36),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
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

/// Ảnh mặc định ổn định (không bị Too Many Requests)
String pickDefaultServiceImage(String name) {
  final n = name.toLowerCase();

  if (n.contains('cắt') || n.contains('cat') || n.contains('haircut')) {
    return 'https://picsum.photos/seed/haircut/800/500';
  }
  if (n.contains('nhuộm') || n.contains('nhuom') || n.contains('dye')) {
    return 'https://picsum.photos/seed/hairdye/800/500';
  }
  if (n.contains('uốn') ||
      n.contains('uon') ||
      n.contains('perm') ||
      n.contains('curl')) {
    return 'https://picsum.photos/seed/hairperm/800/500';
  }
  if (n.contains('duỗi') ||
      n.contains('duoi') ||
      n.contains('keratin') ||
      n.contains('straight')) {
    return 'https://picsum.photos/seed/hairstraight/800/500';
  }
  if (n.contains('gội') ||
      n.contains('goi') ||
      n.contains('wash') ||
      n.contains('shampoo')) {
    return 'https://picsum.photos/seed/hairwash/800/500';
  }
  if (n.contains('tạo kiểu') ||
      n.contains('tao kieu') ||
      n.contains('styling')) {
    return 'https://picsum.photos/seed/hairstyle/800/500';
  }

  return 'https://picsum.photos/seed/salon/800/500';
}

/// Sample services (khi Firestore chưa có)
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
