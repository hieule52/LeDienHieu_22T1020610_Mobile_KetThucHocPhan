import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/order_item_card.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/product.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../cart/pages/cart_page.dart';
import '../../checkout/pages/checkout_page.dart';
import '../../auth/profile_screen.dart';
import 'order_detail_page.dart';
import '../../chat/pages/chat_list_page.dart';

class OrderHistoryPage extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic>? simulatedOrder;
  final bool fromCheckout;

  const OrderHistoryPage({
    super.key,
    this.initialIndex = 0,
    this.simulatedOrder,
    this.fromCheckout = false,
  });

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _orders = [];
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Inject simulated order immediately if present
    if (widget.simulatedOrder != null) {
      _orders.add(widget.simulatedOrder!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        // If we have a simulated order, don't show loading forever
        setState(() => _loading = false);
        return;
      }

      // 1. Get User ID
      final userRes = await http.get(
        Uri.parse('https://dummyjson.com/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _user = userData;
        final userId = userData['id'];

        // 2. Get Carts (Orders) - Use GLOBAL carts for DEMO purpose to have enough data
        // instead of 'https://dummyjson.com/carts/user/$userId' which might be empty
        final cartsRes = await http.get(
          Uri.parse('https://dummyjson.com/carts?limit=50'),
        );

        if (cartsRes.statusCode == 200) {
          final cartsData = jsonDecode(cartsRes.body);
          setState(() {
            // Append fetched orders to the list (simulated order already at 0)
            _orders.addAll(cartsData['carts']);
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelOrder(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final api = ApiService();
      final repo = OrderRepository(api);
      await repo.cancelOrder(id);

      if (mounted) Navigator.pop(context);

      setState(() {
        _orders.removeWhere((o) => o['id'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn hàng thành công')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _buyAgain(Map<String, dynamic> order) async {
    // Navigate DIRECTLY to CheckoutPage with these items
    try {
      final List<dynamic> productsJson = order['products'] ?? [];
      final List<CartItem> checkoutItems = [];

      for (var pJson in productsJson) {
        // Construct Product object
        // NOTE: dummyjson carts data is partial (missing brand, category, etc.)
        // We fill defaults to avoid crashes in CheckoutPage
        final product = Product(
          id: pJson['id'],
          title: pJson['title'] ?? 'Unknown Product',
          description: 'Product from Order #${order['id']}',
          price: (pJson['price'] as num).toDouble(),
          discountPercentage: (pJson['discountPercentage'] as num).toDouble(),
          rating: 0,
          stock: 999, // Assume in stock
          brand: 'Official Store', // Default brand for checkout grouping
          category: 'General',
          thumbnail: pJson['thumbnail'] ?? 'https://via.placeholder.com/150',
          images: [pJson['thumbnail'] ?? 'https://via.placeholder.com/150'],
        );

        final qty = pJson['quantity'] as int? ?? 1;

        checkoutItems.add(CartItem(product: product, qty: qty));
      }

      if (checkoutItems.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CheckoutPage(items: checkoutItems)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy sản phẩm trong đơn hàng này'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi mua lại: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn đã mua', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00B14F)),
          onPressed: () {
            if (widget.fromCheckout) {
              // If came from checkout, back goes to Profile (as per requirement)
              // Import ProfileScreen if not already, or use named route if set up
              // Assuming direct import needed or reuse specific flow
              // Ideally pushAndRemoveUntil to reset stack to Profile
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                (route) => false,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Cart Button with Badge
          Consumer<CartController>(
            builder: (context, cart, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFF00B14F),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (cart.totalQty > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cart.totalQty > 99 ? '99+' : '${cart.totalQty}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF00B14F),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatListPage()),
                  );
                },
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Color(0xFF00B14F),
          unselectedLabelColor: Colors.black54,
          indicatorColor: Color(0xFF00B14F),
          tabs: const [
            Tab(text: 'Chờ xác nhận'),
            Tab(text: 'Chờ lấy hàng'),
            Tab(text: 'Chờ giao hàng'),
            Tab(text: 'Đã giao'),
            Tab(text: 'Đã hủy'),
            Tab(text: 'Trả hàng'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('pending'),
                _buildOrderList('processing'),
                _buildOrderList('shipping'),
                _buildOrderList('delivered'),
                _buildOrderList('cancelled'),
                _buildOrderList('returned'),
              ],
            ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }

  Widget _buildOrderList(String status) {
    // Determine which orders go into which tab
    // For demo:
    // Chờ xác nhận (pending): orders with even ID
    // Đã giao (delivered): orders with odd ID
    // Others: empty

    // NOTE: dummyjson carts don't have status. We simulate it.
    List<dynamic> filteredOrders = [];

    // Modulo 6 distribution to populate all tabs
    // pending (0), processing (1), shipping (2), delivered (3), cancelled (4), returned (5)

    int targetMod = 0;
    switch (status) {
      case 'pending':
        targetMod = 0;
        break;
      case 'processing':
        targetMod = 1;
        break;
      case 'shipping':
        targetMod = 2;
        break;
      case 'delivered':
        targetMod = 3;
        break;
      case 'cancelled':
        targetMod = 4;
        break;
      case 'returned':
        targetMod = 5;
        break;
    }

    // Filter orders matching the modulo
    filteredOrders = _orders
        .where((o) => (o['id'] as int) % 6 == targetMod)
        .toList();

    // Ensure simulated order (id 1002) always shows in Pending (1002 % 6 = 0)
    // If we wanted it elsewhere, we'd adjust its ID in CheckoutPage.

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: filteredOrders.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return OrderItemCard(
          order: order,
          status: status,
          onCancel: () => _cancelOrder(order['id']),
          onBuyAgain: () => _buyAgain(order),
          onViewDetail: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailPage(orderId: order['id']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 60,
              color: Colors.grey,
            ),
            // Replace with Image asset if available
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa có đơn hàng nào cả',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 40),
          const Row(
            children: [
              Expanded(child: Divider(indent: 40, endIndent: 10)),
              Text(
                'Có thể bạn cũng thích',
                style: TextStyle(color: Colors.black54),
              ),
              Expanded(child: Divider(indent: 10, endIndent: 40)),
            ],
          ),
          const SizedBox(height: 20),
          // Placeholder for random products
          Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text('Danh sách gợi ý...'),
          ),
        ],
      ),
    );
  }
}
