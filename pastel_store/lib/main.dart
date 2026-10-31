import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PastelStoreApp());
}

// ==================== THEME ====================

class AppColors {
  static const background = Color(0xFFFFF9F5);
  static const lavender = Color(0xFFDCD6F7);
  static const pink = Color(0xFFFFDCE5);
  static const mint = Color(0xFFDDF4E7);
  static const cream = Color(0xFFFFEBC8);
  static const purple = Color(0xFF8174B8);
  static const text = Color(0xFF393447);
  static const subtitle = Color(0xFF96909F);
  static const white = Colors.white;
}

class PastelStoreApp extends StatelessWidget {
  const PastelStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pastel Store',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.purple,
          surface: AppColors.background,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ==================== PRODUCT MODEL ====================

class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final double discountPercentage;
  final String brand;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    required this.images,
    required this.discountPercentage,
    required this.brand,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Product',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] ?? 0,
      thumbnail: json['thumbnail'] ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => image.toString())
              .toList() ??
          [],
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      brand: json['brand'] ?? 'Pastel Collection',
    );
  }
}

// ==================== API SERVICE ====================

class ProductService {
  static const String baseUrl = 'https://dummyjson.com/products';

  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl?limit=0'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List products = data['products'];

      return products
          .map((item) => Product.fromJson(item))
          .toList();
    }

    throw Exception('Failed to load products');
  }
}

// ==================== HOME PAGE ====================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ProductService.fetchProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
        _applyFilters();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load products. Please try again.';
      });
    }
  }

  List<String> get _categories {
    final categories = _products
        .map((product) => product.category)
        .toSet()
        .toList()
      ..sort();

    return ['All', ...categories];
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    _filteredProducts = _products.where((product) {
      final matchesSearch = product.title.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'All' ||
          product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _applyFilters();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.purple,
                ),
              )
            : _errorMessage != null
                ? _buildError()
                : RefreshIndicator(
                    color: AppColors.purple,
                    onRefresh: _loadProducts,
                    child: CustomScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(),
                        ),
                        SliverToBoxAdapter(
                          child: _buildSearchBar(),
                        ),
                        SliverToBoxAdapter(
                          child: _buildCategorySection(),
                        ),
                        SliverToBoxAdapter(
                          child: _buildSectionTitle(),
                        ),
                        if (_filteredProducts.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'No products found 🥺',
                                style: TextStyle(
                                  color: AppColors.subtitle,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              0,
                              18,
                              24,
                            ),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product =
                                      _filteredProducts[index];

                                  return ProductCard(
                                    product: product,
                                    index: index,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailPage(
                                            product: product,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: _filteredProducts.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.61,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: AppColors.purple,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rim Store',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Little things, lovely days ✨',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFE88CA8),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.lavender.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Find something lovely...',
            hintStyle: const TextStyle(
              color: AppColors.subtitle,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.purple,
            ),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.subtitle,
              ),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = _categories;

    return SizedBox(
      height: 57,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 5),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => _selectCategory(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.purple : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: selected
                      ? AppColors.purple
                      : AppColors.lavender,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                category == 'All'
                    ? 'All items'
                    : _capitalize(category),
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore collection',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your next favorite is waiting 💗',
                  style: TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_filteredProducts.length} items',
            style: const TextStyle(
              color: AppColors.purple,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 65,
              color: AppColors.purple,
            ),
            const SizedBox(height: 18),
            const Text(
              'Oops! Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtitle),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadProducts,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PRODUCT CARD ====================

class ProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.onTap,
  });

  static const List<Color> pastelColors = [
    AppColors.lavender,
    AppColors.pink,
    AppColors.mint,
    AppColors.cream,
  ];

  @override
  Widget build(BuildContext context) {
    final background = pastelColors[index % pastelColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.lavender.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: background.withValues(alpha: 0.65),
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      product.thumbnail,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.image_not_supported_outlined,
                          size: 42,
                          color: AppColors.purple,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '-${product.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalize(product.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subtitle,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC45C),
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PRODUCT DETAIL PAGE ====================

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              title: const Text(
                'Product details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 25, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategory(),
                        const SizedBox(height: 12),
                        Text(
                          product.title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 27,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pink,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                  color: Color(0xFFB95D7A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 19),
                        _buildStats(),
                        const SizedBox(height: 28),
                        const Text(
                          'About this item',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildInfoRow(
                          Icons.sell_outlined,
                          'Brand',
                          product.brand,
                          AppColors.lavender,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.inventory_2_outlined,
                          'Availability',
                          product.stock > 0
                              ? '${product.stock} items in stock'
                              : 'Out of stock',
                          AppColors.mint,
                        ),
                        const SizedBox(height: 25),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFE7A94C),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'A little something to brighten your day.',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      height: 310,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.purple,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Center(
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 65,
                    color: AppColors.purple,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _capitalize(product.category),
        style: const TextStyle(
          color: Color(0xFF468A69),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.star_rounded,
            product.rating.toStringAsFixed(1),
            'Rating',
            AppColors.cream,
            const Color(0xFFE3A43C),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            Icons.inventory_2_rounded,
            '${product.stock}',
            'Stock',
            AppColors.mint,
            const Color(0xFF579777),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
    Color background,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 25),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.purple,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HELPER ====================

String _capitalize(String value) {
  if (value.isEmpty) return value;

  return value
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}