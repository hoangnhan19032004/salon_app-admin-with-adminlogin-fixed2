import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/components/bottom_navigationbar.dart';
import 'package:salon_app/components/admin_bottom_navigationbar.dart';
import 'package:salon_app/controller/auth_controller.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();

  bool _hidePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _goHomeWithUser(dynamic user) async {
    if (!mounted) return;

    final p = Provider.of<UserProvider>(context, listen: false);
    p.setUser(user);
    p.setAdmin(false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavigationComponent()),
      (route) => false,
    );
  }

  Future<void> _goHomeAdmin({dynamic user}) async {
    if (!mounted) return;

    final p = Provider.of<UserProvider>(context, listen: false);
    p.setUser(user);
    p.setAdmin(true);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminBottomNavigationComponent()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtl.text.trim();
    final pass = _passCtl.text.trim();

    setState(() => _loading = true);
    try {
      final auth = AuthController();
      final user = await auth.login(
        email: email,
        password: pass,
      );

      if (user == null) throw Exception("USER_NULL");

      // ✅ Nếu user có role=admin trong Firestore -> vào trang admin
      final role = await auth.getUserRole(user.uid);
      if (role.toLowerCase() == "admin") {
        await _goHomeAdmin(user: user);
      } else {
        await _goHomeWithUser(user);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thất bại: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return "Vui lòng nhập email";
    // Cho phép admin demo đăng nhập bằng chữ "admin"
    if (v.toLowerCase() == "admin") return null;

    // Validate email cơ bản
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(v)) return "Email không hợp lệ";
    return null;
  }

  String? _validatePassword(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return "Vui lòng nhập mật khẩu";
    // Cho phép admin demo mật khẩu = "admin"
    if (v == "admin") return null;

    if (v.length < 6) return "Mật khẩu tối thiểu 6 ký tự";
    return null;
  }

  Future<void> _loginGoogle() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final auth = AuthController();
      final user = await auth.signInWithGoogle(context: context);
      if (user == null) return;

      final role = await auth.getUserRole(user.uid);
      if (role.toLowerCase() == "admin") {
        await _goHomeAdmin(user: user);
      } else {
        await _goHomeWithUser(user);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập Google thất bại: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputStyle({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x1A000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff721c80), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ nền gradient giống style salon
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff721c80),
                  Color.fromARGB(255, 196, 103, 169),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  children: [
                    // ✅ logo/tiêu đề
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: const Icon(Icons.content_cut, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Salon Booking",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Đăng nhập để đặt lịch nhanh hơn",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ✅ Card form
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 18,
                            offset: Offset(0, 8),
                            color: Color(0x22000000),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Đăng nhập",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 14),

                            // Email
                            TextFormField(
                              controller: _emailCtl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputStyle(
                                label: "Email",
                                icon: Icons.email_outlined,
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              controller: _passCtl,
                              obscureText: _hidePass,
                              decoration: _inputStyle(
                                label: "Mật khẩu",
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  onPressed: () => setState(() => _hidePass = !_hidePass),
                                  icon: Icon(_hidePass ? Icons.visibility : Icons.visibility_off),
                                ),
                              ),
                              validator: _validatePassword,
                            ),

                            const SizedBox(height: 10),

                            // Quên mật khẩu (tạm)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Chức năng quên mật khẩu sẽ bổ sung sau.")),
                                  );
                                },
                                child: const Text("Quên mật khẩu?"),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Login button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff721c80),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 1.5,
                                ),
                                onPressed: _loading ? null : _login,
                                child: _loading
                                    ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                                    : const Text(
                                  "Đăng nhập",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.black.withOpacity(0.12))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text("HOẶC"),
                                ),
                                Expanded(child: Divider(color: Colors.black.withOpacity(0.12))),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Google sign in
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  side: BorderSide(color: Colors.black.withOpacity(0.15)),
                                ),
                                onPressed: _loading ? null : _loginGoogle,
                                icon: const Icon(Icons.g_mobiledata, size: 28),
                                label: const Text(
                                  "Đăng nhập với Google",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Go to register
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Chưa có tài khoản? "),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                    );
                                  },
                                  child: const Text("Đăng ký"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      "© ${DateTime.now().year} Salon Booking",
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
