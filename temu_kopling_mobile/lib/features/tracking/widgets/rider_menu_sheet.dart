import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/features/home/pages/home_screen.dart' show MenuCard;

class RiderMenuSheet extends StatefulWidget {
  final Map<String, dynamic> rider;

  const RiderMenuSheet({super.key, required this.rider});

  @override
  State<RiderMenuSheet> createState() => _RiderMenuSheetState();
}

class _RiderMenuSheetState extends State<RiderMenuSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _menus = [];

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    try {
      final response = await Supabase.instance.client
          .from('menus')
          .select('*')
          .eq('rider_id', widget.rider['rider_id']);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      // Sort: available first, then alphabetical
      data.sort((a, b) {
        final bool aAvail = a['available'] ?? false;
        final bool bAvail = b['available'] ?? false;
        if (aAvail == bAvail) {
          final String aName = a['name'] ?? '';
          final String bName = b['name'] ?? '';
          return aName.compareTo(bName);
        }
        return aAvail ? -1 : 1;
      });

      if (mounted) {
        setState(() {
          _menus = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching menus: $e");
      if (mounted) {
        setState(() {
          _menus = [];
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMenuContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBrown),
          ),
        ),
      );
    }

    if (_menus.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              "Yah, belum ada menu",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              "Rider ini belum mengatur daftar menu",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _menus.length,
      itemBuilder: (context, index) {
        final menu = _menus[index];
        final bool available = menu['available'] ?? false;
        final int stock = menu['stock'] ?? 0;
        final bool isAvailable = available && stock > 0;

        return Opacity(
          opacity: isAvailable ? 1.0 : 0.6,
          child: MenuCard(
            image: menu['image_url'] ?? '',
            brand: widget.rider['brand'] ?? 'Kopi',
            name: menu['name'] ?? 'Menu',
            price: "Rp ${menu['price'] ?? 0}",
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgTanTracking,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Eksplorasi Menu",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Disajikan segar langsung dari motor",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!_isLoading && _menus.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      "${_menus.where((m) => (m['available'] ?? false) && (m['stock'] ?? 0) > 0).length} Tersedia",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildMenuContent(),
            ),
          ),
        ],
      ),
    );
  }
}
