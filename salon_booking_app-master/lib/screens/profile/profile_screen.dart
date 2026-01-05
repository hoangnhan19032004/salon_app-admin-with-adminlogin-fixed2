import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:salon_app/screens/promotions/promotions_screen.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/widgets/horizontal_line.dart';
import 'package:salon_app/screens/profile/edit_profile_screen.dart'; // ✅ tạo file này
import 'package:salon_app/screens/booking/booking_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatDob(dynamic dob) {
    if (dob is Timestamp) {
      final d = dob.toDate();
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    }
    return "Chưa cập nhật";
  }

  Future<void> _openEdit(BuildContext context) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );

    if (changed == true) {
      // ✅ reload lại Firebase user (để lấy displayName mới)
      await FirebaseAuth.instance.currentUser?.reload();
      final fresh = FirebaseAuth.instance.currentUser;

      if (!context.mounted) return;

      // ✅ cập nhật lại Provider để UI đổi ngay
      Provider.of<UserProvider>(context, listen: false).setUser(fresh);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã cập nhật hồ sơ")),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có muốn đăng xuất để đổi tài khoản không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      userProvider.clearUser();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đăng xuất thất bại: $e")),
        );
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ listen: true để khi setUser() thì UI đổi theo
    final user = context.watch<UserProvider>().getUser();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Hồ sơ của tôi",
          style: TextStyle(
            color: Color(0xff721c80),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Color(0xff721c80)),
            label: const Text(
              "Đăng xuất",
              style: TextStyle(
                color: Color(0xff721c80),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HorizontalLine(),
              const SizedBox(height: 20),

              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[200],
                    foregroundImage: (user?.photoURL != null)
                        ? NetworkImage(user!.photoURL.toString())
                        : null,
                    child: (user?.photoURL == null)
                        ? const Icon(Icons.person, size: 30, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (user?.displayName ?? "Chưa có tên").toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (user?.email ?? "Chưa có email").toString(),
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        // ✅ SĐT + Ngày sinh từ Firestore
                        if (user != null) ...[
                          const SizedBox(height: 8),
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots(),
                            builder: (context, snap) {
                              final data = snap.data?.data();

                              final phone =
                              (data?['phone'] ?? "Chưa cập nhật").toString();
                              final dobText = _formatDob(data?['dob']);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SĐT: $phone",
                                    style: TextStyle(
                                      color: Colors.grey.withOpacity(0.85),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Ngày sinh: $dobText",
                                    style: TextStyle(
                                      color: Colors.grey.withOpacity(0.85),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SectionCard(
                header: "Lịch hẹn của tôi",
                desc: "Xem lịch hẹn đã đặt / sắp tới",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingScreen()),
                  );
                },
              ),
              SectionCard(
                header: "Thông tin liên hệ",
                desc: "Cập nhật thông tin để salon liên hệ dễ hơn",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
              SectionCard(
                header: "Phương thức thanh toán",
                desc: "Thêm thẻ / liên kết ví để thanh toán nhanh",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _SimplePlaceholderPage(
                        title: "Phương thức thanh toán",
                        subtitle: "Chức năng này sẽ được cập nhật trong phiên bản tiếp theo.",
                      ),
                    ),
                  );
                },
              ),
              SectionCard(
                header: "Thông Báo",
                desc: "Khuyến mãi & ưu đãi dành cho bạn",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PromotionsScreen()),
                  );
                },
              ),

              SectionCard(
                header: "Đánh giá của tôi",
                desc: "Đánh giá dịch vụ & chuyên viên",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _SimplePlaceholderPage(
                        title: "Đánh giá của tôi",
                        subtitle: "Chức năng này sẽ được cập nhật trong phiên bản tiếp theo.",
                      ),
                    ),
                  );
                },
              ),
              SectionCard(
                header: "Cài đặt",
                desc: " Chính sách bảo mật, quyền riêng tư",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _SimplePlaceholderPage(
                        title: "Cài đặt",
                        subtitle: "Chức năng này sẽ được cập nhật trong phiên bản tiếp theo.",
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),


              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Color(0xff721c80)),
                  label: const Text(
                    "Đăng xuất",
                    style: TextStyle(
                      color: Color(0xff721c80),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xff721c80)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String header;
  final String desc;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.header,
    required this.desc,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    header,
                    style: const TextStyle(
                      color: Color(0xff721c80),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                if (canTap)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(color: Colors.grey.withOpacity(0.85)),
            ),
            const SizedBox(height: 12),
            const HorizontalLine(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SimplePlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SimplePlaceholderPage({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          subtitle,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

