import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();

  DateTime? _dob;
  bool _loading = false;

  User get _user => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

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

  Future<void> _loadProfile() async {
    try {
      // 1) lấy tên từ FirebaseAuth
      _nameCtl.text = _user.displayName ?? "";

      // 2) lấy các field khác từ Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
      final data = doc.data();

      if (data != null) {
        _phoneCtl.text = (data['phone'] ?? "").toString();
        final dob = data['dob'];
        if (dob is Timestamp) _dob = dob.toDate();
      }
    } catch (e) {
      _snack("Không tải được hồ sơ: $e");
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final name = _nameCtl.text.trim();
      final phone = _phoneCtl.text.trim();

      // A) Update tên trên FirebaseAuth
      await _user.updateDisplayName(name);
      await _user.reload();

      // B) Lưu thêm info vào Firestore
      await FirebaseFirestore.instance.collection('users').doc(_user.uid).set(
        {
          'fullName': name,
          'phone': phone,
          'dob': _dob == null ? null : Timestamp.fromDate(_dob!),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      _snack("Cập nhật hồ sơ thành công");
      Navigator.pop(context, true); // trả về true để profile refresh
    } catch (e) {
      _snack("Cập nhật thất bại: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ nền gradient đồng bộ dự án
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
                // ✅ AppBar custom (back + title)
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
                          "Chỉnh sửa hồ sơ",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      children: [
                        // ✅ Avatar “fake” (sau này bạn có thể thay bằng ảnh thật)
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _user.email ?? "",
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 16),

                        // ✅ Card Form
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
                                  "Thông tin cá nhân",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 14),

                                // Họ tên
                                TextFormField(
                                  controller: _nameCtl,
                                  decoration: _inputStyle(
                                    label: "Họ và tên",
                                    icon: Icons.badge_outlined,
                                  ),
                                  validator: (v) {
                                    final s = (v ?? "").trim();
                                    if (s.isEmpty) return "Vui lòng nhập họ tên";
                                    if (s.length < 2) return "Họ tên quá ngắn";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Phone
                                TextFormField(
                                  controller: _phoneCtl,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputStyle(
                                    label: "Số điện thoại",
                                    icon: Icons.phone_outlined,
                                  ),
                                  validator: (v) {
                                    final s = (v ?? "").trim();
                                    if (s.isEmpty) return null; // cho phép trống
                                    if (!RegExp(r'^0\d{9}$').hasMatch(s)) {
                                      return "SĐT phải 10 số và bắt đầu bằng 0";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // DOB picker
                                InkWell(
                                  onTap: _loading ? null : _pickDob,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0x0A000000),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0x1A000000)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cake_outlined),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _dob == null ? "Chưa chọn ngày sinh" : "Ngày sinh: ${_fmtDate(_dob!)}",
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const Icon(Icons.edit_calendar_outlined),
                                      ],
                                    ),
                                  ),
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
                                    onPressed: _loading ? null : _save,
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
                                      "Lưu thay đổi",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
