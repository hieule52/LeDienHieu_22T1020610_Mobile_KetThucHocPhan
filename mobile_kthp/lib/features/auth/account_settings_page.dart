import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/auth_controller.dart';
import '../products/pages/product_list_page.dart';
import 'user_info_page.dart';
import '../address/pages/address_list_page.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Thiết lập tài khoản',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00B14F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF00B14F),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Tài khoản của tôi'),
            _buildMenuItem(
              context,
              'Tài khoản & Bảo mật',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserInfoPage()),
                );
              },
            ),
            const Divider(height: 1, indent: 16),
            _buildMenuItem(
              context,
              'Địa Chỉ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddressListPage()),
                );
              },
            ),
            const Divider(height: 1, indent: 16),
            _buildMenuItem(context, 'Tài khoản / Thẻ ngân hàng'),

            _buildSectionHeader('Cài đặt'),
            _buildMenuItem(context, 'Cài đặt Chat'),
            const Divider(height: 1, indent: 16),
            _buildMenuItem(context, 'Cài đặt Thông báo'),
            const Divider(height: 1, indent: 16),
            _buildMenuItem(context, 'Cài đặt riêng tư'),
            const Divider(height: 1, indent: 16),
            _buildMenuItem(context, 'Người dùng đã bị chặn'),
            const Divider(height: 1, indent: 16),
            _buildMenuItem(
              context,
              'Ngôn ngữ / Language',
              subtitle: 'Tiếng Việt',
            ),

            // Add some spacing at bottom
            const SizedBox(height: 50),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B14F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => _logout(context),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (context.mounted) {
      // Try/catch in case AuthController is not in tree (though it should be)
      try {
        await context.read<AuthController>().logout();
      } catch (_) {}

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProductListPage()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.black54, fontSize: 14),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap:
            onTap ??
            () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(title),
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
      ),
    );
  }
}
