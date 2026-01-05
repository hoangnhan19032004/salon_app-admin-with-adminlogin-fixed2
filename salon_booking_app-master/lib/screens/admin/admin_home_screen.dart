import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:salon_app/screens/admin/manage_chats_screen.dart';
// TODO: sửa đúng đường dẫn theo project của bạn
import 'package:salon_app/screens/admin/manage_services_screen.dart';
import 'package:salon_app/screens/admin/manage_bookings_screen.dart';
import 'package:salon_app/screens/admin/manage_workers_screen.dart';
import 'package:salon_app/screens/admin/manage_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;

  const AdminHomeScreen({super.key, this.onLogout});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Nếu Firestore rules của bạn chặn count bằng aggregation,
  // dùng cách stream "limit(1)" để hiển thị "có dữ liệu" thay vì count chính xác.
  // Nhưng ở đây ta lấy count bằng snapshot.size (đủ nhanh với data vừa).
  Stream<int> _watchCount(String col) {
    return FirebaseFirestore.instance.collection(col).snapshots().map((s) => s.size);
  }

  // Nút điều hướng tiện
  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xff721c80);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            tooltip: "Làm mới",
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Đăng xuất",
            onPressed: () => widget.onLogout?.call(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ===== Header card =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Quản trị hệ thống",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Theo dõi số liệu & quản lý dữ liệu: dịch vụ, lịch hẹn, chuyên viên, người dùng, chat.",
                          style: TextStyle(color: Colors.black54, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Stats =====
            const Text(
              "Thống kê nhanh",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (context, c) {
                final crossAxisCount = c.maxWidth < 420 ? 2 : 3;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _LiveStatCard(
                      title: "Dịch vụ",
                      icon: Icons.content_cut,
                      primary: primary,
                      stream: _watchCount("services"),
                    ),
                    _LiveStatCard(
                      title: "Lịch hẹn",
                      icon: Icons.event_available,
                      primary: primary,
                      stream: _watchCount("bookings"),
                    ),
                    _LiveStatCard(
                      title: "Chuyên viên",
                      icon: Icons.people,
                      primary: primary,
                      stream: _watchCount("workers"),
                    ),
                    _LiveStatCard(
                      title: "Người dùng",
                      icon: Icons.person,
                      primary: primary,
                      stream: _watchCount("users"),
                    ),
                    _LiveStatCard(
                      title: "Hỗ trợ chat",
                      icon: Icons.chat_bubble_outline,
                      primary: primary,
                      stream: _watchCount("support_chats"),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // ===== Quick Actions =====
            Row(
              children: const [
                Text(
                  "Chức năng quản trị",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _ActionTile(
              title: "Quản lý dịch vụ",
              subtitle: "Thêm / sửa / xóa dịch vụ",
              icon: Icons.content_cut,
              color: primary,
              onTap: () => _go(context, const ManageServicesScreen()),
            ),
            const SizedBox(height: 10),

            _ActionTile(
              title: "Quản lý lịch hẹn",
              subtitle: "Xem tất cả booking, đổi trạng thái, xóa",
              icon: Icons.event_note,
              color: primary,
              onTap: () => _go(context, const ManageBookingsScreen()),
            ),
            const SizedBox(height: 10),

            _ActionTile(
              title: "Quản lý chuyên viên",
              subtitle: "Thêm / sửa / xóa chuyên viên",
              icon: Icons.people_alt,
              color: primary,
              onTap: () => _go(context, const ManageWorkersScreen()),
            ),
            const SizedBox(height: 10),

            _ActionTile(
              title: "Quản lý người dùng",
              subtitle: "Xem user, đổi role, kiểm tra hồ sơ",
              icon: Icons.manage_accounts,
              color: primary,
              onTap: () => _go(context, const ManageUsersScreen()),
            ),
            const SizedBox(height: 10),

            _ActionTile(
              title: "Quản lý chat hỗ trợ",
              subtitle: "Xem phòng chat, trả lời khách",
              icon: Icons.chat,
              color: primary,
              onTap: () => _go(context, const ManageChatsScreen()),
            ),

            const SizedBox(height: 18),

            // ===== Tips/Notes =====
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x11000000)),
              ),
              child: const Text(
                "Gợi ý:\n"
                    "- Nếu bạn muốn admin truy cập bằng tài khoản user, hãy set users/{uid}.role = 'admin'.\n"
                    "- Nếu chat không hiển thị, kiểm tra collection support_chats và subcollection messages.\n"
                    "- Nếu lịch hẹn đang hardcode workerId, nên sửa để user chọn chuyên viên (mình có thể sửa luôn).",
                style: TextStyle(color: Colors.black87, height: 1.35),
              ),
            ),

            const SizedBox(height: 12),

            // ===== Logout button =====
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () => widget.onLogout?.call(),
                icon: const Icon(Icons.logout),
                label: const Text("Đăng xuất"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card thống kê realtime, không bị loading xoay liên tục.
/// Có skeleton nhẹ lúc chưa có dữ liệu.
class _LiveStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primary;
  final Stream<int> stream;

  const _LiveStatCard({
    required this.title,
    required this.icon,
    required this.primary,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StreamBuilder<int>(
              stream: stream,
              builder: (context, snap) {
                final value = snap.data;
                // Nếu chưa có data -> show placeholder chứ không xoay
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (value == null)
                      Container(
                        height: 18,
                        width: 56,
                        decoration: BoxDecoration(
                          color: const Color(0x11000000),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    else
                      Text(
                        value.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
