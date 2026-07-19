import 'dart:async';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/shared/widgets/wavy_header_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:temu_kopling_mobile/features/profile/services/profile_manager.dart';

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
  static void removeListener(VoidCallback listener) =>
      listeners.remove(listener);

  static void toggle(MenuModel menu) {
    if (isFavorite(menu)) {
      favoriteItems.removeWhere(
        (item) => item.name == menu.name && item.brand == menu.brand,
      );
    } else {
      favoriteItems.add(menu);
    }
    for (var listener in listeners) {
      listener();
    }
  }

  static bool isFavorite(MenuModel menu) {
    return favoriteItems.any(
      (item) => item.name == menu.name && item.brand == menu.brand,
    );
  }
}

class BrandModel {
  final String name;
  final String logoUrl; // URL atau path asset foto logo brand
  final Color color;
  final bool isAsset; // true jika pakai asset lokal, false jika network

  const BrandModel({
    required this.name,
    required this.logoUrl,
    required this.color,
    this.isAsset = false,
  });
}

// Daftar brand dengan foto logo
const List<BrandModel> allBrands = [
  BrandModel(
    name: 'Terlaris',
    logoUrl: 'assets/Terlaris.png',
    color: AppColors.primaryBrown,
    isAsset: true,
  ),
  BrandModel(
    name: 'Calf Coffee',
    logoUrl: 'assets/brand_coffe/Calf.png',
    color: AppColors.brandBlue,
    isAsset: true,
  ),
  BrandModel(
    name: 'Sejuta Jiwa',
    logoUrl: 'assets/brand_coffe/KSJ.png',
    color: AppColors.brandPurple,
    isAsset: true,
  ),
  BrandModel(
    name: 'Kopi Jago',
    logoUrl: 'assets/brand_coffe/Jago.jpeg',
    color: AppColors.deleteRed,
    isAsset: true,
  ),
];

// Daftar semua menu
const List<MenuModel> allMenus = [
  // Calf Coffee
  MenuModel(
    image: 'assets/brand_coffe/calf/caramel-jeff.png',
    brand: 'Calf Coffee',
    name: 'Caramel Macchiato',
    price: 'Rp 18.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/calf/eskopi-reg.png',
    brand: 'Calf Coffee',
    name: 'Es Kopi Regular',
    price: 'Rp 16.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/calf/americano.png',
    brand: 'Calf Coffee',
    name: 'Calf Americano',
    price: 'Rp 15.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/calf/liquid-jeff.png',
    brand: 'Calf Coffee',
    name: 'Liquid Latte',
    price: 'Rp 20.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/calf/mocha-jeff.png',
    brand: 'Calf Coffee',
    name: 'Mocha Milkbar',
    price: 'Rp 22.000',
  ),
  // Sejuta Jiwa
  MenuModel(
    image: 'assets/brand_coffe/ksj/EsAmericano.jpeg',
    brand: 'Sejuta Jiwa',
    name: 'Iced Americano',
    price: 'Rp 12.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/ksj/Eskopisususejutajiwa.jpeg',
    brand: 'Sejuta Jiwa',
    name: 'Aren Latte',
    price: 'Rp 15.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/ksj/Eskopivanila.jpeg',
    brand: 'Sejuta Jiwa',
    name: 'Vanilla Latte',
    price: 'Rp 17.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/ksj/EsCokelat.jpeg',
    brand: 'Sejuta Jiwa',
    name: 'Es Cokelat',
    price: 'Rp 16.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/ksj/EsLemonade.jpeg',
    brand: 'Sejuta Jiwa',
    name: 'Es Lemonade',
    price: 'Rp 14.000',
  ),
  // Kopi Jago
  MenuModel(
    image: 'assets/brand_coffe/jago/kopi susu jago.png',
    brand: 'Kopi Jago',
    name: 'Kopi Susu Jago',
    price: 'Rp 13.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/jago/Citrus Cold Brew.png',
    brand: 'Kopi Jago',
    name: 'Citrus Cold Brew',
    price: 'Rp 15.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/jago/Salted Caramel Latte.png',
    brand: 'Kopi Jago',
    name: 'Salted Caramel Latte',
    price: 'Rp 18.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/jago/matcha.png',
    brand: 'Kopi Jago',
    name: 'Matcha Latte',
    price: 'Rp 16.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/jago/chocolate.png',
    brand: 'Kopi Jago',
    name: 'Hot Chocolate',
    price: 'Rp 15.000',
  ),
];

