import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/voucher.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../orders/pages/order_history_page.dart';
import '../../address/models/address_model.dart';
import '../../address/controllers/address_controller.dart';
import '../../address/pages/address_list_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  const CheckoutPage({super.key, required this.items});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Shipping State
  // Map brandName -> shippingLabel
  Map<String, String> selectedShippingByBrand = {};

  final List<Map<String, dynamic>> shippingOptions = [
    {'label': 'Nhanh', 'price': 24, 'description': 'Nhận hàng vào 10 Th01'},
    {'label': 'Hỏa Tốc', 'price': 50, 'description': 'Nhận hàng trong 2 giờ'},
  ];

  num _getShippingPrice(String label) {
    final option = shippingOptions.firstWhere(
      (e) => e['label'] == label,
      orElse: () => shippingOptions.first,
    );
    return option['price'] as num;
  }

  // Payment State
  String selectedPaymentMethod = 'Thanh toán khi nhận hàng'; // COD | ShopeePay

  // Voucher state
  // Map brandName -> Voucher?
  Map<String, Voucher?> selectedShopVouchers = {};
  Voucher? selectedShopeeVoucher; // FreeShip voucher

  // Address State
  AddressModel? _selectedAddress;

  // Dummy Vouchers Data
  final List<Map<String, dynamic>> paymentOptions = [
    {'label': 'Thanh toán khi nhận hàng', 'icon': Icons.money},
    {'label': 'Chuyển khoản', 'icon': Icons.account_balance_wallet},
  ];

  final List<Voucher> shopVouchers = [
    Voucher(
      id: '1',
      code: 'SHOP10đ',
      description: 'Giảm 10đ đơn 0đ',
      type: VoucherType.fixedAmount,
      value: 10,
      minOrderValue: 0,
    ),
    Voucher(
      id: '2',
      code: 'SHOP20đ',
      description: 'Giảm 20đ đơn 500đ',
      type: VoucherType.fixedAmount,
      value: 20,
      minOrderValue: 500,
    ),
    Voucher(
      id: '3',
      code: 'SHOP50',
      description: 'Giảm 50% max 50đ đơn 100đ',
      type: VoucherType.percentage,
      value: 50,
      maxDiscount: 50,
      minOrderValue: 100,
    ),
  ];

  final List<Voucher> shopeeVouchers = [
    Voucher(
      id: 'FS1',
      code: 'FREESHIP',
      description: 'Giảm 15đ phí ship',
      type: VoucherType.freeShip,
      value: 15,
      minOrderValue: 0,
    ),
    Voucher(
      id: 'FS2',
      code: 'FREESHIPEXTRA',
      description: 'Miễn phí vận chuyển (Max 50đ)',
      type: VoucherType.freeShip,
      value: 50,
      minOrderValue: 300,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize default shipping for every brand
    final brands = itemsByBrand.keys;
    for (var brand in brands) {
      selectedShippingByBrand[brand] = 'Nhanh';
      selectedShopVouchers[brand] = null;
    }

    // Load Default Address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addrCtrl = context.read<AddressController>();
      if (addrCtrl.addresses.isEmpty) {
        addrCtrl.loadAddresses().then((_) {
          if (mounted) {
            setState(() {
              _selectedAddress = addrCtrl.defaultAddress;
            });
          }
        });
      } else {
        setState(() {
          _selectedAddress = addrCtrl.defaultAddress;
        });
      }
    });
  }

  Map<String, List<CartItem>> get itemsByBrand {
    final map = <String, List<CartItem>>{};
    for (var item in widget.items) {
      final brand = item.product.brand.isEmpty
          ? 'Official Store'
          : '${item.product.brand} Store';
      if (!map.containsKey(brand)) map[brand] = [];
      map[brand]!.add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    num totalItemPrice = 0;
    num totalShippingFee = 0;
    num totalShopDiscount = 0;

    // Iterate over brands to sum up
    itemsByBrand.forEach((brand, items) {
      // Item price
      final brandItemTotal = items.fold<num>(
        0,
        (sum, item) => sum + item.lineTotal,
      );
      totalItemPrice += brandItemTotal;

      // Shipping
      final shippingLabel = selectedShippingByBrand[brand] ?? 'Nhanh';
      final shipFee = _getShippingPrice(shippingLabel);
      totalShippingFee += shipFee;

      // Shop Voucher
      final v = selectedShopVouchers[brand];
      if (v != null) {
        totalShopDiscount += v.calculateDiscount(brandItemTotal, shipFee);
      }
    });

    num shippingDiscount = 0;
    if (selectedShopeeVoucher != null) {
      // Shopee voucher applies to total? Or sum of per-shop? Usually Total Order Value
      shippingDiscount = selectedShopeeVoucher!.calculateDiscount(
        totalItemPrice,
        totalShippingFee,
      );
    }

    final totalPayment =
        totalItemPrice +
        totalShippingFee -
        shippingDiscount -
        totalShopDiscount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAddressSection(),
            const SizedBox(height: 12),
            // Render Shop Sections
            ...itemsByBrand.entries.map((entry) {
              final brand = entry.key;
              final items = entry.value;
              return _buildShopSection(brand, items);
            }),
            const SizedBox(height: 12),
            _buildVoucherSection(totalItemPrice, shippingDiscount),
            const SizedBox(height: 12),
            _buildPaymentMethodSection(),
            const SizedBox(height: 12),
            _buildBillSection(
              totalItemPrice,
              totalShippingFee,
              shippingDiscount,
              totalShopDiscount,
              totalPayment,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(totalPayment),
    );
  }

  // --- Widgets ---

  Widget _buildAddressSection() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddressListPage(selectMode: true),
          ),
        );
        if (result != null && result is AddressModel) {
          setState(() {
            _selectedAddress = result;
          });
        }
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Color(0xFF00B14F), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: _selectedAddress == null
                  ? const Text(
                      'Vui lòng chọn địa chỉ nhận hàng',
                      style: TextStyle(color: Colors.red),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedAddress!.name} | ${_selectedAddress!.phone}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedAddress!.fullAddress,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildShopSection(String brand, List<CartItem> items) {
    final brandItemTotal = items.fold<num>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final selectedVoucher = selectedShopVouchers[brand];

    final shippingLabel = selectedShippingByBrand[brand] ?? 'Nhanh';
    final shippingFee = _getShippingPrice(shippingLabel);

    final discount =
        selectedVoucher?.calculateDiscount(brandItemTotal, shippingFee) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Column(
        children: [
          // Shop Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B14F),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'Yêu thích',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  brand,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // Items
          ...items.map((item) => _buildItemRow(item)).toList(),

          const Divider(height: 1, thickness: 0.5),

          // Shop Voucher
          ListTile(
            title: const Text(
              'Voucher của Shop',
              style: TextStyle(fontSize: 14),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedVoucher != null
                      ? '-${_formatPrice(discount)}₫'
                      : 'Chọn Voucher',
                  style: TextStyle(
                    color: selectedVoucher != null
                        ? const Color(0xFF00B14F)
                        : Colors.black54,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
            onTap: () => _showVoucherDialog(
              title: 'Chọn Voucher của $brand',
              vouchers: shopVouchers,
              currentTotal: brandItemTotal,
              selectedVoucher: selectedVoucher,
              onSelect: (v) => setState(() => selectedShopVouchers[brand] = v),
            ),
          ),

          // Shipping Method for this shop
          _buildShopShipping(brand, shippingLabel, shippingFee),

          // Shop Total
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng số tiền (${items.length} sản phẩm):'),
                Text(
                  '${_formatPrice(brandItemTotal + shippingFee - discount)}₫',
                  style: const TextStyle(
                    color: Color(0xFF00B14F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(CartItem item) {
    final p = item.product;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              p.thumbnail,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'sku: ${p.sku}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatPrice(p.price)}₫',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'x${item.qty}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopShipping(String brand, String label, num fee) {
    final option = shippingOptions.firstWhere(
      (e) => e['label'] == label,
      orElse: () => shippingOptions.first,
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phương thức vận chuyển',
                style: TextStyle(fontSize: 14, color: Colors.green),
              ),
              InkWell(
                onTap: () => _showShippingMethodDialog(brand),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  option['description'],
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              Text('${fee}₫', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection(num totalOrder, num currentShippingDiscount) {
    return InkWell(
      onTap: () => _showVoucherDialog(
        title: 'Chọn Shopee Voucher',
        vouchers: shopeeVouchers,
        currentTotal: totalOrder,
        selectedVoucher: selectedShopeeVoucher,
        onSelect: (v) => setState(() => selectedShopeeVoucher = v),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              color: Color(0xFF00B14F),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Shopee Voucher', style: TextStyle(fontSize: 14)),
            ),
            if (selectedShopeeVoucher != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  selectedShopeeVoucher!.description,
                  style: const TextStyle(color: Colors.green, fontSize: 10),
                ),
              ),

            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    // Find current icon
    final selectedOption = paymentOptions.firstWhere(
      (e) => e['label'] == selectedPaymentMethod,
      orElse: () => paymentOptions.first,
    );

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 14),
                ),
                InkWell(
                  onTap: () => _showPaymentMethodDialog(),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Show ONLY selected
          InkWell(
            onTap: () => _showPaymentMethodDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(
                    selectedOption['icon'] as IconData,
                    color: const Color(0xFF00B14F),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedPaymentMethod,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.check, color: Color(0xFF00B14F)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSection(
    num price,
    num shipFee,
    num shipDiscount,
    num shopDiscount,
    num total,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildBillRow('Tổng tiền hàng', '${_formatPrice(price)}₫'),
          _buildBillRow(
            'Tổng tiền phí vận chuyển',
            '${_formatPrice(shipFee)}₫',
          ),
          if (shipDiscount > 0)
            _buildBillRow(
              'Giảm giá phí vận chuyển',
              '-${_formatPrice(shipDiscount)}₫',
              isNegative: true,
            ),
          if (shopDiscount > 0)
            _buildBillRow(
              'Voucher từ Shop',
              '-${_formatPrice(shopDiscount)}₫',
              isNegative: true,
            ),

          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_formatPrice(total)}₫',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B14F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isNegative ? const Color(0xFF00B14F) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(num total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  '${_formatPrice(total)}₫',
                  style: const TextStyle(
                    color: Color(0xFF00B14F),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  // 1. Place Order (POST /carts/add)
                  // Ref: https://dummyjson.com/docs/carts#add-cart
                  final products = widget.items
                      .map((e) => {'id': e.product.id, 'quantity': e.qty})
                      .toList();

                  final body = jsonEncode({
                    'userId': 1, // Dummy user ID
                    'products': products,
                  });

                  final res = await http.post(
                    Uri.parse('https://dummyjson.com/carts/add'),
                    headers: {'Content-Type': 'application/json'},
                    body: body,
                  );

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    if (!context.mounted) return;

                    // 2. Remove Purchased Items from Local Cart (Selective Delete)
                    // The user requested: "chỉ xóa những sản phẩm mua thành công"
                    final cartController = context.read<CartController>();
                    for (var item in widget.items) {
                      cartController.remove(item.product.id);
                    }

                    Navigator.pop(context); // close loading

                    // 3. Navigate to Order History (Pending Tab)
                    final orderData = jsonDecode(res.body);

                    // Force ID to be even so it appears in the "Pending" tab (id % 6 == 0)
                    // For demo purposes, we override the ID or ensure it satisfies the condition.
                    // Let's create a copy or modify it.
                    // 1002 % 6 = 0, so it's a safe ID for Pending.
                    // We can also just let the real ID flow if we adjusted OrderHistory logic,
                    // but sticking to existing logic is safer for now.
                    orderData['id'] = 1002;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderHistoryPage(
                          initialIndex: 0,
                          simulatedOrder: orderData,
                          fromCheckout: true,
                        ),
                      ),
                    );
                  } else {
                    if (context.mounted) {
                      Navigator.pop(context); // close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi đặt hàng: ${res.statusCode}'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // close loading
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B14F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Đặt hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoucherDialog({
    required String title,
    required List<Voucher> vouchers,
    required num currentTotal,
    required Voucher? selectedVoucher,
    required Function(Voucher?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: vouchers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final v = vouchers[i];
                    final isValid = v.isValid(currentTotal);
                    final isSelected = selectedVoucher?.id == v.id;

                    return Opacity(
                      opacity: isValid ? 1.0 : 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFEE4D2D)
                                : Colors.black12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isValid ? Colors.white : Colors.grey[100],
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.discount,
                            color: isValid
                                ? const Color(0xFFEE4D2D)
                                : Colors.grey,
                          ),
                          title: Text(
                            v.code,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.description),
                              if (!isValid)
                                Text(
                                  'Đơn tối thiểu ${_formatPrice(v.minOrderValue)}₫',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Radio<String>(
                            value: v.id,
                            groupValue: selectedVoucher?.id,
                            activeColor: const Color(0xFFEE4D2D),
                            onChanged: isValid
                                ? (val) {
                                    onSelect(v);
                                    Navigator.pop(context);
                                  }
                                : null,
                          ),
                          onTap: isValid
                              ? () {
                                  onSelect(v);
                                  Navigator.pop(context);
                                }
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selectedVoucher != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      onSelect(null);
                      Navigator.pop(context);
                    },
                    child: const Text('Bỏ chọn Voucher hiện tại'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showShippingMethodDialog(String brand) {
    final currentSelected = selectedShippingByBrand[brand];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn vận chuyển cho $brand',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...shippingOptions.map((option) {
                final isSelected = option['label'] == currentSelected;
                return InkWell(
                  onTap: () {
                    setState(
                      () => selectedShippingByBrand[brand] =
                          option['label'] as String,
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                      color: isSelected
                          ? const Color(0xFFF6FFFA)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option['label'] as String,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                option['description'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${option['price']}₫',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn phương thức thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...paymentOptions.map((option) {
                final isSelected = option['label'] == selectedPaymentMethod;
                return InkWell(
                  onTap: () {
                    setState(
                      () => selectedPaymentMethod = option['label'] as String,
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          color: isSelected
                              ? const Color(0xFFEE4D2D)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option['label'] as String,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                              color: isSelected
                                  ? const Color(0xFFEE4D2D)
                                  : Colors.black,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, color: Color(0xFFEE4D2D)),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatPrice(num price) {
    if (price % 1 == 0) return price.toInt().toString();
    return price.toStringAsFixed(2);
  }
}
