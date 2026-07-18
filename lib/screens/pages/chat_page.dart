import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/profile_manager.dart';

// ==========================================
// MODELS FOR CHAT
// ==========================================
class MessageModel {
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final String? imageUrl; // For simulated photo sharing

  MessageModel({
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.imageUrl,
  });
}

class ChatSession {
  final String id;
  String riderName;
  String brandName;
  String avatarPath;
  String status; // 'Mengantar', 'Diseduh', 'Selesai'
  String lastMessageTime;
  final List<MessageModel> messages;
  int unreadCount;
  final String riderId;

  ChatSession({
    required this.id,
    required this.riderName,
    required this.brandName,
    required this.avatarPath,
    required this.status,
    required this.lastMessageTime,
    required this.messages,
    this.unreadCount = 0,
    required this.riderId,
  });
}

// ==========================================
// MAIN CHAT PAGE
// ==========================================
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
  bool _isTyping = false; // Simulated typing indicator
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Primary palette matching the app theme
  static const Color primaryBrown = Color(0xFF4A3324);
  static const Color lightTan = Color(0xFFF5E6D3);
  static const Color bgCream = Color(0xFFFCFAF8);

  String? _customerId;
  String? _customerName;
  String? _customerLogo;

  // List of active chats
  final List<ChatSession> _sessions = [];
  
  // Supabase Realtime channel & Backup Polling
  RealtimeChannel? _messagesChannel;
  Timer? _backupPollingTimer;
  bool _isFetchingBackup = false;

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
        
        // Cek apakah sesi dengan rider_id ini sudah ada sebelumnya
        final existingIndex = _sessions.indexWhere((s) => s.id == expectedChatId);
        
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

    debugPrint("🔌 Init chat for customer: $_customerId");
    
    // 1. Fetch semua pesan yang sudah ada
    await _fetchAllMessages();
    
    // 2. Subscribe ke Supabase Realtime channel untuk INSERT baru (Murni Real-time)
    _messagesChannel = Supabase.instance.client
        .channel('messages_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            debugPrint("📥 Realtime INSERT detected: ${payload.newRecord}");
            _handleNewMessage(payload.newRecord);
          },
        )
        .subscribe((status, [error]) {
          debugPrint("📡 Realtime channel status: $status ${error ?? ''}");
        });
  }

  Future<void> _fetchAllMessages() async {
    try {
      final data = await Supabase.instance.client
          .from('messages')
          .select('*')
          .order('created_at', ascending: true);
      
      if (data is List) {
        await _processMessagesFromSupabase(data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint("❌ Fetch messages error: $e");
    }
  }

  void _handleNewMessage(Map<String, dynamic> newRecord) {
    final msgData = newRecord['message_data'];
    if (msgData is! Map) {
      debugPrint("⚠️ Realtime message skipped: message_data is not a Map");
      return;
    }
    
    final customer = msgData['customer'];
    if (customer is! Map || customer['id']?.toString() != _customerId?.toString()) {
      debugPrint("⚠️ Realtime message skipped: customer ID mismatch (db: ${customer?['id']} vs local: $_customerId)");
      return;
    }
    
    final chatId = msgData['chatId']?.toString() ?? '';
    final riderId = msgData['riderId']?.toString() ?? '';
    final message = msgData['message'];
    if (message is! Map) return;
    
    final sender = message['sender']?.toString() ?? '';
    final text = message['text']?.toString() ?? '';
    String rawTimestampStr = newRecord['created_at']?.toString() ?? message['rawTimestamp']?.toString() ?? '';
    final timestamp = DateTime.tryParse(rawTimestampStr)?.toLocal() ?? DateTime.now();
    
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
          // Cek duplikasi: hanya dianggap duplikat jika teks, pengirim (isMe), dan waktu detiknya sama persis
          final isDuplicate = session.messages.any(
            (m) => m.text == text && 
                   m.isMe == (sender == 'customer') &&
                   m.timestamp.difference(timestamp).inSeconds.abs() <= 2,
          );
          if (!isDuplicate) {
            session.messages.add(newMsg);
            session.lastMessageTime = _formatTimeDisplay(timestamp);
            if (_selectedSessionId != chatId) {
              session.unreadCount += 1;
            }
            // Pindahkan ke atas
            _sessions.removeAt(sessionIndex);
            _sessions.insert(0, session);
            debugPrint("🟢 Realtime message successfully added to session: $chatId");
          } else {
            debugPrint("⚠️ Realtime message skipped: Duplicate detected (text: '$text', isMe: ${sender == 'customer'})");
          }
        } else {
          // Sesi baru
          _sessions.insert(0, ChatSession(
            id: chatId,
            riderName: riderName,
            brandName: brandName,
            avatarPath: avatarPath,
            status: 'Mengantar',
            lastMessageTime: _formatTimeDisplay(timestamp),
            messages: [newMsg],
            riderId: riderId,
          ));
          debugPrint("🟢 Realtime message created new session: $chatId");
        }
      });
      _scrollToBottom();
    }
  }

  String _formatTimeDisplay(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _processMessagesFromSupabase(List<Map<String, dynamic>> data) async {
    final Map<String, ChatSession> sessionMap = {};
    
    for (var row in data) {
      final msgData = row['message_data'];
      if (msgData is! Map) continue;
      
      final customer = msgData['customer'];
      if (customer is! Map || customer['id'] != _customerId) continue;
      
      final chatId = msgData['chatId']?.toString() ?? '';
      final riderId = msgData['riderId']?.toString() ?? '';
      final message = msgData['message'];
      if (message is! Map) continue;
      
      final sender = message['sender']?.toString() ?? '';
      final text = message['text']?.toString() ?? '';
      
      String rawTimestampStr = row['created_at']?.toString() ?? message['rawTimestamp']?.toString() ?? '';
      final timestamp = DateTime.tryParse(rawTimestampStr)?.toLocal() ?? DateTime.now();
      
      final riderData = msgData['riderData'];
      String riderName = 'Rider';
      String brandName = 'Temu Kopling';
      String avatarPath = '';
      if (riderData is Map) {
        riderName = riderData['riderName']?.toString() ?? 'Rider';
        brandName = riderData['brand']?.toString() ?? 'Temu Kopling';
        avatarPath = riderData['logo']?.toString() ?? '';
      }
      
      if (!sessionMap.containsKey(chatId)) {
        sessionMap[chatId] = ChatSession(
          id: chatId,
          riderName: riderName,
          brandName: brandName,
          avatarPath: avatarPath,
          status: 'Mengantar',
          lastMessageTime: _formatTimeDisplay(timestamp),
          messages: [],
          riderId: riderId,
        );
      }
      
      final session = sessionMap[chatId]!;
      // Hindari duplikat pesan
      final isDuplicate = session.messages.any((m) => m.text == text && m.timestamp.difference(timestamp).inSeconds.abs() < 2);
      if (!isDuplicate) {
        session.messages.add(MessageModel(
          text: text,
          timestamp: timestamp,
          isMe: sender == 'customer',
        ));
      }
    }
    
    // Sort messages di tiap session
    for (var session in sessionMap.values) {
      session.messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    
    // Fetch profile terbaru dari database (seperti di web)
    final uniqueRiderIds = sessionMap.values.map((s) => s.riderId).toSet().toList();
    if (uniqueRiderIds.isNotEmpty) {
      try {
        final profilesRes = await Supabase.instance.client
            .from('profiles')
            .select('id, name, brand, logo')
            .inFilter('id', uniqueRiderIds);
        
        if (profilesRes is List) {
          for (var p in profilesRes) {
            if (p is Map) {
              final rId = p['id']?.toString() ?? '';
              final rName = p['name']?.toString() ?? 'Rider';
              final rBrand = p['brand']?.toString() ?? 'Temu Kopling';
              final rLogo = p['logo']?.toString() ?? '';
              
              for (var s in sessionMap.values) {
                if (s.riderId == rId) {
                  s.riderName = rName;
                  s.brandName = rBrand;
                  s.avatarPath = rLogo;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching rider profiles: $e");
      }
    }

    // Fetch status keaktidan kurir dari active_riders
    try {
      final activeRidersRes = await Supabase.instance.client
          .from('active_riders')
          .select();
      
      if (activeRidersRes is List) {
        for (var s in sessionMap.values) {
          final hasActiveRider = activeRidersRes.any(
            (r) => r is Map && r['rider_id']?.toString() == s.riderId,
          );
          if (hasActiveRider) {
            s.status = 'Mengantar';
          } else {
            s.status = 'Selesai';
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching active riders status: $e");
    }
    
    if (mounted) {
      setState(() {
        _sessions.clear();
        _sessions.addAll(sessionMap.values);
        _sessions.sort((a, b) {
          if (a.messages.isEmpty) return 1;
          if (b.messages.isEmpty) return -1;
          return b.messages.last.timestamp.compareTo(a.messages.last.timestamp);
        });
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _backupPollingTimer?.cancel();
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

  void _showDeleteConfirmDialog(ChatSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Obrolan?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1F14),
          ),
        ),
        content: Text(
          'Obrolan dengan ${session.riderName} akan dihapus secara permanen.',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: primaryBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSession(session);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text, {String? imageUrl}) async {
    if (text.trim().isEmpty && imageUrl == null) return;
    
    final session = _activeSession;
    if (session == null) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
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
      }
    };

    _messageController.clear();

    // Optimistic UI update — tampilkan pesan langsung di UI
    setState(() {
      session.messages.add(
        MessageModel(
          text: text.trim(),
          timestamp: now,
          isMe: true,
          imageUrl: imageUrl,
        ),
      );
      // Pindahkan sesi ke paling atas
      final idx = _sessions.indexOf(session);
      if (idx > 0) {
        _sessions.removeAt(idx);
        _sessions.insert(0, session);
      }
    });
    _scrollToBottom();

    try {
      // Simpan langsung ke Supabase secara native. 
      // Realtime Bridge di backend akan secara otomatis mem-broadcast-nya via Socket.io ke Rider Web.
      await Supabase.instance.client.from('messages').insert({
        'chat_id': session.id,
        'message_data': payload,
      });
      debugPrint("✅ Message inserted directly to Supabase");
    } catch (e) {
      debugPrint("❌ Failed to insert message to Supabase: $e");
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
      final matchesSearch = session.riderName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            session.brandName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;

      if (_activeFilter == 'Semua') return true;
      if (_activeFilter == 'Sedang Aktif') return session.status == 'Mengantar' || session.status == 'Diseduh';
      if (_activeFilter == 'Selesai') return session.status == 'Selesai';

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSessionId != null && _activeSession != null) {
      return _buildChatRoomView(_activeSession!);
    }
    return _buildChatListView();
  }

  // ==========================================
  // VIEW: CHAT LIST
  // ==========================================
  Widget _buildChatListView() {
    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          // Elegant wavy background header matching Home & Favorite page style
          ClipPath(
            clipper: _ListHeaderClipper(),
            child: Container(
              height: 140,
              width: double.infinity,
              color: const Color(0xFFF3EAE1),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Titles
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Obrolan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hubungi rider kopling untuk koordinasi pesananmu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari rider atau brand kopi...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: primaryBrown, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: ['Semua', 'Sedang Aktif', 'Selesai'].map((filter) {
                      final isSelected = _activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _activeFilter = filter;
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
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // Chat Items List
                Expanded(
                  child: _filteredSessions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return _buildDismissibleChatCard(session);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DISMISSIBLE WRAPPER (Swipe-to-Delete)
  // ==========================================
  Widget _buildDismissibleChatCard(ChatSession session) {
    return Dismissible(
      key: Key('chat_${session.id}'),
      direction: DismissDirection.endToStart,
      // Konfirmasi sebelum benar-benar dihapus
      confirmDismiss: (direction) async {
        bool confirmed = false;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Hapus Obrolan?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1F14),
              ),
            ),
            content: Text(
              'Obrolan dengan ${session.riderName} akan dihapus secara permanen.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  confirmed = false;
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: primaryBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        return confirmed;
      },
      onDismissed: (direction) => _deleteSession(session),
      // Background merah saat digeser
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: _buildChatItemCard(session),
    );
  }

  // Single item in chat list
  Widget _buildChatItemCard(ChatSession session) {
    final lastMsg = session.messages.isNotEmpty ? session.messages.last.text : '';
    final hasUnread = session.unreadCount > 0;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[100]!),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSessionId = session.id;
            session.unreadCount = 0; // Clear unread count on open
          });
          _scrollToBottom();
        },
        onLongPress: () => _showDeleteConfirmDialog(session),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  _buildAvatar(session.avatarPath, session.brandName),
                  if (session.status != 'Selesai')
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50), // Green dot
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Title and Message details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          session.riderName,
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14.5,
                            color: primaryBrown,
                          ),
                        ),
                        Text(
                          session.lastMessageTime,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: hasUnread ? primaryBrown : Colors.grey,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.brandName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: hasUnread ? Colors.black87 : Colors.black45,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Unread Badge
              if (hasUnread) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: primaryBrown,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${session.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Builder for Brand Logos / Fallback Avatar
  Widget _buildAvatar(String avatarPath, String brandName) {
    if (avatarPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
      bgColor = const Color(0xFF1565C0);
    } else if (brandName.contains('Jago')) {
      bgColor = const Color(0xFFD32F2F);
    } else if (brandName.contains('Jiwa')) {
      bgColor = const Color(0xFF7B1FA2);
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

  // Empty list layout
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Obrolan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Tidak ada rider yang cocok dengan "$_searchQuery"'
                  : 'Belum ada obrolan aktif. Riwayat chat akan muncul saat Anda memesan kopi!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW: CHAT DETAIL ROOM
  // ==========================================
  Widget _buildChatRoomView(ChatSession session) {
    // Quick Replies options
    final quickReplies = [
      'Sesuai titik ya mas 👍',
      'Uang pas ya mas 💵',
      'Kopinya jangan terlalu manis ya ☕',
      'Tolong esnya agak dikurangi 🧊',
      'Terima kasih banyak! 🙏',
      'Ditunggu ya mas, terima kasih! 😊',
      'Saya sudah di depan ya mas 📍',
      'Hati-hati di jalan ya mas 🛵',
      'Kembaliannya ambil saja mas/mba 💵',
      'Tolong ditaruh di pagar/meja depan ya 🚪',
      'Oke siap! 👍',
      'Apakah pesanannya sudah sesuai? 🥤',
      'Sedang di jalan ya mas? 🛵',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      
      // Custom Detail AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBrown),
          onPressed: () {
            setState(() {
              _selectedSessionId = null;
            });
          },
        ),
        title: Row(
          children: [
            // Rider Avatar
            _buildAvatar(session.avatarPath, session.brandName),
            const SizedBox(width: 10),
            
            // Rider Details & Online Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.riderName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: primaryBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.brandName} • ${session.status == 'Selesai' ? 'Offline' : 'Online'}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: session.status == 'Selesai' ? Colors.grey : const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Info Info Button
          IconButton(
            icon: const Icon(Icons.info_outline, color: primaryBrown, size: 20),
            onPressed: () => _showOrderDetails(session),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // Notification Tag for context
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFFFFE0B2).withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.security, size: 14, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demi keamanan, hindari transaksi di luar aplikasi Temu Kopling.',
                    style: TextStyle(fontSize: 10.5, color: Colors.orange[800], fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Message Bubbles Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: session.messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // If it is the last item and _isTyping is true, show the typing indicator
                if (index == session.messages.length) {
                  return _buildTypingIndicatorBubble(session.riderName);
                }

                final message = session.messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Vertical Quick Replies (Scrollable)
          if (session.status != 'Selesai')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 13, color: primaryBrown),
                      const SizedBox(width: 4),
                      Text(
                        'Pesan Cepat',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: quickReplies.length,
                    itemBuilder: (context, index) {
                      final reply = quickReplies[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => _sendMessage(reply),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEFEBE9)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bolt,
                                  size: 14,
                                  color: primaryBrown,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    reply,
                                    style: const TextStyle(
                                      color: primaryBrown,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 10,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          const SizedBox(height: 6),

          // Message Input Field
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment Icon Button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: primaryBrown, size: 24),
                    onPressed: () => _showAttachmentBottomSheet(),
                  ),
                  
                  // Text Area Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 13.5),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: session.status == 'Selesai' 
                              ? 'Obrolan telah dinonaktifkan'
                              : 'Ketik pesan Anda...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        enabled: session.status != 'Selesai',
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),

                  // Send Icon Button
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: primaryBrown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builder for Single Message Bubble
  Widget _buildMessageBubble(MessageModel message) {
    final Alignment alignment = message.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final Color bubbleColor = message.isMe ? primaryBrown : Colors.white;
    final Color textColor = message.isMe ? Colors.white : Colors.black87;
    final double leftPadding = message.isMe ? 50 : 0;
    final double rightPadding = message.isMe ? 0 : 50;

    // Formatting timestamp
    final String timeStr = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(left: leftPadding, right: rightPadding, bottom: 12),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // If the message has an image (simulated attach)
            if (message.imageUrl != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.imageUrl!,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 180,
                        height: 180,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(color: primaryBrown)),
                      );
                    },
                  ),
                ),
              ),
            ],
            
            // Standard Text bubble
            if (message.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                    bottomRight: Radius.circular(message.isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    if (!message.isMe)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
              
            const SizedBox(height: 3),
            
            // Time & Read Status Ticks
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 9.5, color: Colors.grey[400]),
                ),
                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all,
                    size: 13,
                    color: primaryBrown, // Colored brown to represent "Read" status
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Builder for Typing Indicator
  Widget _buildTypingIndicatorBubble(String name) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 50, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$name sedang mengetik',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryBrown),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DIALOGS & SHEET SIMULATIONS
  // ==========================================
  
  // Order detail dialog helper
  void _showOrderDetails(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: primaryBrown),
              SizedBox(width: 8),
              Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryBrown),
              ),
              const SizedBox(height: 4),
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
              child: const Text('Tutup', style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold)),
            )
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
          Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: primaryBrown)),
        ],
      ),
    );
  }

  // Bottom sheet attachment menu
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBrown),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      // Simulate sending a photo
                      _sendMessage('', imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500');
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      // Simulate sending a photo
                      _sendMessage('', imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=500');
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.location_on,
                    label: 'Lokasi Saya',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _sendMessage('📍 Lokasi saya: Jl. Pemuda No. 12, Surabaya');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
      borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: primaryBrown),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM WAVE CLIPPER FOR HEADER
// ==========================================
class _ListHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height - 20);
    var firstEndPoint = Offset(size.width / 2.2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 55);
    var secondEndPoint = Offset(size.width, size.height - 25);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
