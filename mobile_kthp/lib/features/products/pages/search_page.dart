import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mobile_kthp/data/repositories/product_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _recentSearches = [];
  List<String> _popularKeywords = [];
  bool _isLoadingKeywords = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadPopularKeywords();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _loadPopularKeywords() async {
    try {
      final repo = context.read<ProductRepository>();
      // Fetch a larger batch to get variety
      final response = await repo.getAllProducts(limit: 30, skip: 0);
      final products = response.products;

      if (products.isNotEmpty) {
        final titles = products.map((p) => p.title).toList();
        titles.shuffle();
        setState(() {
          _popularKeywords = titles.take(8).toList();
          _isLoadingKeywords = false;
        });
      } else {
        // Fallback if empty
        setState(() {
          _popularKeywords = ['iPhone', 'Laptop', 'Shoes', 'Watch'];
          _isLoadingKeywords = false;
        });
      }
    } catch (e) {
      // Fallback on error
      setState(() {
        _popularKeywords = ['iPhone', 'Samsung', 'Xiaomi', 'Oppo'];
        _isLoadingKeywords = false;
      });
    }
  }

  Future<void> _addRecentSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    if (!list.contains(keyword)) {
      list.insert(0, keyword);
      if (list.length > 10) {
        list.removeLast();
      }
      await prefs.setStringList('recent_searches', list);
      _loadRecentSearches();
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  void _onSearch(String keyword) {
    _addRecentSearch(keyword);
    Navigator.pop(context, keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00B14F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF00B14F)),
                onPressed: () => _onSearch(_controller.text),
              ),
            ),
            onSubmitted: _onSearch,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recentSearches.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch sử tìm kiếm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    InkWell(
                      onTap: _clearHistory,
                      child: const Text(
                        'Xóa',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches
                    .map((keyword) => _buildChip(keyword))
                    .toList(),
              ),
              const Divider(height: 32),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Từ khóa phổ biến',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),

            if (_isLoadingKeywords)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularKeywords
                    .map((keyword) => _buildChip(keyword))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return GestureDetector(
      onTap: () {
        // If it's a category, we might want to return it differently?
        // For now, treat as keyword.
        _controller.text = label;
        _onSearch(label);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ),
    );
  }
}
