import 'package:flutter/material.dart';

const _kPrimaryColor = Color(0xFF00B14F); // Green
const _kGradientStart = Color(0xFF00B14F);
const _kGradientEnd = Color(0xFF00C853);

class ShopeeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onTapCart;
  final VoidCallback? onTapChat;
  final VoidCallback? onTapSearch;

  final int cartBadge;
  final int chatBadge;

  const ShopeeAppBar({
    super.key,
    required this.controller,
    this.onSubmit,
    this.onTapCart,
    this.onTapChat,
    this.onTapSearch,
    this.cartBadge = 0,
    this.chatBadge = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _kPrimaryColor,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kGradientStart, _kGradientEnd],
          ),
        ),
      ),
      elevation: 0,
      titleSpacing: 10,
      title: Row(
        children: [
          Expanded(
            child: _SearchBox(
              controller: controller,
              onSubmit: onSubmit,
              onTap: onTapSearch,
            ),
          ),
          const SizedBox(width: 10),
          _IconWithBadge(
            icon: Icons.shopping_cart_outlined,
            badge: cartBadge,
            onTap: onTapCart,
          ),
          const SizedBox(width: 10),
          _IconWithBadge(
            icon: Icons.chat_bubble_outline,
            badge: chatBadge,
            onTap: onTapChat,
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final dynamic
  onSubmit; // dynamic to support both types if needed, or fix upstream
  final VoidCallback? onTap;

  const _SearchBox({required this.controller, this.onSubmit, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: Colors.black54),
            const SizedBox(width: 6),
            Expanded(
              child: IgnorePointer(
                ignoring: onTap != null,
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmit is ValueChanged<String>
                      ? onSubmit
                      : null,
                  decoration: const InputDecoration(
                    hintText: 'Freeship 0Đ (*)',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback? onTap;

  const _IconWithBadge({required this.icon, required this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: _kPrimaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
