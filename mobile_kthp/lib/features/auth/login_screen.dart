import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_screen.dart';
import '../products/pages/product_list_page.dart';
import 'controllers/auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  bool _obscurePassword = true;

  late final AnimationController _successController;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 0.0, // bắt đầu nhỏ
    );

    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOutBack,
    );

    // ✅ chạy animation sau khi frame đầu render -> form hiện ra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _successController.forward(from: 0.0);
    });

    // ✅ nếu đã login thì tự vào profile
    Future.microtask(_autoRouteIfLoggedIn);
  }

  Future<void> _autoRouteIfLoggedIn() async {
    // ✅ Kiểm tra từ AuthController thay vì SharedPreferences trực tiếp
    if (!mounted) return;

    final authController = context.read<AuthController>();
    // ✅ Đợi AuthController load token xong
    while (authController.isLoading && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    if (authController.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username = userCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError("Vui lòng nhập đầy đủ username và password");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse('https://dummyjson.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          // nếu API yêu cầu: 'expiresInMins': 60,
        }),
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // ✅ DummyJSON có thể trả token theo key "token"
        final token = (data['token'] ?? data['accessToken'])?.toString();

        if (token == null || token.isEmpty) {
          _showError("Server không trả về token hợp lệ");
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // ✅ Cập nhật AuthController
        if (mounted) {
          context.read<AuthController>().setToken(token);
        }

        if (!mounted) return;

        // ✅ vào profile
        final canPop = Navigator.canPop(context);

        // ✅ Nếu màn hình này được mở bằng Navigator.push (từ ProductListPage, AddToCart...)
        if (canPop) {
          Navigator.pop(context, true); // trả về true: đăng nhập OK
          return;
        }

        // ✅ nếu không pop được (mở như màn hình gốc) thì mới vào profile
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (_, __, ___) => const ProfileScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
          ),
        );
      } else {
        // đọc message nếu có
        String msg = "Sai username hoặc mật khẩu";
        try {
          final err = jsonDecode(res.body);
          if (err is Map && err['message'] != null)
            msg = err['message'].toString();
        } catch (_) {}
        _showError(msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showError("Không thể kết nối server");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text("Đăng nhập thất bại")),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Primary Color
    const primaryColor = Color(0xFF00B14F);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // 1. Background Header (Green Top)
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00B14F), Color(0xFF00C853)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom AppBar area
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProductListPage(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              'Đăng Nhập',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance for back button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Login Form Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ScaleTransition(
                scale: _successScale,
                child: Column(
                  children: [
                    const SizedBox(height: 80), // Push down to overlap
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Chào mừng trở lại!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Username
                          const Text(
                            'Tên đăng nhập',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: userCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên đăng nhập',
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password
                          const Text(
                            'Mật khẩu',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => loading ? null : login(),
                            decoration: InputDecoration(
                              hintText: 'Nhập mật khẩu',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() {
                                  _obscurePassword = !_obscurePassword;
                                }),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: Color(0xFF007AFF), // Blue link
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: loading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'ĐĂNG NHẬP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Social Login
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Hoặc đăng nhập bằng',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(
                          icon: Icons.g_mobiledata_rounded,
                          color: Colors.red.shade600,
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _SocialButton(
                          icon: Icons.facebook,
                          color: const Color(0xFF1877F2),
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _SocialButton(
                          icon: Icons.apple,
                          color: Colors.black,
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
