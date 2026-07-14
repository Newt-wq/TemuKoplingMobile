import 'package:flutter/material.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  // ===== TEMA WARNA =====
  static const Color primaryBrown = Color(0xFF4A3324);
  static const Color bgCream = Color(0xFFFCFAF8);
  static const Color textPrimary = Color(0xFF2D1F14);
  static const Color textSecondary = Color(0xFF8D6E63);

  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Berjalan', 'Selesai', 'Batal'];

  // ===== DATA MOCK RIWAYAT PESANAN =====
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'TKO-784902',
      'brand': 'Kopi Jago',
      'brandLogo': 'assets/brand_coffe/Jago.jpeg',
      'date': 'Hari ini, 14:32',
      'status': 'Selesai',
      'items': [
        {'name': 'Kopi Susu Jago', 'qty': 2, 'price': 'Rp 13.000'},
        {'name': 'Citrus Cold Brew', 'qty': 1, 'price': 'Rp 15.000'}
      ],
      'total': 'Rp 41.000',
      'payment': 'GoPay'
    },
    {
      'id': 'TKO-783109',
      'brand': 'Calf Coffee',
      'brandLogo': 'assets/brand_coffe/Calf.jpeg',
      'date': 'Hari ini, 09:15',
      'status': 'Berjalan',
      'items': [
        {'name': 'Caramel Macchiato', 'qty': 1, 'price': 'Rp 18.000'},
        {'name': 'Liquid Latte', 'qty': 1, 'price': 'Rp 20.000'}
      ],
      'total': 'Rp 38.000',
      'payment': 'OVO'
    },
    {
      'id': 'TKO-769821',
      'brand': 'Sejuta Jiwa',
      'brandLogo': 'assets/brand_coffe/KSJ.png',
      'date': 'Kemarin, 16:45',
      'status': 'Selesai',
      'items': [
        {'name': 'Aren Latte', 'qty': 2, 'price': 'Rp 15.000'}
      ],
      'total': 'Rp 30.000',
      'payment': 'GoPay'
    },
    {
      'id': 'TKO-753120',
      'brand': 'Kopi Jago',
      'brandLogo': 'assets/brand_coffe/Jago.jpeg',
      'date': '10 Jul 2026, 11:20',
      'status': 'Batal',
      'items': [
        {'name': 'Salted Caramel Latte', 'qty': 1, 'price': 'Rp 18.000'}
      ],
      'total': 'Rp 18.000',
      'payment': 'Tunai'
    }
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'Semua') return _orders;
    return _orders.where((o) => o['status'] == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
        return const Color(0xFF2E7D32); // Hijau
      case 'Berjalan':
        return const Color(0xFFEF6C00); // Jingga
      case 'Batal':
        return const Color(0xFFC62828); // Merah
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Selesai':
        return const Color(0xFFE8F5E9);
      case 'Berjalan':
        return const Color(0xFFFFF3E0);
      case 'Batal':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: const Text(
          'History Pemesanan',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryBrown, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // ===== FILTER TABS =====
          _buildFilterTabs(),

          // ===== LIST PESANAN =====
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryBrown : const Color(0xFFF5EDE8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryBrown.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColor = _getStatusColor(order['status']);
    final statusBg = _getStatusBgColor(order['status']);
    final List<dynamic> items = order['items'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.brown.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: const Color(0xFFFCFAF8),
                    child: Image.asset(
                      order['brandLogo'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.coffee, color: primaryBrown),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['brand'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order['date'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF5EDE8)),

          // Body Card: Item List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: items.map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['name']} x${item['qty']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        item['price'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF5EDE8)),

          // Footer Card: Payment & Total
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order['total'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryBrown,
                      ),
                    ),
                  ],
                ),
                _buildCardActionButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionButtons(Map<String, dynamic> order) {
    if (order['status'] == 'Selesai') {
      return ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesanan ulang ${order['brand']} berhasil ditambahkan!'),
              backgroundColor: primaryBrown,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Pesan Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    } else if (order['status'] == 'Berjalan') {
      return Row(
        children: [
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menghubungkan ke driver...'),
                  backgroundColor: primaryBrown,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBrown,
              side: const BorderSide(color: primaryBrown, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Membuka peta pelacakan...'),
                  backgroundColor: primaryBrown,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBrown,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lacak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else {
      // Batal
      return TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menghubungkan ke pusat bantuan...'),
              backgroundColor: primaryBrown,
            ),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: const Text('Butuh Bantuan?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: Colors.brown.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada pesanan $_selectedFilter',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba ganti filter atau mulailah memesan kopi!',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
