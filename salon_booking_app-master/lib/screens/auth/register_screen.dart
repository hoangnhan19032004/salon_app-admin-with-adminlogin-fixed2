import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/components/bottom_navigationbar.dart';
import 'package:salon_app/controller/auth_controller.dart';
import 'package:salon_app/provider/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();

  bool _hidePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _goHomeWithUser(dynamic user) async {
    if (!mounted) return;

    Provider.of<UserProvider>(context, listen: false).setUser(user);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavigationComponent()),
          (route) => false,
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = AuthController();
      final user = await auth.register(
        name: _nameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        password: _passCtl.text.trim(),
      );

      await _goHomeWithUser(user);
    } catch (e) {
      _snack("Đăng ký thất bại: $e");
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

  String? _validateName(String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return "Vui lòng nhập họ tên";
    if (s.length < 2) return "Họ tên quá ngắn";
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return "Vui lòng nhập email";
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    if (!ok) return "Email không hợp lệ";
    return null;
  }

  String? _validatePassword(String? v) {
    final s = (v ?? "");
    if (s.isEmpty) return "Vui lòng nhập mật khẩu";
    if (s.length < 6) return "Mật khẩu tối thiểu 6 ký tự";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ nền gradient tím giống toàn dự án
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
            child: Column(
              children: [
                // ✅ AppBar custom (nút back + title)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          "Tạo tài khoản",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // cân giữa title
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Column(
                        children: [
                          // ✅ icon
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                            ),
                            child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 38),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "Tạo tài khoản để đặt lịch nhanh hơn",
                            style: TextStyle(color: Colors.white.withOpacity(0.9)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

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
                                    "Thông tin đăng ký",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 14),

                                  // Họ tên
                                  TextFormField(
                                    controller: _nameCtl,
                                    decoration: _inputStyle(
                                      label: "Họ tên",
                                      icon: Icons.badge_outlined,
                                    ),
                                    validator: _validateName,
                                  ),
                                  const SizedBox(height: 12),

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

                                  // Mật khẩu
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

                                  const SizedBox(height: 16),

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
                                      onPressed: _loading ? null : _register,
                                      child: _loading
                                          ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Text(
                                        "Tạo tài khoản",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Đã có tài khoản? "),
                                      TextButton(
                                        onPressed: _loading ? null : () => Navigator.pop(context),
                                        child: const Text("Đăng nhập"),
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
          ),
        ],
      ),
    );
  }
}
