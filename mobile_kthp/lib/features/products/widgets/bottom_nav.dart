import 'package:flutter/material.dart';

class ShopeeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notifyBadge;

  const ShopeeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notifyBadge = 0,
  });

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF00B14F);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: active,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          label: 'Live & Video',
        ),
        BottomNavigationBarItem(
          icon: _BadgeIcon(icon: Icons.notifications_none, badge: notifyBadge),
          label: 'Thông báo',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Tôi',
        ),
      ],
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int badge;

  const _BadgeIcon({required this.icon, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (badge > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
