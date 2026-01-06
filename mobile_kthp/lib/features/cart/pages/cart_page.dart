import 'package:flutter/material.dart';
import 'package:mobile_kthp/features/products/pages/product_list_page.dart';
import 'package:provider/provider.dart';
import '../controllers/cart_controller.dart';
import '../../products/pages/product_detail_page.dart';
import '../../../data/models/product.dart';
import '../../checkout/pages/checkout_page.dart';
import '../models/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<int> _selectedItemIds = {};

  void _onItemChecked(int productId, bool checked) {
    setState(() {
      if (checked) {
        _selectedItemIds.add(productId);
      } else {
        _selectedItemIds.remove(productId);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Auto select all items on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cart = context.read<CartController>();
      final allIds = cart.items.map((e) => e.product.id).toList();
      setState(() {
        _selectedItemIds.addAll(allIds);
      });
    });
  }

  void _onToggleAll(bool checked, List<int> allIds) {
    setState(() {
      if (checked) {
        _selectedItemIds.addAll(allIds);
      } else {
        _selectedItemIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final allIds = cart.items.map((e) => e.product.id).toList();
    final isAllSelected =
        allIds.isNotEmpty &&
        allIds.every((id) => _selectedItemIds.contains(id));

    // Tính tổng tiền cho các item được chọn
    final selectedTotal = cart.items.fold<num>(0, (sum, item) {
      if (_selectedItemIds.contains(item.product.id)) {
        return sum + item.lineTotal;
      }
      return sum;
    });

    final selectedCount = cart.items
        .where((item) => _selectedItemIds.contains(item.product.id))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00B14F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Giỏ hàng (${cart.totalQty})',
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Demo chức năng sửa
            },
            child: const Text(
              'Sửa',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF00B14F),
                ),
              ),
            ],
          ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart()
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                ..._buildGroupedItems(cart.items),

                // Có thể thêm các section khác như "Gợi ý hôm nay" ở đây
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 140),
                  child: Divider(color: Colors.grey),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Có thể bạn cũng thích',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : _buildBottomBar(
              isAllSelected: isAllSelected,
              allIds: allIds,
              totalPrice: selectedTotal,
              selectedCount: selectedCount,
            ),
    );
  }

  List<Widget> _buildGroupedItems(List<dynamic> items) {
    // Nhóm items theo brand
    final Map<String, List<dynamic>> groupedResponse = {};

    for (var item in items) {
      final p = item.product as Product;
      final brand = (p.brand.isEmpty) ? 'No Brand' : p.brand;

      if (!groupedResponse.containsKey(brand)) {
        groupedResponse[brand] = [];
      }
      groupedResponse[brand]!.add(item);
    }

    return groupedResponse.entries.map((entry) {
      return _buildShopSection(entry.key, entry.value, isMall: true);
    }).toList();
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.black26,
          ),
          const SizedBox(height: 20),
          const Text('Giỏ hàng trống', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ProductListPage()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
              foregroundColor: Colors.white,
            ),
            child: const Text('MUA NGAY'),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection(
    String shopName,
    List<dynamic> items, {
    bool isMall = false,
  }) {
    // items là List<CartItem>
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shop Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Checkbox Shop (dùng logic check hết items trong shop này nếu muốn, ở đây check hết items)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: items.every(
                      (item) => _selectedItemIds.contains(item.product.id),
                    ),
                    activeColor: const Color(0xFF00B14F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (v) {
                      final ids = items
                          .map((e) => (e.product as Product).id)
                          .toList();
                      setState(() {
                        if (v == true) {
                          _selectedItemIds.addAll(ids);
                        } else {
                          _selectedItemIds.removeAll(ids);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (isMall)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0011B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'Mall',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: Colors.black54,
                  ),
                const SizedBox(width: 4),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                const Spacer(),
                const Text(
                  'Sửa',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // List Items
          ...items.map((item) {
            final p = item.product as Product;
            final isSelected = _selectedItemIds.contains(p.id);
            return _buildCartItem(item, isSelected);
          }).toList(),

          // Shop Voucher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  size: 18,
                  color: Color(0xFF00B14F),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Voucher giảm đến 20%',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  color: const Color(0xFF00B14F).withOpacity(0.1),
                  child: const Text(
                    'Mới',
                    style: TextStyle(color: Color(0xFF00B14F), fontSize: 10),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),

          // Shipping promo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giảm 15k phí vận chuyển đơn tối thiểu 0đ',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(
                  'Tìm hiểu thêm',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item, bool isSelected) {
    final cart = context.read<CartController>();
    final p = item.product as Product;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox Item
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                activeColor: const Color(0xFF00B14F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (v) => _onItemChecked(p.id, v == true),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Image
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(productId: p.id),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                p.thumbnail,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.2),
                ),
                const SizedBox(height: 6),
                // Variation badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Phân loại hàng: Bạc',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Price
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00B14F)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        '15.1',
                        style: TextStyle(
                          color: Color(0xFF00B14F),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${p.price}đ',
                      style: const TextStyle(
                        color: Color(0xFF00B14F),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quantity changer
                Row(
                  children: [
                    _QtyBtn(icon: Icons.remove, onTap: () => cart.dec(p.id)),
                    Container(
                      width: 40,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border.symmetric(
                          vertical: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    _QtyBtn(icon: Icons.add, onTap: () => cart.inc(p.id)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({
    required bool isAllSelected,
    required List<int> allIds,
    required num totalPrice,
    required int selectedCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Check all
              InkWell(
                onTap: () => _onToggleAll(!isAllSelected, allIds),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isAllSelected,
                          activeColor: const Color(0xFF00B14F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) => _onToggleAll(v == true, allIds),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tất cả',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Tổng:',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$totalPriceđ',
                            style: const TextStyle(
                              color: Color(0xFF00B14F),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Tiết kiệm 120k', // Dummy
                      style: TextStyle(fontSize: 10, color: Color(0xFF00B14F)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Button Buy
              InkWell(
                onTap: () {
                  final cart = context.read<CartController>();
                  final selectedItems = cart.items
                      .where(
                        (item) => _selectedItemIds.contains(item.product.id),
                      )
                      .toList();

                  if (selectedItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn sản phẩm')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CheckoutPage(items: selectedItems.cast<CartItem>()),
                    ),
                  );
                },
                child: Container(
                  color: const Color(0xFF00B14F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ), // Reduced padding
                  alignment: Alignment.center,
                  height: double.infinity,
                  child: Text(
                    'Mua hàng ($selectedCount)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Slightly smaller font
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }
}
