import 'package:flutter/foundation.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_list_response.dart';
import '../../../data/repositories/product_repository.dart';

class ProductController extends ChangeNotifier {
  final ProductRepository repo;
  ProductController(this.repo);

  // list products
  final List<Product> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;

  int _skip = 0;
  final int _limit = 10;
  int _total = 0;
  bool get canLoadMore => items.length < _total;

  // search / filter
  String _query = '';
  String? _category;

  // sort
  String? sortBy;
  String? order;

  // categories
  List<String> categories = [];
  bool loadingCategories = false;

  String? get selectedCategory => _category;
  String get query => _query;

  Future<void> init() async {
    await Future.wait([loadCategories(), loadInitial()]);
  }

  Future<void> loadCategories() async {
    if (loadingCategories) return;
    loadingCategories = true;
    notifyListeners();

    try {
      categories = await repo.getAllCategories();
    } catch (e) {
      // không chặn app nếu lỗi categories
    } finally {
      loadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _skip = 0;
    _total = 0;
    items.clear();
    error = null;
    notifyListeners();
    await loadInitial();
  }

  Future<void> loadInitial() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _fetch(limit: _limit, skip: 0);
      items
        ..clear()
        ..addAll(res.products);
      _skip = res.skip + res.limit;
      _total = res.total;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || isLoading || !canLoadMore) return;
    isLoadingMore = true;
    notifyListeners();

    try {
      final res = await _fetch(limit: _limit, skip: _skip);
      items.addAll(res.products);
      _skip = res.skip + res.limit;
      _total = res.total;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setSearch(String q) async {
    _query = q.trim();
    _category = null; // search thì bỏ category
    await refresh();
  }

  Future<void> clearSearch() async {
    _query = '';
    await refresh();
  }

  Future<void> setCategory(String? category) async {
    _category = category; // null = all
    _query = '';
    // Reset sort when changing category
    sortBy = null;
    order = null;
    await refresh();
  }

  Future<void> setSort({String? sortBy, String? order}) async {
    this.sortBy = sortBy;
    this.order = order;
    await refresh();
  }

  Future<ProductListResponse> _fetch({
    required int limit,
    required int skip,
  }) async {
    if (_category != null && _category!.isNotEmpty) {
      return repo.getProductsByCategory(
        _category!,
        limit: limit,
        skip: skip,
        sortBy: sortBy,
        order: order,
      );
    }
    if (_query.isNotEmpty) {
      return repo.searchProducts(_query, limit: limit, skip: skip);
    }
    return repo.getAllProducts(
      limit: limit,
      skip: skip,
      sortBy: sortBy,
      order: order,
    );
  }
}
