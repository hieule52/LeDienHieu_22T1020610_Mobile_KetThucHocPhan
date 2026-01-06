import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/product.dart';
import '../../../data/models/product_list_response.dart';
import '../../../data/repositories/product_repository.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/login_screen.dart';
import '../../checkout/pages/checkout_page.dart';
import '../../cart/pages/cart_page.dart';
import '../../cart/models/cart_item.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? product;
  String? error;
  bool loading = true;

  // Dữ liệu cho phần gợi ý
  List<Product> brandProducts = [];
  List<Product> relatedProducts = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<ProductRepository>();
      final p = await repo.getSingleProduct(widget.productId);

      if (!mounted) return;

      // Load Brand products & Related products song song
      ProductListResponse? brandRes;
      ProductListResponse? relatedRes;

      try {
        final results = await Future.wait([
          repo.getProductsByBrand(p.brand, limit: 6),
          repo.getProductsByCategory(p.category, limit: 6),
        ]);
        brandRes = results[0];
        relatedRes = results[1];
      } catch (e) {
        // Ignore error loading suggestions
      }

      if (!mounted) return;
      setState(() {
        product = p;
        if (brandRes != null)
          brandProducts = brandRes.products.where((x) => x.id != p.id).toList();
        if (relatedRes != null)
          relatedProducts = relatedRes.products
              .where((x) => x.id != p.id)
              .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<bool> _ensureLoggedIn() async {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) return true;

    final bool? shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text(
          'Bạn cần đăng nhập để thêm sản phẩm vào giỏ hàng. Bạn có muốn đăng nhập ngay không?',
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

    return ok == true ||
        (mounted && context.read<AuthController>().isAuthenticated);
  }

  Future<void> _addToCartWithAuth(Product p) async {
    final ok = await _ensureLoggedIn();
    if (!ok) return;

    if (!mounted) return;
    context.read<CartController>().add(p);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng')));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      );
    }

    final p = product!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(p),
          SliverList(
            delegate: SliverChildListDelegate([
              _ProductInfoSection(product: p),
              const SizedBox(height: 10),
              _ShopSection(product: p, products: brandProducts),
              const SizedBox(height: 10),
              _DescriptionSection(description: p.description),
              const SizedBox(height: 10),
              _ReviewsSection(product: p),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Đề xuất',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _RecommendationGrid(products: relatedProducts),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomBar(p),
    );
  }

  Widget _buildSliverAppBar(Product p) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent, // Để thấy ảnh khi scroll
      foregroundColor: Colors.white, // Back button màu trắng trên nền ảnh
      flexibleSpace: FlexibleSpaceBar(
        background: PageView.builder(
          itemCount: p.images.length,
          itemBuilder: (_, i) {
            final img = Image.network(p.images[i], fit: BoxFit.cover);
            if (i == 0) {
              return Hero(tag: 'product_${p.id}', child: img);
            }
            return img;
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.share,
            color: Colors.black54,
          ), // Icon nổi nên để màu tối hoặc background
          onPressed: () {},
          style: IconButton.styleFrom(backgroundColor: Colors.white54),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () async {
                final ok = await _ensureLoggedIn();
                if (ok && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                }
              },
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.black54,
              ),
              style: IconButton.styleFrom(backgroundColor: Colors.white54),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Consumer<CartController>(
                builder: (_, cart, __) {
                  if (cart.totalQty == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.totalQty}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          onPressed: () {},
          style: IconButton.styleFrom(backgroundColor: Colors.white54),
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black54),
        onPressed: () => Navigator.pop(context),
        style: IconButton.styleFrom(backgroundColor: Colors.white54),
      ),
    );
  }

  Widget _buildBottomBar(Product p) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50, // Chiều cao chuẩn thanh bottom bar
          child: Row(
            children: [
              // Cụm bên trái: Chat & Thêm giỏ (Nền trắng)
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          // Chat action
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.black54,
                              size: 20,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.black12,
                    ), // Divider
                    Expanded(
                      child: InkWell(
                        onTap: () => _addToCartWithAuth(p),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_shopping_cart,
                              color: Colors.black54,
                              size: 20,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Thêm giỏ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cụm bên phải: Mua ngay (Nền đỏ cam)
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () async {
                    final ok = await _ensureLoggedIn();
                    if (ok && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(
                            items: [CartItem(product: p, qty: 1)],
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    color: const Color(0xFF00B14F), // Green
                    alignment: Alignment.center,
                    child: const Text(
                      'Mua ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

class _ProductInfoSection extends StatelessWidget {
  final Product product;
  const _ProductInfoSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '₫',
                style: TextStyle(color: Color(0xFF00B14F), fontSize: 14),
              ),
              Text(
                '${product.price}',
                style: const TextStyle(
                  color: Color(0xFF00B14F),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: const Color(0xFF00B14F).withOpacity(0.1),
                child: Text(
                  '-${product.discountPercentage.round()}%',
                  style: const TextStyle(
                    color: Color(0xFF00B14F),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            style: const TextStyle(fontSize: 16, height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              Text('${product.rating}', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Text(
                '|  Đã bán ${product.stock * 3}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ), // Dummy sold count
              const Spacer(),
              const Icon(Icons.favorite_border, color: Colors.black54),
            ],
          ),
          const Divider(height: 24),
          // Voucher & Ship
          Row(
            children: [
              const Text(
                'Voucher shop',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: const Color(0xFF00B14F),
                child: const Text(
                  'Giảm 15k',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vận chuyển',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 14,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Xử lý đơn hàng bởi DienHieu',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Miễn phí vận chuyển',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShopSection extends StatelessWidget {
  final Product product;
  final List<Product> products;

  const _ShopSection({required this.product, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.black12,
                backgroundImage: NetworkImage(product.thumbnail),
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand.isEmpty
                          ? 'Official Store'
                          : '${product.brand} Store',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Online 4 phút trước',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00B14F)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'Mall',
                        style: TextStyle(color: Color(0xFF00B14F), fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00B14F)),
                  foregroundColor: const Color(0xFF00B14F),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Xem Shop'),
              ),
            ],
          ),
          if (products.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = products[i];
                  return GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(productId: p.id),
                      ),
                    ),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Image.network(
                              p.thumbnail,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Text(
                                  '${p.price}₫',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF00B14F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;
  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết sản phẩm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  final List<Product> products;
  const _RecommendationGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(productId: p.id),
            ),
          ),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    p.thumbnail,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₫${p.price}',
                        style: const TextStyle(
                          color: Color(0xFF00B14F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final Product product;
  const _ReviewsSection({required this.product});

  @override
  Widget build(BuildContext context) {
    // Calculate average rating from reviews if available, otherwise use product rating
    final rating = product.rating;
    final reviews = product.reviews;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh giá sản phẩm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Show Write Review Dialog
                  _showWriteReviewDialog(context);
                },
                child: const Text(
                  'Viết đánh giá',
                  style: TextStyle(color: Color(0xFF00B14F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Summary
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  if (index < rating.floor()) {
                    return const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    );
                  } else if (index < rating && rating % 1 != 0) {
                    return const Icon(
                      Icons.star_half,
                      size: 16,
                      color: Colors.amber,
                    );
                  }
                  return const Icon(
                    Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '$rating/5 (${reviews.length} đánh giá)',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const Divider(height: 24),

          // Review List
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Chưa có đánh giá nào',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...reviews.take(3).map((r) => _ReviewItem(review: r)).toList(),

          if (reviews.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  'Xem tất cả (${reviews.length})',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Viết đánh giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 32),
                Icon(Icons.star, color: Colors.amber, size: 32),
                Icon(Icons.star, color: Colors.amber, size: 32),
                Icon(Icons.star, color: Colors.amber, size: 32),
                Icon(Icons.star, color: Colors.amber, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Chia sẻ cảm nhận của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ProductReview review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(review.reviewerName, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                size: 12,
                color: Colors.amber,
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(review.comment, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            review.date.split('T')[0],
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
