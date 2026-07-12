import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

// ==========================================
// DATA MODEL MENU & BRAND
// ==========================================
class MenuModel {
  final String image;
  final String brand;
  final String name;
  final String price;

  const MenuModel({
    required this.image,
    required this.brand,
    required this.name,
    required this.price,
  });
}

class FavoritesManager {
  static final List<MenuModel> favoriteItems = [];
  static final List<VoidCallback> listeners = [];

  static void addListener(VoidCallback listener) => listeners.add(listener);
  static void removeListener(VoidCallback listener) => listeners.remove(listener);

  static void toggle(MenuModel menu) {
    if (isFavorite(menu)) {
      favoriteItems.removeWhere((item) => item.name == menu.name && item.brand == menu.brand);
    } else {
      favoriteItems.add(menu);
    }
    for (var listener in listeners) {
      listener();
    }
  }

  static bool isFavorite(MenuModel menu) {
    return favoriteItems.any((item) => item.name == menu.name && item.brand == menu.brand);
  }
}

class BrandModel {
  final String name;
  final String logoUrl; // URL atau path asset foto logo brand
  final Color color;
  final bool isAsset; // true jika pakai asset lokal, false jika network

  const BrandModel({required this.name, required this.logoUrl, required this.color, this.isAsset = false});
}

// Daftar brand dengan foto logo
const List<BrandModel> allBrands = [
  BrandModel(
    name: 'Terlaris',
    logoUrl: 'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=100', // foto kopi untuk 'Terlaris'
    color: Color(0xFF4A3324),
  ),
  BrandModel(
    name: 'Calf Coffee',
    logoUrl: 'assets/brand_coffe/Calf.jpeg',
    color: Color(0xFF1565C0),
    isAsset: true,
  ),
  BrandModel(
    name: 'Sejuta Jiwa',
    logoUrl: 'assets/brand_coffe/KSJ.png',
    color: Color(0xFF7B1FA2),
    isAsset: true,
  ),
  BrandModel(
    name: 'Kopi Jago',
    logoUrl: 'assets/brand_coffe/Jago.jpeg',
    color: Color(0xFFD32F2F),
    isAsset: true,
  ),
];

// Daftar semua menu
const List<MenuModel> allMenus = [
  // Calf Coffee
  MenuModel(image: 'assets/brand_coffe/calf/caramel-jeff.png', brand: 'Calf Coffee', name: 'Caramel Macchiato', price: 'Rp 18.000'),
  MenuModel(image: 'assets/brand_coffe/calf/eskopi-reg.png', brand: 'Calf Coffee', name: 'Es Kopi Regular', price: 'Rp 16.000'),
  MenuModel(image: 'assets/brand_coffe/calf/americano.png', brand: 'Calf Coffee', name: 'Calf Americano', price: 'Rp 15.000'),
  MenuModel(image: 'assets/brand_coffe/calf/liquid-jeff.png', brand: 'Calf Coffee', name: 'Liquid Latte', price: 'Rp 20.000'),
  MenuModel(image: 'assets/brand_coffe/calf/mocha-jeff.png', brand: 'Calf Coffee', name: 'Mocha Milkbar', price: 'Rp 22.000'),
  // Sejuta Jiwa
  MenuModel(image: 'assets/brand_coffe/ksj/EsAmericano.jpeg', brand: 'Sejuta Jiwa', name: 'Iced Americano', price: 'Rp 12.000'),
  MenuModel(image: 'assets/brand_coffe/ksj/Eskopisususejutajiwa.jpeg', brand: 'Sejuta Jiwa', name: 'Aren Latte', price: 'Rp 15.000'),
  MenuModel(image: 'assets/brand_coffe/ksj/Eskopivanila.jpeg', brand: 'Sejuta Jiwa', name: 'Vanilla Latte', price: 'Rp 17.000'),
  MenuModel(image: 'assets/brand_coffe/ksj/EsCokelat.jpeg', brand: 'Sejuta Jiwa', name: 'Es Cokelat', price: 'Rp 16.000'),
  MenuModel(image: 'assets/brand_coffe/ksj/EsLemonade.jpeg', brand: 'Sejuta Jiwa', name: 'Es Lemonade', price: 'Rp 14.000'),
  // Kopi Jago
  MenuModel(image: 'assets/brand_coffe/jago/kopi susu jago.png', brand: 'Kopi Jago', name: 'Kopi Susu Jago', price: 'Rp 13.000'),
  MenuModel(image: 'assets/brand_coffe/jago/Citrus Cold Brew.png', brand: 'Kopi Jago', name: 'Citrus Cold Brew', price: 'Rp 15.000'),
  MenuModel(image: 'assets/brand_coffe/jago/Salted Caramel Latte.png', brand: 'Kopi Jago', name: 'Salted Caramel Latte', price: 'Rp 18.000'),
  MenuModel(image: 'assets/brand_coffe/jago/matcha.png', brand: 'Kopi Jago', name: 'Matcha Latte', price: 'Rp 16.000'),
  MenuModel(image: 'assets/brand_coffe/jago/chocolate.png', brand: 'Kopi Jago', name: 'Hot Chocolate', price: 'Rp 15.000'),
];

