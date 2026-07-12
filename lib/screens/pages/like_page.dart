import 'package:flutter/material.dart';
import 'home_page.dart';

class LikePage extends StatefulWidget {
  final VoidCallback? onExplore;
  const LikePage({super.key, this.onExplore});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  String _selectedBrandFilter = 'Semua';

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    FavoritesManager.addListener(_update);
  }

  @override
  void dispose() {
    FavoritesManager.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allFavorites = FavoritesManager.favoriteItems;
    
    // Ambil list unik brand yang ada di favorites untuk filter chip dinamis
    final favoriteBrands = ['Semua', ...allFavorites.map((m) => m.brand).toSet().toList()];

    // Reset filter jika brand yang di-filter sudah tidak ada di favorites
    if (!favoriteBrands.contains(_selectedBrandFilter)) {
      _selectedBrandFilter = 'Semua';
    }

    // Filter list favorit sesuai chip yang dipilih
    final filteredFavorites = _selectedBrandFilter == 'Semua'
        ? allFavorites
        : allFavorites.where((m) => m.brand == _selectedBrandFilter).toList();



    const Color primaryBrown = Color(0xFF4A3324);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF8), // Sama dengan bgCream di Home
      body: Stack(
        children: [
          // Background gelombang halus (diperkecil tinggi gelombangnya)
          ClipPath(
            clipper: WavyHeaderClipper(),
            child: Container(
              height: 150, // Diperkecil dari 230
              width: double.infinity,
              color: const Color(0xFFF3EAE1),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header utama dengan Tombol Clear All jika ada data (mengikuti layout Home)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favorit Kamu',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryBrown,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Koleksi rasa kopi pilihanmu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (allFavorites.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            _showClearAllDialog();
                          },
                          icon: const Icon(Icons.delete_sweep_outlined, color: primaryBrown, size: 18),
                          label: const Text(
                            'Hapus Semua',
                            style: TextStyle(color: primaryBrown, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Color(0xFFD7CCC8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: allFavorites.isEmpty
                      ? _buildEmptyState()
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // 1. STATS & DYNAMIC BRAND FILTER CHIPS
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Stats badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 10,
                                          )
                                        ],
                                      ),
                                      child: Text(
                                        '🔥 Ada ${allFavorites.length} menu tersimpan',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryBrown,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Horizontal scroll filter chips
                                    SizedBox(
                                      height: 36,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: favoriteBrands.length,
                                        itemBuilder: (context, index) {
                                          final brand = favoriteBrands[index];
                                          final isSelected = _selectedBrandFilter == brand;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: ChoiceChip(
                                              label: Text(brand),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  setState(() {
                                                    _selectedBrandFilter = brand;
                                                  });
                                                }
                                              },
                                              selectedColor: primaryBrown,
                                              backgroundColor: Colors.white,
                                              labelStyle: TextStyle(
                                                color: isSelected ? Colors.white : Colors.grey[700],
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(18),
                                                side: BorderSide(
                                                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // 2. GRID FAVORITE ITEMS
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final menu = filteredFavorites[index];
                                    return MenuCard(
                                      key: ValueKey('${menu.brand}_${menu.name}'),
                                      image: menu.image,
                                      brand: menu.brand,
                                      name: menu.name,
                                      price: menu.price,
                                    );
                                  },
                                  childCount: filteredFavorites.length,
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
    );
  }

  // Dialog konfirmasi Hapus Semua
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Semua Favorit?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah kamu yakin ingin menghapus semua daftar kopi kesukaanmu dari halaman favorit ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  FavoritesManager.favoriteItems.clear();
                  // Notify all listeners
                  for (var listener in FavoritesManager.listeners) {
                    listener();
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Empty State (Tepat di tengah layar)
  Widget _buildEmptyState() {
    const Color primaryBrown = Color(0xFF4A3324);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular wave decoration around heart
            Container(
              width: 130, // Dikembalikan ke 130
              height: 130, // Dikembalikan ke 130
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    spreadRadius: 3,
                  )
                ],
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularWaveDecoration(),
                  ),
                  Icon(
                    Icons.favorite_rounded,
                    size: 50, // Dikembalikan ke 50
                    color: Color(0xFFD32F2F),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Kopi Favorit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih kopi kesukaanmu di halaman beranda dan simpan daftarnya di sini!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Button to explore home page
            if (widget.onExplore != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
                onPressed: widget.onExplore,
                icon: const Icon(Icons.search, size: 16),
                label: const Text(
                  'Cari Kopi Sekarang',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CircularWaveDecoration extends StatefulWidget {
  const CircularWaveDecoration({super.key});

  @override
  State<CircularWaveDecoration> createState() => _CircularWaveDecorationState();
}

class _CircularWaveDecorationState extends State<CircularWaveDecoration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(_controller.value),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final currentProgress = (progress + i / 3) % 1.0;
      final radius = maxRadius * currentProgress;
      final opacity = (1.0 - currentProgress) * 0.25;

      final paint = Paint()
        ..color = const Color(0xFF6B4E3D).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
