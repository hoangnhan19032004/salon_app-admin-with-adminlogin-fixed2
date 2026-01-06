import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:salon_app/screens/admin/manage_chats_screen.dart';
import 'package:salon_app/screens/admin/manage_promotions_screen.dart';
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
  static const Color _primary = Color(0xff721c80);
  static const Color _primary2 = Color.fromARGB(255, 196, 103, 169);

  Stream<int> _watchCount(String col) {
    return FirebaseFirestore.instance.collection(col).snapshots().map((s) => s.size);
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 420;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ===== Modern AppBar (Sliver) =====
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: const Text(
                "Admin Dashboard",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  tooltip: "Làm mới",
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: "Đăng xuất",
                  onPressed: () => widget.onLogout?.call(),
                  icon: const Icon(Icons.logout_rounded),
                ),
                const SizedBox(width: 6),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: const Color(0x11000000)),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Hero Header Card =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, _primary2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Xin chào Admin 👋",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Theo dõi số liệu & quản lý dữ liệu nhanh chóng.",
                                  style: TextStyle(color: Color(0xEEFFFFFF), height: 1.2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Stats title row =====
                    Row(
                      children: [
                        const Text(
                          "Thống kê nhanh",
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _primary.withOpacity(0.18)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 16, color: _primary),
                              SizedBox(width: 6),
                              Text(
                                "Realtime",
                                style: TextStyle(color: _primary, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ===== Stats grid =====
                    LayoutBuilder(
                      builder: (context, c) {
                        final crossAxisCount = isSmall ? 2 : 3;

                        // ✅ thêm 1 item => tổng 6 item (đẹp hơn)
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.42,
                          children: [
                            _ModernStatCard(
                              title: "Dịch vụ",
                              icon: Icons.content_cut_rounded,
                              primary: _primary,
                              stream: _watchCount("services"),
                            ),
                            _ModernStatCard(
                              title: "Lịch hẹn",
                              icon: Icons.event_available_rounded,
                              primary: _primary,
                              stream: _watchCount("bookings"),
                            ),
                            _ModernStatCard(
                              title: "Chuyên viên",
                              icon: Icons.people_alt_rounded,
                              primary: _primary,
                              stream: _watchCount("workers"),
                            ),
                            _ModernStatCard(
                              title: "Người dùng",
                              icon: Icons.person_rounded,
                              primary: _primary,
                              stream: _watchCount("users"),
                            ),
                            _ModernStatCard(
                              title: "Hỗ trợ chat",
                              icon: Icons.chat_bubble_outline_rounded,
                              primary: _primary,
                              stream: _watchCount("support_chats"),
                            ),

                            // ✅ THỐNG KÊ ƯU ĐÃI (collection promotions)
                            _ModernStatCard(
                              title: "Ưu đãi",
                              icon: Icons.local_offer_rounded,
                              primary: _primary,
                              stream: _watchCount("promotions"), // <-- đổi nếu collection khác
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // ===== Actions =====
                    const Text(
                      "Chức năng quản trị",
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),

                    // Action grid (đẹp, hiện đại)
                    LayoutBuilder(
                      builder: (context, c) {
                        final crossAxisCount = isSmall ? 2 : 3;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.15,
                          children: [
                            _ActionCard(
                              title: "Dịch vụ",
                              subtitle: "Thêm / sửa / xóa",
                              icon: Icons.content_cut_rounded,
                              color: _primary,
                              onTap: () => _go(context, const ManageServicesScreen()),
                            ),
                            _ActionCard(
                              title: "Lịch hẹn",
                              subtitle: "Duyệt / trạng thái",
                              icon: Icons.event_note_rounded,
                              color: _primary,
                              onTap: () => _go(context, const ManageBookingsScreen()),
                            ),
                            _ActionCard(
                              title: "Chuyên viên",
                              subtitle: "Thêm / sửa / xóa",
                              icon: Icons.people_alt_rounded,
                              color: _primary,
                              onTap: () => _go(context, const ManageWorkersScreen()),
                            ),
                            _ActionCard(
                              title: "Người dùng",
                              subtitle: "Role / hồ sơ",
                              icon: Icons.manage_accounts_rounded,
                              color: _primary,
                              onTap: () => _go(context, const ManageUsersScreen()),
                            ),
                            _ActionCard(
                              title: "Chat hỗ trợ",
                              subtitle: "Trả lời khách",
                              icon: Icons.chat_rounded,
                              color: _primary,
                              onTap: () => _go(context, const ManageChatsScreen()),
                            ),
                            _ActionCard(
                              title: "Ưu đãi",
                              subtitle: "Thông báo KM",
                              icon: Icons.campaign_rounded,
                              color: _primary,
                              onTap: () => _go(context, const ManagePromotionsScreen()),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // ===== Logout button =====
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onLogout?.call(),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          "Đăng xuất",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: BorderSide(color: _primary.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Modern Stat Card =====
class _ModernStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primary;
  final Stream<int> stream;

  const _ModernStatCard({
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withOpacity(0.18), primary.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withOpacity(0.14)),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StreamBuilder<int>(
              stream: stream,
              builder: (context, snap) {
                final v = snap.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.8,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (v == null)
                      Container(
                        height: 18,
                        width: 56,
                        decoration: BoxDecoration(
                          color: const Color(0x11000000),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                    else
                      Text(
                        v.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
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

/// ===== Action Card (Dashboard style) =====
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x11000000)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, height: 1.15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
