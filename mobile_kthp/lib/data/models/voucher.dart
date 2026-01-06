enum VoucherType {
  fixedAmount, // Giảm số tiền cố định (VD: 15k)
  percentage, // Giảm theo % (VD: 10%)
  freeShip, // Miễn phí vận chuyển
}

class Voucher {
  final String id;
  final String code;
  final String description;
  final VoucherType type;
  final num value; // Số tiền giảm hoặc % giảm
  final num? maxDiscount; // Giảm tối đa bao nhiêu (cho %)
  final num minOrderValue; // Đơn tối thiểu để áp dụng
  final DateTime? expiredDate;

  Voucher({
    required this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    required this.minOrderValue,
    this.maxDiscount,
    this.expiredDate,
  });

  // Kiểm tra xem đơn hàng có đủ điều kiện áp dụng voucher không
  bool isValid(num orderTotal) {
    if (orderTotal < minOrderValue) return false;
    if (expiredDate != null && DateTime.now().isAfter(expiredDate!))
      return false;
    return true;
  }

  // Tính số tiền được giảm
  num calculateDiscount(num orderTotal, num shippingFee) {
    if (!isValid(orderTotal)) return 0;

    switch (type) {
      case VoucherType.fixedAmount:
        return value;
      case VoucherType.percentage:
        final discount = orderTotal * (value / 100);
        if (maxDiscount != null && discount > maxDiscount!) {
          return maxDiscount!;
        }
        return discount;
      case VoucherType.freeShip:
        return value > shippingFee
            ? shippingFee
            : value; // Giảm tối đa bằng phí ship
    }
  }
}
