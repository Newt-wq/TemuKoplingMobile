import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';

class ChatService {
  /// Mendapatkan pesan awal dari Supabase
  static Future<List<ChatSession>> fetchAllSessions(String customerId) async {
    final Map<String, ChatSession> sessionMap = {};

    try {
      final data = await Supabase.instance.client
          .from('messages')
          .select('*')
          .order('created_at', ascending: true);

      {
        final messages = List<Map<String, dynamic>>.from(data);
        for (var row in messages) {
          final msgData = row['message_data'];
          if (msgData == null) continue;

          final customer = msgData['customer'];
          if (customer == null || customer['id']?.toString() != customerId) {
            continue;
          }

          final chatId = msgData['chatId']?.toString() ?? '';
          final riderId = msgData['riderId']?.toString() ?? '';
          final message = msgData['message'];
          if (message == null) continue;

          final sender = message['sender']?.toString() ?? '';
          final text = message['text']?.toString() ?? '';

          String rawTimestampStr =
              row['created_at']?.toString() ??
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

          if (!sessionMap.containsKey(chatId)) {
            sessionMap[chatId] = ChatSession(
              id: chatId,
              riderName: riderName,
              brandName: brandName,
              avatarPath: avatarPath,
              status: 'Mengantar', // Default status
              lastMessageTime: formatTimeDisplay(timestamp),
              messages: [],
              riderId: riderId,
            );
          }

          final session = sessionMap[chatId]!;
          final isDuplicate = session.messages.any(
            (m) =>
                m.text == text &&
                m.timestamp.difference(timestamp).inSeconds.abs() < 2,
          );
          if (!isDuplicate) {
            session.messages.add(
              MessageModel(
                text: text,
                timestamp: timestamp,
                isMe: sender == 'customer',
              ),
            );
          }
        }

        // Sort messages di tiap session
        for (var session in sessionMap.values) {
          session.messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }

        // Ambil data profile terbaru dari rider (jika perlu update logo dll)
        await _enrichRiderProfiles(sessionMap);

        // Ambil status rider dari active_riders
        await _enrichRiderStatus(sessionMap);
      }
    } catch (e) {
      debugPrint("❌ Fetch messages error: $e");
    }

    // Sort session berdasarkan pesan terakhir
    final sortedSessions = sessionMap.values.toList();
    sortedSessions.sort((a, b) {
      if (a.messages.isEmpty) return 1;
      if (b.messages.isEmpty) return -1;
      return b.messages.last.timestamp.compareTo(a.messages.last.timestamp);
    });

    return sortedSessions;
  }

  static Future<void> _enrichRiderProfiles(
    Map<String, ChatSession> sessionMap,
  ) async {
    final uniqueRiderIds = sessionMap.values
        .map((s) => s.riderId)
        .toSet()
        .toList();
    if (uniqueRiderIds.isEmpty) return;

    try {
      final profilesRes = await Supabase.instance.client
          .from('profiles')
          .select('id, name, brand, logo')
          .inFilter('id', uniqueRiderIds);

      {
        for (var p in profilesRes) {
          {
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

  static Future<void> _enrichRiderStatus(
    Map<String, ChatSession> sessionMap,
  ) async {
    try {
      final activeRidersRes = await Supabase.instance.client
          .from('active_riders')
          .select();

      {
        for (var s in sessionMap.values) {
          final hasActiveRider = activeRidersRes.any(
            (r) => r['rider_id']?.toString() == s.riderId,
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
  }

  /// Membuat realtime subscription untuk tabel messages
  static RealtimeChannel subscribeToMessages({
    required Function(Map<String, dynamic>) onInsert,
  }) {
    return Supabase.instance.client
        .channel('messages_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe((status, [error]) {
          debugPrint("📡 Realtime channel status: $status ${error ?? ''}");
        });
  }

  /// Kirim pesan ke Supabase
  static Future<void> sendMessage(
    String chatId,
    Map<String, dynamic> payload,
  ) async {
    await Supabase.instance.client.from('messages').insert({
      'chat_id': chatId,
      'message_data': payload,
    });
  }

  static String formatTimeDisplay(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
