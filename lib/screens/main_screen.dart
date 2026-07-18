import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/tracking_page.dart';
import 'pages/like_page.dart';
import 'pages/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _trackingKeyCounter = 0;
  /// Data rider dari TrackingPage yang akan dibuatkan chatroom baru
  Map<String, dynamic>? _chatNewRiderInfo;

  // Daftar halaman riil yang akan dipanggil saat tab diklik
  late final List<Widget> _pages;

  void _setSelectedIndex(int index) {
    setState(() {
      if (index == 2 && _selectedIndex != 2) {
        _trackingKeyCounter++;
      }
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        onNavigateToTracking: () => _setSelectedIndex(2),
      ),
      const SizedBox(), // Placeholder untuk ChatPage dinamis
      const SizedBox(), // Placeholder untuk TrackingPage dinamis
      LikePage(
        onExplore: () => _setSelectedIndex(0),
      ),
      ProfilePage(
        onNavigateToFavorite: () => _setSelectedIndex(3),
      ),
    ];
  }

  /// Dipanggil dari TrackingPage saat tombol Chat ditekan.
  /// Menerima data rider lengkap dan langsung buka chatroom baru.
  void _navigateToChat(Map<String, dynamic> riderInfo) {
    setState(() {
      _chatNewRiderInfo = riderInfo;
    });
    _setSelectedIndex(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      
      // ===== ISI HALAMAN TENGAH =====
      // ChatPage dirender ulang dengan data rider baru saat navigasi dari Tracking
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _pages[0], // Home
          ChatPage(
            key: ValueKey(_chatNewRiderInfo?['rider_id']),
            newRiderInfo: _chatNewRiderInfo,
          ), // Chat
          TrackingPage(
            key: ValueKey('tracking_page_$_trackingKeyCounter'),
            onNavigateToChat: _navigateToChat,
            onBack: () => _setSelectedIndex(0),
          ), // Tracking
          _pages[3], // Favorite
          _pages[4], // Profile
        ],
      ),

      // ===== 1. TOMBOL FLOATING DI TENGAH (TRACKING) =====
      floatingActionButton: _selectedIndex == 2
          ? null
          : FloatingActionButton(
              onPressed: () {
                _setSelectedIndex(2);
              },
              backgroundColor: Colors.brown, // Warna coklat sesuai request
              elevation: 6, 
              shape: const CircleBorder(), 
              child: const Icon(
                Icons.location_on, 
                color: Colors.white,
                size: 32, 
              ),
            ),
      
      // ===== 2. POSISI TOMBOL TENGAH =====
      floatingActionButtonLocation: _selectedIndex == 2
          ? null
          : FloatingActionButtonLocation.centerDocked,

      // ===== 3. BAR MENU BAWAH =====
      bottomNavigationBar: _selectedIndex == 2
          ? null
          : BottomAppBar(
              shape: const CircularNotchedRectangle(), 
              notchMargin: 8.0, 
              color: Colors.white,
              elevation: 10,
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround, 
                  children: [
                    _buildTabIcon(index: 0, icon: Icons.home_filled, label: 'Home'), 
                    _buildTabIcon(index: 1, icon: Icons.forum_outlined, label: 'Chat'), 
                    const SizedBox(width: 48), 
                    _buildTabIcon(index: 3, icon: Icons.favorite_border, label: 'Favorite'), 
                    _buildTabIcon(index: 4, icon: Icons.person_outline, label: 'Akun'), 
                  ],
                ),
              ),
            ),
    );
  }

  // Fungsi diubah untuk menerima 'label' teks
  Widget _buildTabIcon({required int index, required IconData icon, required String label}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.brown : Colors.grey;
    
    // Pakai InkWell supaya kolomnya bisa diklik
    return InkWell(
      onTap: () {
        _setSelectedIndex(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min, // Biar column gak memanjang
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color, 
            size: 26, // Ukuran icon sedikit dikecilkan biar teks muat
          ),
          const SizedBox(height: 2), // Jarak antara icon dan teks
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