// Menu Terlaris / Rekomendasi — satu unggulan dari tiap brand
const List<MenuModel> recommendedMenus = [
  MenuModel(image: 'assets/brand_coffe/calf/caramel-jeff.png', brand: 'Calf Coffee', name: 'Caramel Macchiato', price: 'Rp 18.000'),
  MenuModel(image: 'assets/brand_coffe/ksj/Eskopisususejutajiwa.jpeg', brand: 'Sejuta Jiwa', name: 'Aren Latte', price: 'Rp 15.000'),
  MenuModel(image: 'assets/brand_coffe/jago/kopi susu jago.png', brand: 'Kopi Jago', name: 'Kopi Susu Jago', price: 'Rp 13.000'),
  MenuModel(image: 'assets/brand_coffe/calf/liquid-jeff.png', brand: 'Calf Coffee', name: 'Liquid Latte', price: 'Rp 20.000'),
  MenuModel(image: 'assets/brand_coffe/ksj/EsAmericano.jpeg', brand: 'Sejuta Jiwa', name: 'Iced Americano', price: 'Rp 12.000'),
  MenuModel(image: 'assets/brand_coffe/jago/Citrus Cold Brew.png', brand: 'Kopi Jago', name: 'Citrus Cold Brew', price: 'Rp 15.000'),
];

