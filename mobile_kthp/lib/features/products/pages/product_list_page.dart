import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cart/controllers/cart_controller.dart';
import '../../cart/pages/cart_page.dart';

import '../controllers/product_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav.dart';
import 'product_detail_page.dart';

import '../../auth/login_screen.dart';
import '../../auth/profile_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/pages/notification_page.dart';
import '../../home/widgets/banner_carousel.dart';
import '../../../shared/widgets/skeleton.dart';

import 'search_page.dart';
import '../../chat/pages/chat_list_page.dart';

class ProductListPage extends StatefulWidget {
  final int initialIndex;
  final String? initialSearchQuery;
  const ProductListPage({
    super.key,
    this.initialIndex = 0,
    this.initialSearchQuery,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialIndex;

    Future.microtask(() {
      final c = context.read<ProductController>();
      c.init();
      if (widget.initialSearchQuery != null) {
        c.setSearch(widget.initialSearchQuery!);
      }
    });

    _scroll.addListener(() {
      if (!mounted) return;
      final c = context.read<ProductController>();
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        c.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<bool> _ensureLoggedIn({String? message}) async {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) return true;

    // Hiển thị dialog xác nhận
    final bool? shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: Text(
          message ??
              'Bạn cần đăng nhập để thực hiện thao tác này. Bạn có muốn đăng nhập ngay không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );

    if (shouldLogin != true) return false;

    if (!mounted) return false;

    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    // login_screen.dart đã pop(true) khi login OK
    return ok == true ||
        (mounted && context.read<AuthController>().isAuthenticated);
  }

  Future<void> _addToCartWithAuth(p) async {
    final ok = await _ensureLoggedIn();
    if (!ok) return;

    if (!mounted) return;
    context.read<CartController>().add(p);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã thêm "${p.title}" vào giỏ')));
  }

  // ✅ Xử lý bottom navigation tap
  Future<void> _handleBottomNavTap(int i) async {
    // Tab index: 0 Home, 1 Live, 2 Thông báo, 3 Tôi
    if (i == 3 || i == 2) {
      // 2 (Notification) & 3 (Profile) require login
      final auth = context.read<AuthController>();

      if (!mounted) return;

      if (!auth.isAuthenticated) {
        final ok = await _ensureLoggedIn(
          message: 'Bạn cần đăng nhập để xem thông báo và hồ sơ.',
        );
        if (!ok) return; // User cancelled or login failed
      }

      // Logged in
      if (i == 3) {
        // Move to Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        return;
      }
      // For i == 2, just fall through to setState
    }

    setState(() => _tabIndex = i);
  }

  void _clearSearch(ProductController c) {
    _search.clear();
    c.clearSearch();
  }

  Widget _buildCategories(ProductController c) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Stack(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryPill(
                  label: 'Tất cả',
                  selected: c.selectedCategory == null,
                  icon: Icons.grid_view_rounded,
                  onTap: () async {
                    _search.clear();
                    await context.read<ProductController>().setSort(
                      sortBy: null,
                      order: null,
                    );
                    await context.read<ProductController>().setCategory(null);
                  },
                ),
                const SizedBox(width: 8),

                if (c.loadingCategories)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),

                ...c.categories.map((cat) {
                  final isSelected = c.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryPill(
                      label: _prettyCategory(cat),
                      selected: isSelected,
                      icon: isSelected
                          ? Icons.check_circle
                          : Icons.local_offer_outlined,
                      onTap: () async {
                        _search.clear();
                        await context.read<ProductController>().setSort(
                          sortBy: null,
                          order: null,
                        );
                        await context.read<ProductController>().setCategory(
                          cat,
                        );
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(width: 44), // chừa chỗ cho nút bên phải
              ],
            ),
          ),

          // fade bên phải
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0x00F7F2FA), Color(0xFFF7F2FA)],
                  ),
                ),
              ),
            ),
          ),

          // nút mở bottomsheet
          Positioned(
            right: 8,
            top: 2,
            bottom: 2,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _openCategorySheet(c),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCategorySheet(ProductController c) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: const Text('Tất cả'),
                trailing: c.selectedCategory == null
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  _search.clear();
                  await context.read<ProductController>().setSort(
                    sortBy: null,
                    order: null,
                  );
                  await context.read<ProductController>().setCategory(null);
                },
              ),
              const Divider(),
              ...c.categories.map((cat) {
                final selected = c.selectedCategory == cat;
                return ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: Text(_prettyCategory(cat)),
                  trailing: selected ? const Icon(Icons.check) : null,
                  onTap: () async {
                    Navigator.pop(context);
                    _search.clear();
                    await context.read<ProductController>().setSort(
                      sortBy: null,
                      order: null,
                    );
                    await context.read<ProductController>().setCategory(cat);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProductController>();
    final cart = context.watch<CartController>();

    // Responsive grid
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

    return Scaffold(
      appBar: _tabIndex == 0
          ? ShopeeAppBar(
              controller: _search,
              onSubmit: (v) => context.read<ProductController>().setSearch(v),
              onTapSearch: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
                if (result != null && result is String && context.mounted) {
                  _search.text = result;
                  context.read<ProductController>().setSearch(result);
                }
              },
              cartBadge: cart.totalQty,
              chatBadge: 0,
              onTapCart: () async {
                final ok = await _ensureLoggedIn();
                if (ok && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                }
              },
              onTapChat: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListPage()),
                );
              },
            )
          : null,
      bottomNavigationBar: ShopeeBottomNav(
        currentIndex: _tabIndex,
        notifyBadge: 0,
        onTap: _handleBottomNavTap, // ✅ gọi trực tiếp
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildHomeContent(c, crossAxisCount), // Index 0
          const Center(child: Text('Live & Video - Coming Soon')), // Index 1
          const NotificationPage(), // Index 2: Notifications
          const SizedBox(), // Index 3: Profile (handled via push)
        ],
      ),
    );
  }

  Widget _buildHomeContent(ProductController c, int crossAxisCount) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: RefreshIndicator(
        onRefresh: () => context.read<ProductController>().refresh(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Categories
            if (c.query.isEmpty) SliverToBoxAdapter(child: _buildCategories(c)),

            // 2. Filter Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.selectedCategory != null
                                    ? 'Danh mục: ${_prettyCategory(c.selectedCategory!)}'
                                    : (c.query.isNotEmpty
                                          ? 'Tìm: "${c.query}"'
                                          : 'Sản phẩm'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (c.query.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              _clearSearch(context.read<ProductController>()),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Sort',
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        color: Colors.white,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sort_rounded,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                        onSelected: (val) {
                          final controller = context.read<ProductController>();
                          if (val == 'price_asc') {
                            controller.setSort(sortBy: 'price', order: 'asc');
                          } else if (val == 'price_desc') {
                            controller.setSort(sortBy: 'price', order: 'desc');
                          } else if (val == 'title_asc') {
                            controller.setSort(sortBy: 'title', order: 'asc');
                          } else if (val == 'title_desc') {
                            controller.setSort(sortBy: 'title', order: 'desc');
                          } else {
                            controller.setSort(sortBy: null, order: null);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.restart_alt_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 8),
                                Text('Mặc định'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'title_asc',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_by_alpha_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 8),
                                Text('Tên A → Z'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'title_desc',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_by_alpha_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 8),
                                Text('Tên Z → A'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'price_asc',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 8),
                                Text('Giá: Thấp đến Cao'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'price_desc',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 8),
                                Text('Giá: Cao đến Thấp'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Banner Carousel (Below Filter)
            if (c.query.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: BannerCarousel(),
                ),
              ),

            // 4. Content (Skeleton, Error, Empty, or Grid)
            if (c.isLoading && c.items.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.50,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const SkeletonProductCard(),
                    childCount: 6,
                  ),
                ),
              )
            else if (c.error != null && c.items.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text('Error: ${c.error}')),
              )
            else if (c.items.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        c.query.isEmpty
                            ? 'Không có sản phẩm nào'
                            : 'Không tìm thấy "${c.query}"',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final p = c.items[index];
                    return ProductCard(
                      product: p,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(productId: p.id),
                          ),
                        );
                      },
                      onAddToCart: () => _addToCartWithAuth(p),
                    );
                  }, childCount: c.items.length),
                ),
              ),

            // Loading More Spinner
            if (c.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF00B14F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? active : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? active : Colors.black12),
          boxShadow: [
            if (selected)
              const BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 3),
                color: Color(0x22000000),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _prettyCategory(String s) {
  final parts = s.split('-');
  return parts
      .map((p) {
        if (p.isEmpty) return '';
        return p[0].toUpperCase() + p.substring(1);
      })
      .join(' ');
}
