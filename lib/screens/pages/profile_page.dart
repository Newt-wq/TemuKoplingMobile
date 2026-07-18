import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_manager.dart';
import '../auth/login_screen.dart';
import 'home_page.dart'; // untuk FavoritesManager

class ProfilePage extends StatefulWidget {
  final VoidCallback? onNavigateToFavorite;
  const ProfilePage({super.key, this.onNavigateToFavorite});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ===== WARNA TEMA =====
  static const Color primaryBrown = Color(0xFF4A3324);
  static const Color accentBrown = Color(0xFF7B5544);
  static const Color lightBrown = Color(0xFFD4A27A);
  static const Color bgCream = Color(0xFFFCFAF8);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D1F14);
  static const Color textSecondary = Color(0xFF8D6E63);

  // ===== STATE DATA AKUN & PREFERENSI =====
  late final ProfileManager _profileManager = ProfileManager();

  String _language = 'Indonesia';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  final List<String> _addresses = [
    'Rumah: Jl. Embong Kaliasin No. 12, Surabaya',
    'Kantor: Gedung Rektorat Lt. 3, Surabaya',
  ];

  @override
  void initState() {
    super.initState();
    _profileManager.addListener(_onProfileChanged);
    FavoritesManager.addListener(_onFavoritesChanged);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _profileManager.removeListener(_onProfileChanged);
    FavoritesManager.removeListener(_onFavoritesChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkModeEnabled ? const Color(0xFF1E1410) : bgCream,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ===== HEADER DENGAN AVATAR =====
              SliverToBoxAdapter(child: _buildHeader()),

              // ===== STATISTIK =====
              SliverToBoxAdapter(child: _buildStatsRow()),

              // ===== SEKSI AKUN =====
              SliverToBoxAdapter(
                child: _buildSectionTitle('Akun Saya'),
              ),
              SliverToBoxAdapter(child: _buildAccountSection()),

              // ===== SEKSI PREFERENSI =====
              SliverToBoxAdapter(
                child: _buildSectionTitle('Preferensi'),
              ),
              SliverToBoxAdapter(child: _buildPreferenceSection()),

              // ===== SEKSI DUKUNGAN =====
              SliverToBoxAdapter(
                child: _buildSectionTitle('Dukungan'),
              ),
              SliverToBoxAdapter(child: _buildSupportSection()),

              // ===== TOMBOL KELUAR =====
              SliverToBoxAdapter(child: _buildLogoutButton()),

              // ===== VERSI APP =====
              SliverToBoxAdapter(child: _buildAppVersion()),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // HEADER: Avatar + Nama + Badge Member
  // =============================================
  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background gradient gelombang
        ClipPath(
          clipper: _ProfileWaveClipper(),
          child: Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBrown, accentBrown, lightBrown],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Dekorasi lingkaran blur di background
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 60,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                // Judul halaman
                const Positioned(
                  top: 52,
                  left: 20,
                  child: Text(
                    'Profil Saya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Tombol edit di kanan atas
                Positioned(
                  top: 48,
                  right: 16,
                  child: _buildEditButton(),
                ),
              ],
            ),
          ),
        ),

        // Avatar melayang di tengah bawah header
        Positioned(
          top: 130,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                // Avatar dengan border & shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _darkModeEnabled ? const Color(0xFF1E1410) : Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBrown.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: lightBrown,
                    backgroundImage: ProfileManager.getProfileImage(_profileManager.profileImage),
                    child: ProfileManager.getProfileImage(_profileManager.profileImage) == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 54,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                // Nama pengguna
                Text(
                  _profileManager.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _darkModeEnabled ? Colors.white : textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Email
                Text(
                  _profileManager.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: _darkModeEnabled ? Colors.white70 : textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                // Badge Member
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4A027), Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A027).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium,
                          color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Member Gold',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Spacer untuk mendorong konten di bawah header
        const SizedBox(height: 390),
      ],
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () => _showEditProfileDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 14),
            SizedBox(width: 5),
            Text(
              'Edit Profil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // STATISTIK: Pesanan, Poin, Review
  // =============================================
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _darkModeEnabled ? const Color(0xFF2C1E18) : bgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryBrown.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _buildStatItem('0', 'Kupon Saya', Icons.confirmation_number_outlined)),
              _buildStatDivider(),
              Expanded(
                child: InkWell(
                  onTap: () => widget.onNavigateToFavorite?.call(),
                  borderRadius: BorderRadius.circular(20),
                  child: _buildStatItem(
                    FavoritesManager.favoriteItems.length.toString(),
                    'Menu Favorit',
                    Icons.favorite_border_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: accentBrown, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _darkModeEnabled ? Colors.white : primaryBrown,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: _darkModeEnabled ? Colors.white70 : textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: const Color(0xFFEEE0D8),
    );
  }

  // =============================================
  // JUDUL SEKSI
  // =============================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _darkModeEnabled ? Colors.white70 : textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // =============================================
  // SEKSI AKUN
  // =============================================
  Widget _buildAccountSection() {
    return _buildMenuCard([
      _buildMenuItem(
        icon: Icons.person_outline_rounded,
        iconBg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF7E57C2),
        title: 'Informasi Pribadi',
        subtitle: 'Nama, email, nomor telepon',
        onTap: () => _showEditProfileDialog(),
      ),
    ]);
  }

  // =============================================
  // SEKSI PREFERENSI
  // =============================================
  Widget _buildPreferenceSection() {
    return _buildMenuCard([
      _buildMenuItemWithToggle(
        icon: Icons.notifications_outlined,
        iconBg: const Color(0xFFFCE4EC),
        iconColor: const Color(0xFFE91E63),
        title: 'Notifikasi',
        subtitle: 'Promo & info pesanan',
        initialValue: _notificationsEnabled,
        onChanged: (val) {
          setState(() {
            _notificationsEnabled = val;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_notificationsEnabled
                  ? 'Notifikasi diaktifkan'
                  : 'Notifikasi dinonaktifkan'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
      _buildMenuDivider(),
      _buildMenuItem(
        icon: Icons.language_rounded,
        iconBg: const Color(0xFFE0F7FA),
        iconColor: const Color(0xFF00838F),
        title: 'Bahasa',
        subtitle: _language,
        trailing: _buildChip(_language == 'Indonesia' ? 'ID' : 'EN'),
        onTap: () => _showLanguageDialog(),
      ),
    ]);
  }

  // =============================================
  // SEKSI DUKUNGAN
  // =============================================
  Widget _buildSupportSection() {
    return _buildMenuCard([
      _buildMenuItem(
        icon: Icons.help_outline_rounded,
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF8E24AA),
        title: 'Pusat Bantuan',
        subtitle: 'FAQ & panduan penggunaan',
        onTap: () => _showHelpCenterSheet(),
      ),
      _buildMenuDivider(),
      _buildMenuItem(
        icon: Icons.chat_bubble_outline_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        title: 'Hubungi Kami',
        subtitle: 'Chat dengan tim support',
        onTap: () => _showContactUsSheet(),
      ),
      _buildMenuDivider(),
      _buildMenuItem(
        icon: Icons.star_outline_rounded,
        iconBg: const Color(0xFFFFFDE7),
        iconColor: const Color(0xFFF9A825),
        title: 'Beri Rating Aplikasi',
        subtitle: 'Bantu kami berkembang',
        onTap: () => _showRatingDialog(),
      ),
      _buildMenuDivider(),
      _buildMenuItem(
        icon: Icons.info_outline_rounded,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        title: 'Tentang Aplikasi',
        subtitle: 'Versi & kebijakan privasi',
        onTap: () => _showAboutSheet(),
      ),
    ]);
  }

  // =============================================
  // KOMPONEN REUSABLE: Card Menu
  // =============================================
  Widget _buildMenuCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _darkModeEnabled ? const Color(0xFF2C1E18) : bgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryBrown.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: lightBrown.withValues(alpha: 0.12),
      highlightColor: lightBrown.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _darkModeEnabled ? Colors.white : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _darkModeEnabled ? Colors.white70 : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemWithToggle({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool initialValue,
    required ValueChanged<bool> onChanged,
  }) {
    return _ToggleMenuItem(
      key: ValueKey(title + initialValue.toString()),
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      initialValue: initialValue,
      onChanged: onChanged,
      darkModeEnabled: _darkModeEnabled,
    );
  }

  Widget _buildMenuDivider() {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: _darkModeEnabled ? const Color(0xFF422F26) : const Color(0xFFF5EDE8),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E8E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: accentBrown,
        ),
      ),
    );
  }

  // =============================================
  // TOMBOL LOGOUT
  // =============================================
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  color: Color(0xFFE53935), size: 20),
              SizedBox(width: 8),
              Text(
                'Keluar dari Akun',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // VERSI APLIKASI
  // =============================================
  Widget _buildAppVersion() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Image.asset('assets/logo.png', height: 36, errorBuilder: (context, error, stack) {
            return const Icon(Icons.coffee_rounded, color: lightBrown, size: 36);
          }),
          const SizedBox(height: 6),
          const Text(
            'Temu Kopling',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accentBrown,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Versi 1.0.0',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // =============================================
  // DIALOG: Edit Profil
  // =============================================
  void _showEditProfileDialog() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(
        initialName: _profileManager.name,
        initialEmail: _profileManager.email,
        initialPhone: _profileManager.phone,
        initialImage: _profileManager.profileImage,
      ),
    );

    if (result != null && mounted) {
      _profileManager.updateProfile(
        name: result['name'] ?? _profileManager.name,
        email: result['email'] ?? _profileManager.email,
        phone: result['phone'] ?? _profileManager.phone,
        profileImage: result['image'],
      );
    }
  }

  // =============================================
  // DIALOG: Konfirmasi Logout
  // =============================================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        content: const Text(
          'Kamu akan keluar dari akun Temu Kopling. Yakin ingin melanjutkan?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: accentBrown, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil keluar dari akun'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // SHEET: Alamat Saya
  // =============================================
  void _showAddressesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: _darkModeEnabled ? const Color(0xFF1E1410) : bgCream,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Alamat Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _darkModeEnabled ? Colors.white : textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_location_alt_rounded, color: primaryBrown),
                        onPressed: () => _showAddAddressDialog(setModalState),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Belum ada alamat tersimpan',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _addresses.map((address) {
                        final parts = address.split(': ');
                        final label = parts[0];
                        final details = parts.length > 1 ? parts[1] : parts[0];
                        return Card(
                          color: _darkModeEnabled ? const Color(0xFF2C1E18) : Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _darkModeEnabled ? const Color(0xFF422F26) : const Color(0xFFEEE0D8),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.location_pin, color: primaryBrown),
                            title: Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _darkModeEnabled ? Colors.white : textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              details,
                              style: TextStyle(
                                color: _darkModeEnabled ? Colors.white70 : textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setState(() {
                                  _addresses.remove(address);
                                });
                                setModalState(() {});
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAddressDialog(StateSetter setModalState) {
    final labelController = TextEditingController();
    final detailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tambah Alamat Baru', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label Alamat (cth: Rumah, Kantor)',
                  labelStyle: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailController,
                decoration: const InputDecoration(
                  labelText: 'Detail Alamat Lengkap',
                  labelStyle: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final label = labelController.text.trim();
                final detail = detailController.text.trim();
                if (label.isNotEmpty && detail.isNotEmpty) {
                  setState(() {
                    _addresses.add('$label: $detail');
                  });
                  setModalState(() {});
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // =============================================
  // SHEET: Riwayat Pesanan
  // =============================================
  void _showPaymentMethodsSheet() {
    final List<Map<String, dynamic>> paymentMethods = [
      {
        'name': 'GoPay',
        'icon': Icons.account_balance_wallet_rounded,
        'color': Colors.blue,
        'subtitle': 'Utama • Terhubung',
        'isLinked': true,
      },
      {
        'name': 'OVO',
        'icon': Icons.account_balance_wallet_rounded,
        'color': Colors.deepPurple,
        'subtitle': 'Terhubung',
        'isLinked': true,
      },
      {
        'name': 'ShopeePay',
        'icon': Icons.account_balance_wallet_rounded,
        'color': Colors.orange,
        'subtitle': 'Belum terhubung',
        'isLinked': false,
      },
      {
        'name': 'Kartu Debit/Kredit',
        'icon': Icons.credit_card_rounded,
        'color': Colors.green,
        'subtitle': 'Atur kartu debit/kredit',
        'isLinked': false,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _darkModeEnabled ? const Color(0xFF1E1410) : bgCream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkModeEnabled ? Colors.white : textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16, color: primaryBrown),
                    label: const Text('Tambah', style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Column(
                children: paymentMethods.map((method) {
                  return Card(
                    color: _darkModeEnabled ? const Color(0xFF2C1E18) : Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: _darkModeEnabled ? const Color(0xFF422F26) : const Color(0xFFEEE0D8),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: method['color'].withOpacity(0.1),
                        child: Icon(method['icon'], color: method['color']),
                      ),
                      title: Text(
                        method['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _darkModeEnabled ? Colors.white : textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        method['subtitle'],
                        style: const TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      trailing: method['isLinked']
                          ? const Text(
                              'Aktif',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                            )
                          : Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                      onTap: () {
                        if (!method['isLinked']) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Menghubungkan ke ${method['name']}...'),
                              backgroundColor: primaryBrown,
                            ),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================
  // DIALOG: Pilihan Bahasa
  // =============================================
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Pilih Bahasa', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Indonesia', style: TextStyle(color: textPrimary)),
                trailing: _language == 'Indonesia' ? const Icon(Icons.check, color: primaryBrown) : null,
                onTap: () {
                  setState(() {
                    _language = 'Indonesia';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English', style: TextStyle(color: textPrimary)),
                trailing: _language == 'English' ? const Icon(Icons.check, color: primaryBrown) : null,
                onTap: () {
                  setState(() {
                    _language = 'English';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================
  // SHEET: Pusat Bantuan & FAQ
  // =============================================
  void _showHelpCenterSheet() {
    final List<Map<String, String>> faqs = [
      {
        'q': 'Bagaimana cara melakukan pemesanan?',
        'a': 'Pilih brand kopi terdekat di tab Home, pilih item menu yang Anda inginkan, tentukan opsi tambahan (es/gula), lalu tekan tombol Pesan. Anda dapat melacak rider yang sedang membawa pesanan Anda di tab Tracking.'
      },
      {
        'q': 'Bagaimana cara menghubungi rider?',
        'a': 'Saat pesanan sedang dikirim, Anda dapat membuka tab Chat atau menekan tombol Chat pada panel detail rider di tab Tracking untuk mengirim pesan instan ke rider.'
      },
      {
        'q': 'Apakah aplikasi ini mendukung pengiriman di Surabaya?',
        'a': 'Ya, saat ini Temu Kopling melayani pengiriman area Surabaya (khususnya sekitar Kampus Universitas Airlangga, Darmo, dan Wonokromo).'
      },
      {
        'q': 'Bagaimana jika pesanan tidak sesuai?',
        'a': 'Anda dapat menggunakan fitur Hubungi Kami di halaman profil atau langsung chat dengan rider untuk berkoordinasi jika ada ketidaksesuaian.'
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: _darkModeEnabled ? const Color(0xFF1E1410) : bgCream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Pusat Bantuan & FAQ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkModeEnabled ? Colors.white : textPrimary,
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return Card(
                      color: _darkModeEnabled ? const Color(0xFF2C1E18) : Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _darkModeEnabled ? const Color(0xFF422F26) : const Color(0xFFEEE0D8),
                        ),
                      ),
                      child: ExpansionTile(
                        iconColor: primaryBrown,
                        textColor: primaryBrown,
                        collapsedTextColor: _darkModeEnabled ? Colors.white : textPrimary,
                        title: Text(
                          faq['q']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              faq['a']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _darkModeEnabled ? Colors.white70 : textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================
  // SHEET: Hubungi Kami
  // =============================================
  void _showContactUsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _darkModeEnabled ? const Color(0xFF1E1410) : bgCream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Hubungi Kami',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkModeEnabled ? Colors.white : textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tim Customer Support Temu Kopling siap melayani Anda.',
                style: TextStyle(
                  fontSize: 12,
                  color: _darkModeEnabled ? Colors.white70 : textSecondary,
                ),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.chat_outlined, color: Colors.green),
                ),
                title: Text(
                  'Live Chat Support',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _darkModeEnabled ? Colors.white : textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Hubungi langsung agen support kami',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menghubungkan ke Live Chat...'),
                      backgroundColor: primaryBrown,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.email_outlined, color: Colors.blue),
                ),
                title: Text(
                  'Email Support',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _darkModeEnabled ? Colors.white : textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'support@temukopling.com',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka aplikasi email...'),
                      backgroundColor: primaryBrown,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================
  // DIALOG: Rating Aplikasi
  // =============================================
  void _showRatingDialog() {
    int selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Beri Rating Aplikasi', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bagaimana pengalaman Anda menggunakan aplikasi Temu Kopling?', style: TextStyle(fontSize: 12, color: textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedStars = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis ulasan Anda disini...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBCAAA4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEE0D8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEE0D8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryBrown, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Terima kasih atas rating $selectedStars bintang Anda!'),
                        backgroundColor: primaryBrown,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Kirim', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =============================================
  // SHEET: Tentang Aplikasi
  // =============================================
  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _darkModeEnabled ? const Color(0xFF1E1410) : bgCream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Tentang Temu Kopling',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkModeEnabled ? Colors.white : textPrimary,
                ),
              ),
              const Divider(height: 24),
              Text(
                'Temu Kopling (Temukan Kopi Keliling) adalah platform digital inovatif yang mempertemukan penikmat kopi dengan penjual kopi keliling secara real-time. Melalui pelacakan rute terintegrasi, pelanggan dapat menikmati kopi segar dengan mudah dan efisien.',
                style: TextStyle(
                  fontSize: 12,
                  color: _darkModeEnabled ? Colors.white70 : textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Versi Aplikasi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _darkModeEnabled ? Colors.white : textPrimary,
                    ),
                  ),
                  const Text('1.0.0 (Gold Release)', style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lisensi & Kebijakan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _darkModeEnabled ? Colors.white : textPrimary,
                    ),
                  ),
                  const Text('Privacy Policy & TOS', style: TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '© 2026 Temu Kopling Team. All rights reserved.',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================
// TOGGLE MENU ITEM (Stateful karena ada switch)
// =============================================
class _ToggleMenuItem extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final bool darkModeEnabled;

  const _ToggleMenuItem({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.onChanged,
    required this.darkModeEnabled,
  });

  @override
  State<_ToggleMenuItem> createState() => _ToggleMenuItemState();
}

class _ToggleMenuItemState extends State<_ToggleMenuItem> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.darkModeEnabled ? Colors.white : const Color(0xFF2D1F14),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.darkModeEnabled ? Colors.white70 : const Color(0xFF8D6E63),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _value,
            onChanged: (v) {
              setState(() {
                _value = v;
              });
              widget.onChanged(v);
            },
            activeThumbColor: const Color(0xFF4A3324),
            activeTrackColor: const Color(0xFFD4A27A),
          ),
        ],
      ),
    );
  }
}

// =============================================
// EDIT PROFILE BOTTOM SHEET
// =============================================
class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String? initialImage;

  const _EditProfileSheet({
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    this.initialImage,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _selectedImageBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _selectedImageBase64 = widget.initialImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil gambar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCFAF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1F14),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8D6E63)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0E8E0)),
            // Form content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Avatar edit
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFD4A27A),
                            backgroundImage: ProfileManager.getProfileImage(_selectedImageBase64),
                            child: ProfileManager.getProfileImage(_selectedImageBase64) == null
                                ? const Icon(Icons.person_rounded,
                                    size: 58, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4A3324),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildTextField(label: 'Nama Lengkap', hint: 'Masukkan nama kamu', icon: Icons.person_outline_rounded, controller: _nameController),
                  const SizedBox(height: 16),
                  _buildTextField(label: 'Email', hint: 'Masukkan email kamu', icon: Icons.email_outlined, controller: _emailController),
                  const SizedBox(height: 16),
                  _buildTextField(label: 'Nomor Telepon', hint: '+62 xxx xxxx xxxx', icon: Icons.phone_outlined, controller: _phoneController),
                  const SizedBox(height: 32),
                  // Tombol simpan
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'name': _nameController.text,
                          'email': _emailController.text,
                          'phone': _phoneController.text,
                          'image': _selectedImageBase64 ?? '',
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A3324),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: const Color(0xFF4A3324).withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A3324),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBCAAA4), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF8D6E63), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEEE0D8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEEE0D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF4A3324), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================
// CUSTOM CLIPPER: Gelombang Header
// =============================================
class _ProfileWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
