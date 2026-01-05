import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/screens/admin/admin_home_screen.dart';
import 'package:salon_app/screens/admin/manage_bookings_screen.dart';
import 'package:salon_app/screens/admin/manage_services_screen.dart';
import 'package:salon_app/screens/admin/manage_users_screen.dart';
import 'package:salon_app/screens/admin/manage_workers_screen.dart';
import 'package:salon_app/screens/auth/login_screen.dart';

class AdminBottomNavigationComponent extends StatefulWidget {
  const AdminBottomNavigationComponent({super.key});

  @override
  State<AdminBottomNavigationComponent> createState() =>
      _AdminBottomNavigationComponentState();
}

class _AdminBottomNavigationComponentState
    extends State<AdminBottomNavigationComponent> {
  int _index = 0;

  Future<void> _logout() async {
    if (!mounted) return;

    // Clear local session
    Provider.of<UserProvider>(context, listen: false).clearUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);

    // Chặn nếu không phải admin (tránh truy cập bằng deep link)
    if (!provider.isAdmin) {
      return const LoginScreen();
    }

    final pages = <Widget>[
      AdminHomeScreen(onLogout: _logout),
      const ManageServicesScreen(),
      const ManageBookingsScreen(),
      const ManageWorkersScreen(),
      const ManageUsersScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Tổng quan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut_outlined),
            label: "Dịch vụ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_outlined),
            label: "Lịch hẹn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Chuyên viên",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            label: "Người dùng",
          ),
        ],
      ),
    );
  }
}