// ==========================================
// HOME PAGE (StatefulWidget untuk filter brand)
// ==========================================
class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToTracking;

  const HomePage({super.key, this.onNavigateToTracking});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedBrand = 'Terlaris';

  List<MenuModel> get _filteredMenus {
    if (_selectedBrand == 'Terlaris') return recommendedMenus; // Tampilkan rekomendasi saja
    return allMenus.where((m) => m.brand == _selectedBrand).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF4A3324);
    const Color lightTan = Color(0xFFF5E6D3);
    const Color bgCream = Color(0xFFFCFAF8);

    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          // Background gelombang halus
          ClipPath(
            clipper: WavyHeaderClipper(),
            child: Container(
              height: 230,
              width: double.infinity,
              color: const Color(0xFFF3EAE1),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER PROFIL
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: lightTan,
                          child: Icon(Icons.person, color: darkBrown),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                              ),
                              const Text(
                                'Budi Sudarsono',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBrown),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.notifications_none, color: darkBrown, size: 28),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. KARTU PETA LIVE (FlutterMap Preview)
                    GestureDetector(
                      onTap: widget.onNavigateToTracking,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Peta asli FlutterMap (non-interaktif)
                              Positioned.fill(
                                child: AbsorbPointer(
                                  absorbing: true, // Blokir semua gesture agar GestureDetector di atas yang handle tap
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(-7.2575, 112.7521),
                                      initialZoom: 14.0,
                                      interactionOptions: const InteractionOptions(
                                        flags: InteractiveFlag.none, // Matikan semua interaksi
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.temu_kopling',
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Overlay gradien bawah + tombol CTA
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.45),
                                      ],
                                      stops: const [0.4, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // Tombol CTA bawah
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: darkBrown, size: 18),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Cari gerobak kopi di sekitarmu',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: darkBrown,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: darkBrown,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Lihat Peta',
                                          style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),


                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 3. PROMO SPESIAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Promo Spesial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown)),
                        Text('Lihat Semua', style: TextStyle(fontSize: 12, color: Colors.brown[400], fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const PromoCarousel(),
                    const SizedBox(height: 28),

                    // 4. FILTER BRAND (Foto Bulat gaya Instagram Story)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Menu Terpopuler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown)),
                        Text(
                          _selectedBrand == 'Terlaris' ? '🔥 Terlaris' : _selectedBrand,
                          style: TextStyle(fontSize: 12, color: Colors.brown[400], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 96,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allBrands.length,
                        itemBuilder: (context, index) {
                          final brand = allBrands[index];
                          final isSelected = _selectedBrand == brand.name;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedBrand = brand.name),
                            child: Container(
                              width: 72,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [brand.color, brand.color.withValues(alpha: 0.6)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      border: !isSelected
                                          ? Border.all(color: Colors.grey[300]!, width: 1.5)
                                          : null,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: ClipOval(
                                        child: Container(
                                          width: 52,
                                          height: 52,
                                          color: Colors.white,
                                          child: brand.isAsset
                                              ? Image.asset(
                                                  brand.logoUrl,
                                                  width: 52,
                                                  height: 52,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) => Icon(Icons.coffee, color: brand.color, size: 26),
                                                )
                                              : Image.network(
                                                  brand.logoUrl,
                                                  width: 52,
                                                  height: 52,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) => Icon(Icons.coffee, color: brand.color, size: 26),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    brand.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                      color: isSelected ? brand.color : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. GRID MENU (berubah sesuai filter)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: _filteredMenus.length,
                      itemBuilder: (context, index) {
                        final menu = _filteredMenus[index];
                        return MenuCard(
                          image: menu.image,
                          brand: menu.brand,
                          name: menu.name,
                          price: menu.price,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// KARTU PROMO CAROUSEL
// ==========================================
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _promoImages = [
    'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=800',
    'https://images.unsplash.com/photo-1559525839-b184a4d698c7?w=800',
    'https://images.unsplash.com/photo-1600093463592-8e36ae95ef56?w=800',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _currentPage = (_currentPage + 1) % _promoImages.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _promoImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: NetworkImage(_promoImages[index]), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promoImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? const Color(0xFF4A3324) : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// KARTU MENU
// ==========================================
class MenuCard extends StatefulWidget {
  final String image;
  final String brand;
  final String name;
  final String price;

  const MenuCard({
    super.key,
    required this.image,
    required this.brand,
    required this.name,
    required this.price,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  late MenuModel _menu;

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _menu = MenuModel(
      image: widget.image,
      brand: widget.brand,
      name: widget.name,
      price: widget.price,
    );
    FavoritesManager.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    FavoritesManager.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MenuCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Saat GridView mendaur ulang card, update _menu agar tidak stale
    if (oldWidget.image != widget.image ||
        oldWidget.brand != widget.brand ||
        oldWidget.name != widget.name ||
        oldWidget.price != widget.price) {
      _menu = MenuModel(
        image: widget.image,
        brand: widget.brand,
        name: widget.name,
        price: widget.price,
      );
    }
  }

  bool get _isLiked => FavoritesManager.isFavorite(_menu);

  // Cari warna brand yang sesuai
  Color get _brandColor {
    final found = allBrands.where((b) => b.name == widget.brand);
    return found.isNotEmpty ? found.first.color : const Color(0xFF4A3324);
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF4A3324);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white, // Background putih agar menyatu dengan background JPEG Sejuta Jiwa
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.all(18.0), // Diperkecil dengan memperbesar padding
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: widget.image.startsWith('assets')
                        ? Image.asset(
                            widget.image,
                            fit: BoxFit.contain,
                          )
                        : Image.network(
                            widget.image,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => FavoritesManager.toggle(_menu),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.grey[600], size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge brand berwarna
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _brandColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.brand.toUpperCase(),
                    style: TextStyle(fontSize: 8, color: _brandColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkBrown),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(widget.price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// EFEK GELOMBANG BACKGROUND
// ==========================================
class WavyHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 4, size.height + 10, size.width / 2, size.height - 20);
    path.quadraticBezierTo(size.width * 0.75, size.height - 50, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