// Menu Terlaris / Rekomendasi — satu unggulan dari tiap brand
const List<MenuModel> recommendedMenus = [
  MenuModel(
    image: 'assets/brand_coffe/calf/caramel-jeff.png',
    brand: 'Calf Coffee',
    name: 'Caramel Macchiato',
    price: 'Rp 18.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/ksj/Eskopisususejutajiwa.jpeg',
    brand: 'Sejuta Jiwa',
    name: 'Aren Latte',
    price: 'Rp 15.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/jago/kopi susu jago.png',
    brand: 'Kopi Jago',
    name: 'Kopi Susu Jago',
    price: 'Rp 13.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/calf/liquid-jeff.png',
    brand: 'Calf Coffee',
    name: 'Liquid Latte',
    price: 'Rp 20.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/ksj/EsAmericano.jpeg',
    brand: 'Sejuta Jiwa',
    name: 'Iced Americano',
    price: 'Rp 12.000',
  ),
  MenuModel(
    image: 'assets/brand_coffe/jago/Citrus Cold Brew.png',
    brand: 'Kopi Jago',
    name: 'Citrus Cold Brew',
    price: 'Rp 15.000',
  ),
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
  late final ProfileManager _profileManager = ProfileManager();

  @override
  void initState() {
    super.initState();
    _profileManager.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profileManager.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<MenuModel> get _filteredMenus {
    if (_selectedBrand == 'Terlaris') {
      return recommendedMenus; // Tampilkan rekomendasi saja
    }
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
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: Stack(
        children: [
          // Background gelombang halus
          ClipPath(
            clipper: WavyHeaderClipper(),
            child: Container(
              height: 230,
              width: double.infinity,
              color: AppColors.bgWave,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER PROFIL
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.lightTan,
                          backgroundImage: ProfileManager.getProfileImage(
                            _profileManager.profileImage,
                          ),
                          child:
                              ProfileManager.getProfileImage(
                                    _profileManager.profileImage,
                                  ) ==
                                  null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.primaryBrown,
                                )
                              : null,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _profileManager.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBrown,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.notifications_none,
                          color: AppColors.primaryBrown,
                          size: 28,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xxl),

                    // 2. KARTU PETA LIVE (FlutterMap Preview)
                    GestureDetector(
                      onTap: widget.onNavigateToTracking,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.radiusXxl,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: AppRadius.radiusXxl,
                          child: Stack(
                            children: [
                              // Peta asli FlutterMap (non-interaktif)
                              Positioned.fill(
                                child: AbsorbPointer(
                                  absorbing:
                                      true, // Blokir semua gesture agar GestureDetector di atas yang handle tap
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(-7.2575, 112.7521),
                                      initialZoom: 14.0,
                                      interactionOptions:
                                          const InteractionOptions(
                                            flags: InteractiveFlag
                                                .none, // Matikan semua interaksi
                                          ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}?access_token=pk.eyJ1IjoicmxkeW5uIiwiYSI6ImNtcnFkbHQ3eTNxamwyeHNlbHlid3lvdXEifQ.RWhbqX2IppS-TtBpeZvt6g',
                                        userAgentPackageName:
                                            'com.example.temu_kopling_mobile',
                                        maxZoom: 21,
                                        tileDimension: 512,
                                        zoomOffset: -1,
                                        errorTileCallback:
                                            (tile, error, stackTrace) {
                                              debugPrint(
                                                '❌ Home tile error: $error',
                                              );
                                            },
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgCard.withValues(
                                      alpha: 0.95,
                                    ),
                                    borderRadius: AppRadius.radiusLg,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: AppColors.primaryBrown,
                                        size: 18,
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      const Expanded(
                                        child: Text(
                                          'Cari gerobak kopi di sekitarmu',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBrown,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBrown,
                                          borderRadius: AppRadius.radiusSm,
                                        ),
                                        child: const Text(
                                          'Lihat Peta',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.bgCard,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                    SizedBox(height: AppSpacing.xxxl),

                    // 3. PROMO SPESIAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Promo Spesial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    const PromoCarousel(),
                    SizedBox(height: AppSpacing.xxxl),

                    // 4. FILTER BRAND (Foto Bulat gaya Instagram Story)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Menu Terpopuler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        Text(
                          _selectedBrand == 'Terlaris'
                              ? '🔥 Terlaris'
                              : _selectedBrand,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allBrands.length,
                        itemBuilder: (context, index) {
                          final brand = allBrands[index];
                          final isSelected = _selectedBrand == brand.name;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedBrand = brand.name),
                            child: Container(
                              width: 82,
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
                                              colors: [
                                                brand.color,
                                                brand.color.withValues(
                                                  alpha: 0.6,
                                                ),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      border: !isSelected
                                          ? Border.all(
                                              color: AppColors.textSecondary,
                                              width: 1.5,
                                            )
                                          : null,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.bgCard,
                                      ),
                                      child: ClipOval(
                                        child: Container(
                                          width: 62,
                                          height: 62,
                                          color: AppColors.bgCard,
                                          child: brand.isAsset
                                              ? Image.asset(
                                                  brand.logoUrl,
                                                  width: 62,
                                                  height: 62,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, _, _) =>
                                                      Icon(
                                                        Icons.coffee,
                                                        color: brand.color,
                                                        size: 30,
                                                      ),
                                                )
                                              : Image.network(
                                                  brand.logoUrl,
                                                  width: 62,
                                                  height: 62,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, _, _) =>
                                                      Icon(
                                                        Icons.coffee,
                                                        color: brand.color,
                                                        size: 30,
                                                      ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    brand.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? brand.color
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),

                    // 5. GRID MENU (berubah sesuai filter)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
    'assets/Promo/Promo-calf.png',
    'assets/Promo/Promo-jago.png',
    'assets/Promo/Promo-KSJ.png',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _currentPage = (_currentPage + 1) % _promoImages.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
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
                  borderRadius: AppRadius.radiusXxl,
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.radiusXxl,
                  child: Image.asset(
                    _promoImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: AppSpacing.md),
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
                color: _currentPage == index
                    ? AppColors.primaryBrown
                    : AppColors.textSecondary,
                borderRadius: AppRadius.radiusXs,
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
    return found.isNotEmpty ? found.first.color : AppColors.primaryBrown;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.radiusXxl,
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
                  decoration: BoxDecoration(
                    color: AppColors
                        .bgCard, // Background putih agar menyatu dengan background JPEG Sejuta Jiwa
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(
                    18.0,
                  ), // Diperkecil dengan memperbesar padding
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: widget.image.startsWith('assets')
                        ? Image.asset(widget.image, fit: BoxFit.contain)
                        : Image.network(widget.image, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => FavoritesManager.toggle(_menu),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : AppColors.textSecondary,
                        size: 18,
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _brandColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Text(
                    widget.brand.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      color: _brandColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBrown,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  widget.price,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBrown,
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

// ==========================================
// EFEK GELOMBANG BACKGROUND
// ==========================================
