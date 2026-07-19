import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/features/profile/services/profile_manager.dart';

import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_list_view.dart';
import '../widgets/chat_detail_view.dart';

class ChatPage extends StatefulWidget {
  /// Data rider dari TrackingPage untuk langsung buat chatroom baru.
  /// Format: {'rider_id', 'name', 'brand', 'logo', 'status'}
  final Map<String, dynamic>? newRiderInfo;
  const ChatPage({super.key, this.newRiderInfo});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _selectedSessionId;
  String _searchQuery = '';
  String _activeFilter = 'Semua';
  final bool _isTyping = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _customerId;
  String? _customerName;
  String? _customerLogo;

  final List<ChatSession> _sessions = [];

  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    _initChat();

    // Jika ada rider info dari Tracking Page → buat sesi baru dan langsung buka
    final rider = widget.newRiderInfo;
    if (rider != null) {
      final riderIdStr = rider['rider_id']?.toString() ?? '';
      _customerId = Supabase.instance.client.auth.currentUser?.id;
      if (_customerId != null && riderIdStr.isNotEmpty) {
        final expectedChatId = 'chat_${_customerId}_$riderIdStr';

        final existingIndex = _sessions.indexWhere(
          (s) => s.id == expectedChatId,
        );

        if (existingIndex != -1) {
          _selectedSessionId = expectedChatId;
        } else {
          final riderStatus = rider['status'] as String? ?? 'Mengantar';
          final newSession = ChatSession(
            id: expectedChatId,
            riderName: rider['name'] as String? ?? 'Kurir',
            brandName: rider['brand'] as String? ?? 'Brand Kopi',
            avatarPath: rider['logo'] as String? ?? '',
            status: riderStatus,
            lastMessageTime: 'Sekarang',
            unreadCount: 0,
            riderId: riderIdStr,
            messages: [],
          );
          setState(() {
            _sessions.insert(0, newSession);
            _selectedSessionId = expectedChatId;
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  Future<void> _initChat() async {
    final profile = ProfileManager();
    _customerId = Supabase.instance.client.auth.currentUser?.id;
    _customerName = profile.name;
    _customerLogo = profile.profileImage;

    if (_customerId == null) {
      debugPrint("⚠️ Cannot init chat: _customerId is null");
      return;
    }

    final initialSessions = await ChatService.fetchAllSessions(_customerId!);
    if (mounted) {
      setState(() {
        _sessions.clear();
        _sessions.addAll(initialSessions);
      });
      _scrollToBottom();
    }

    _messagesChannel = ChatService.subscribeToMessages(
      onInsert: _handleNewMessage,
    );
  }

  void _handleNewMessage(Map<String, dynamic> newRecord) {
    final msgData = newRecord['message_data'];
    if (msgData == null) {
      return;
    }

    final customer = msgData['customer'];
    if (customer == null ||
        customer['id']?.toString() != _customerId?.toString()) {
      return;
    }

    final chatId = msgData['chatId']?.toString() ?? '';
    final riderId = msgData['riderId']?.toString() ?? '';
    final message = msgData['message'];
    if (message == null) {
      return;
    }

    final sender = message['sender']?.toString() ?? '';
    final text = message['text']?.toString() ?? '';
    String rawTimestampStr =
        newRecord['created_at']?.toString() ??
        message['rawTimestamp']?.toString() ??
        '';
    final timestamp =
        DateTime.tryParse(rawTimestampStr)?.toLocal() ?? DateTime.now();

    final riderData = msgData['riderData'];
    String riderName = 'Rider';
    String brandName = 'Temu Kopling';
    String avatarPath = '';
    if (riderData is Map) {
      riderName = riderData['riderName']?.toString() ?? 'Rider';
      brandName = riderData['brand']?.toString() ?? 'Temu Kopling';
      avatarPath = riderData['logo']?.toString() ?? '';
    }

    final newMsg = MessageModel(
      text: text,
      timestamp: timestamp,
      isMe: sender == 'customer',
    );

    if (mounted) {
      setState(() {
        var sessionIndex = _sessions.indexWhere((s) => s.id == chatId);

        if (sessionIndex != -1) {
          final session = _sessions[sessionIndex];
          final isDuplicate = session.messages.any(
            (m) =>
                m.text == text &&
                m.isMe == (sender == 'customer') &&
                m.timestamp.difference(timestamp).inSeconds.abs() <= 2,
          );
          if (!isDuplicate) {
            session.messages.add(newMsg);
            session.lastMessageTime = ChatService.formatTimeDisplay(timestamp);
            if (_selectedSessionId != chatId) {
              session.unreadCount += 1;
            }
            _sessions.removeAt(sessionIndex);
            _sessions.insert(0, session);
          }
        } else {
          _sessions.insert(
            0,
            ChatSession(
              id: chatId,
              riderName: riderName,
              brandName: brandName,
              avatarPath: avatarPath,
              status: 'Mengantar',
              lastMessageTime: ChatService.formatTimeDisplay(timestamp),
              messages: [newMsg],
              riderId: riderId,
            ),
          );
        }
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ChatSession? get _activeSession {
    if (_selectedSessionId == null) return null;
    try {
      return _sessions.firstWhere((s) => s.id == _selectedSessionId);
    } catch (_) {
      return null;
    }
  }

  void _deleteSession(ChatSession session) {
    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);
      if (_selectedSessionId == session.id) {
        _selectedSessionId = null;
      }
    });
  }

  Future<void> _sendMessage(String text, {String? imageUrl}) async {
    if (text.trim().isEmpty && imageUrl == null) return;

    final session = _activeSession;
    if (session == null) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final payloadMessage = {
      'sender': 'customer',
      'text': text.trim(),
      'timestamp': timeStr,
      'rawTimestamp': now.toUtc().toIso8601String(),
    };

    final payload = {
      'chatId': session.id,
      'customer': {
        'id': _customerId,
        'name': _customerName,
        'logo': _customerLogo ?? '',
      },
      'riderId': session.riderId,
      'message': payloadMessage,
      'riderData': {
        'riderName': session.riderName,
        'brand': session.brandName,
        'logo': session.avatarPath,
      },
    };

    setState(() {
      session.messages.add(
        MessageModel(
          text: text.trim(),
          timestamp: now,
          isMe: true,
          imageUrl: imageUrl,
        ),
      );
      final idx = _sessions.indexOf(session);
      if (idx > 0) {
        _sessions.removeAt(idx);
        _sessions.insert(0, session);
      }
    });
    _scrollToBottom();

    try {
      await ChatService.sendMessage(session.id, payload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  List<ChatSession> get _filteredSessions {
    return _sessions.where((session) {
      final matchesSearch =
          session.riderName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          session.brandName.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_activeFilter == 'Semua') return true;
      if (_activeFilter == 'Sedang Aktif') {
        return session.status == 'Mengantar' || session.status == 'Diseduh';
      }
      if (_activeFilter == 'Selesai') {
        return session.status == 'Selesai';
      }

      return true;
    }).toList();
  }

  Widget _buildAvatar(String avatarPath, String brandName) {
    if (avatarPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: AppRadius.radiusPill,
        child: Image.asset(
          avatarPath,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(brandName);
          },
        ),
      );
    } else {
      return _buildFallbackAvatar(brandName);
    }
  }

  Widget _buildFallbackAvatar(String brandName) {
    Color bgColor = Colors.brown;
    if (brandName.contains('Calf')) {
      bgColor = AppColors.brandBlue;
    } else if (brandName.contains('Jago')) {
      bgColor = AppColors.deleteRed;
    } else if (brandName.contains('Jiwa')) {
      bgColor = AppColors.brandPurple;
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.coffee, color: bgColor, size: 24),
    );
  }

  void _showOrderDetails(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXxl),
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primaryBrown),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Detail Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Driver', session.riderName),
              _buildInfoRow('Brand Kopi', session.brandName),
              _buildInfoRow('Status Pemesanan', session.status),
              const Divider(height: 20),
              const Text(
                'Pesanan Item:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primaryBrown,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                session.brandName == 'Kopi Jago'
                    ? '• 1x Salted Caramel Latte (Rp 18.000)\n• 1x Citrus Cold Brew (Rp 15.000)'
                    : session.brandName == 'Calf Coffee'
                    ? '• 1x Caramel Macchiato (Rp 18.000)'
                    : '• 1x Aren Latte (Rp 15.000)',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: AppColors.primaryBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBrown,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kirim Lampiran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryBrown,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        '',
                        imageUrl:
                            'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        '',
                        imageUrl:
                            'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=500',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.location_on,
                    label: 'Lokasi Saya',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage(
                        '📍 Lokasi saya: Jl. Pemuda No. 12, Surabaya',
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusLg,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSessionId != null && _activeSession != null) {
      return ChatDetailView(
        session: _activeSession!,
        scrollController: _scrollController,
        messageController: _messageController,
        isTyping: _isTyping,
        onSendMessage: _sendMessage,
        onBack: () => setState(() => _selectedSessionId = null),
        onShowAttachmentBottomSheet: _showAttachmentBottomSheet,
        onShowOrderDetails: () => _showOrderDetails(_activeSession!),
        buildAvatar: _buildAvatar,
      );
    }

    return ChatListView(
      filteredSessions: _filteredSessions,
      searchQuery: _searchQuery,
      activeFilter: _activeFilter,
      onSearchChanged: (val) => setState(() => _searchQuery = val),
      onFilterChanged: (val) => setState(() => _activeFilter = val),
      onSessionTapped: (session) {
        setState(() {
          _selectedSessionId = session.id;
          session.unreadCount = 0;
        });
        _scrollToBottom();
      },
      onDeleteSession: _deleteSession,
      buildAvatar: _buildAvatar,
    );
  }
}
