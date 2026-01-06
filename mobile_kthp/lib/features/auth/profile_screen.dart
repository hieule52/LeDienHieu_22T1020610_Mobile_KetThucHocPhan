import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_info_page.dart';
import 'account_settings_page.dart';

import 'login_screen.dart';
import 'controllers/auth_controller.dart';

import '../products/pages/product_list_page.dart';
import '../products/widgets/bottom_nav.dart';
import '../orders/pages/order_history_page.dart';
import '../cart/pages/cart_page.dart';
import '../cart/controllers/cart_controller.dart';
import '../chat/pages/chat_list_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool loading = true;
  String? error;

  int _tabIndex = 3;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> _onBottomTap(int i) async {
    if (i == 3) return; // Already on Profile

    // For any other tab (Home, Live, Notifications),
    // navigate back to ProductListPage with the selected index.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ProductListPage(initialIndex: i)),
      (route) => false,
    );
  }

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      _goHome();
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("https://dummyjson.com/auth/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          user = jsonDecode(res.body) as Map<String, dynamic>;
          loading = false;
        });
        return;
      }

      if (res.statusCode == 401) {
        await prefs.remove("token");
        if (mounted) {
          await context.read<AuthController>().logout();
        }
        if (!mounted) return;
        _goHome();
        return;
      }

      setState(() {
        loading = false;
        error = "Lỗi tải hồ sơ (HTTP ${res.statusCode})";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = "Không thể kết nối server";
      });
    }
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ProductListPage()),
      (route) => false,
    );
  }

  void _navToOrders(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderHistoryPage(initialIndex: index)),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (mounted) {
      await context.read<AuthController>().logout();
    }
    if (!mounted) return;
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    // Custom header design requires no default AppBar or a transparent one
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: ShopeeBottomNav(
        currentIndex: _tabIndex,
        notifyBadge: 0,
        onTap: (i) => _onBottomTap(i),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
          ? _ErrorView(message: error!, onRetry: loadProfile)
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildOrderSection(),
          const SizedBox(height: 10),
          _buildWalletSection(),
          const SizedBox(height: 10),
          _buildFinancialSection(),
          const SizedBox(height: 10),
          _buildSupportSection(),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: logout,
              child: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final u = user!;
    final fullName = "${u["firstName"] ?? ""} ${u["lastName"] ?? ""}".trim();
    final username = (u["username"] ?? "user").toString();
    final avatar = u["image"]?.toString();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserInfoPage()),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B14F), // Green
              Color(0xFF00C853), // Lighter Green
            ],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 20,
          left: 16,
          right: 16,
        ),
        child: Column(
          children: [
            // Top Icons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsPage(),
                      ),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 24),
                Consumer<CartController>(
                  builder: (context, cart, child) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartPage(),
                              ),
                            );
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        if (cart.totalQty > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                cart.totalQty > 99 ? '99+' : '${cart.totalQty}',
                                style: const TextStyle(
                                  color: Color(0xFF00B14F),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 24),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatListPage(),
                          ),
                        );
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            // Avatar Row
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: (avatar != null && avatar.isNotEmpty)
                      ? NetworkImage(avatar)
                      : null,
                  backgroundColor: Colors.white24,
                  child: (avatar == null || avatar.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            username.isNotEmpty ? username : fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Bạc',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Text(
                            '28 Đang theo dõi',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '0 Người theo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // VIP Banner
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAA520),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Nhận Voucher giảm 20% mỗi ngày',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đơn mua',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                GestureDetector(
                  onTap: () => _navToOrders(0),
                  child: const Row(
                    children: [
                      Text(
                        'Xem lịch sử mua hàng',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderIcon(
                Icons.account_balance_wallet_outlined,
                'Chờ xác nhận',
                0,
              ),
              _buildOrderIcon(Icons.inventory_2_outlined, 'Chờ lấy hàng', 1),
              _buildOrderIcon(
                Icons.local_shipping_outlined,
                'Chờ giao hàng',
                2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.black12,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_android,
                  color: Color(0xFF00B14F),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Đơn Nạp điện thoại & Dịch vụ',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const Text(
                  'Giảm 5%',
                  style: TextStyle(color: Color(0xFF00B14F), fontSize: 12),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOrderIcon(
    IconData icon,
    String label,
    int index, {
    String? badge,
  }) {
    return GestureDetector(
      onTap: () => _navToOrders(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Icon(icon, size: 28, color: Colors.black87),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              right: 0,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF00B14F),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiện ích của tôi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUtilityItem(
                Icons.account_balance_wallet_outlined,
                'Ví Pay',
                'Kích hoạt n...',
                highlight: false,
              ),
              _buildUtilityItem(
                Icons.credit_score,
                'PayLater',
                'Kích hoạt nhận\nngay 150.000Đ',
                highlight: true,
              ),
              _buildUtilityItem(
                Icons.monetization_on_outlined,
                'Xu',
                'Nhấn để nhận Xu\nmỗi ngày!',
                highlight: true,
              ),
              _buildUtilityItem(
                Icons.confirmation_number_outlined,
                'Kho Voucher',
                '50+ Voucher',
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dịch vụ tài chính',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Row(
                children: [
                  Text(
                    'Xem thêm',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Colors.black54),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUtilityItem(
                Icons.attach_money,
                'Vay Tiêu Dùng',
                'Miễn lãi kỳ đầu tiên',
                highlight: true,
              ),
              _buildUtilityItem(
                Icons.account_balance,
                'Tài khoản Pay',
                'Gói voucher\n1.000.000Đ',
                highlight: true,
              ),
              _buildUtilityItem(
                Icons.shield_outlined,
                'Bảo hiểm của tôi',
                'Gói Tai nạn MINI miễn\nphí',
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityItem(
    IconData icon,
    String label,
    String subLabel, {
    bool highlight = false,
  }) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(label),
            content: const Text('Tính năng đang được phát triển.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 80,
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: highlight ? const Color(0xFF00B14F) : Colors.black87,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 10,
                color: highlight ? const Color(0xFF00B14F) : Colors.black54,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Hỗ trợ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          _supportItem(Icons.help_outline, 'Trung tâm trợ giúp'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _supportItem(Icons.headset_mic_outlined, 'Trò chuyện'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _supportItem(Icons.article_outlined, 'Blog'),
        ],
      ),
    );
  }

  Widget _supportItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.black54),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: () {},
      minLeadingWidth: 0,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.black45),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEE4D2D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Thử lại"),
            ),
          ],
        ),
      ),
    );
  }
}
