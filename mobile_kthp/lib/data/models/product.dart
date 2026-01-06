class Product {
  final int id;
  final String title;
  final String description;
  final num price;
  final num discountPercentage;
  final num rating;
  final int stock;
  final String brand;
  final String category;
  final String thumbnail;
  final List<String> images;

  // New fields
  final List<String> tags;
  final String sku;
  final num weight;
  final ProductDimensions? dimensions;
  final String warrantyInformation;
  final String shippingInformation;
  final String availabilityStatus;
  final List<ProductReview> reviews;
  final String returnPolicy;
  final int minimumOrderQuantity;
  final ProductMeta? meta;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.category,
    required this.thumbnail,
    required this.images,
    this.tags = const [],
    this.sku = '',
    this.weight = 0,
    this.dimensions,
    this.warrantyInformation = '',
    this.shippingInformation = '',
    this.availabilityStatus = '',
    this.reviews = const [],
    this.returnPolicy = '',
    this.minimumOrderQuantity = 1,
    this.meta,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? 0) as int,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      price: (json['price'] ?? 0) as num,
      discountPercentage: (json['discountPercentage'] ?? 0) as num,
      rating: (json['rating'] ?? 0) as num,
      stock: (json['stock'] ?? 0) as int,
      brand: (json['brand'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      thumbnail: (json['thumbnail'] ?? '') as String,
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      sku: (json['sku'] ?? '') as String,
      weight: (json['weight'] ?? 0) as num,
      dimensions: json['dimensions'] != null
          ? ProductDimensions.fromJson(json['dimensions'])
          : null,
      warrantyInformation: (json['warrantyInformation'] ?? '') as String,
      shippingInformation: (json['shippingInformation'] ?? '') as String,
      availabilityStatus: (json['availabilityStatus'] ?? '') as String,
      reviews: (json['reviews'] as List? ?? [])
          .map((e) => ProductReview.fromJson(e))
          .toList(),
      returnPolicy: (json['returnPolicy'] ?? '') as String,
      minimumOrderQuantity: (json['minimumOrderQuantity'] ?? 1) as int,
      meta: json['meta'] != null ? ProductMeta.fromJson(json['meta']) : null,
    );
  }
}

class ProductDimensions {
  final num width;
  final num height;
  final num depth;

  ProductDimensions({this.width = 0, this.height = 0, this.depth = 0});

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      width: (json['width'] ?? 0) as num,
      height: (json['height'] ?? 0) as num,
      depth: (json['depth'] ?? 0) as num,
    );
  }
}

class ProductReview {
  final int rating;
  final String comment;
  final String date;
  final String reviewerName;
  final String reviewerEmail;

  ProductReview({
    this.rating = 0,
    this.comment = '',
    this.date = '',
    this.reviewerName = '',
    this.reviewerEmail = '',
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      rating: (json['rating'] ?? 0) as int,
      comment: (json['comment'] ?? '') as String,
      date: (json['date'] ?? '') as String,
      reviewerName: (json['reviewerName'] ?? '') as String,
      reviewerEmail: (json['reviewerEmail'] ?? '') as String,
    );
  }
}

class ProductMeta {
  final String createdAt;
  final String updatedAt;
  final String barcode;
  final String qrCode;

  ProductMeta({
    this.createdAt = '',
    this.updatedAt = '',
    this.barcode = '',
    this.qrCode = '',
  });

  factory ProductMeta.fromJson(Map<String, dynamic> json) {
    return ProductMeta(
      createdAt: (json['createdAt'] ?? '') as String,
      updatedAt: (json['updatedAt'] ?? '') as String,
      barcode: (json['barcode'] ?? '') as String,
      qrCode: (json['qrCode'] ?? '') as String,
    );
  }
}
