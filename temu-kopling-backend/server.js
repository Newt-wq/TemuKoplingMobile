const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const supabase = require('./config/supabase');

const app = express();
app.use(cors());
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', activeRiders: Object.keys(activeRiders).length, time: new Date().toISOString() });
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

// In-memory store (realtime cepat, sumber kebenaran utama)
let activeRiders = {};

// =======================================================
// Helper: load active riders dari Supabase saat server start
// Ini untuk recovery ketika backend di-restart
// =======================================================
async function loadActiveRidersFromDB() {
  try {
    const { data, error } = await supabase
      .from('active_riders')
      .select('*')
      .eq('status', 'online');

    if (error) {
      console.log('⚠️  Gagal load active riders dari DB:', error.message);
      return;
    }

    if (data && data.length > 0) {
      activeRiders = {};
      data.forEach((r) => {
        activeRiders[r.rider_id] = {
          id:        r.rider_id,
          name:      r.name,
          brand:     r.brand   || '',
          logo:      r.logo    || '',
          lat:       r.lat,
          lng:       r.lng,
          landmark:  r.landmark || '',
          status:    'online',
          startTime: r.start_time,
        };
      });
      console.log(`📦 Restored ${data.length} active rider(s) from DB`);
    } else {
      console.log('📦 Tidak ada rider online di DB (normal jika baru start)');
    }
  } catch (e) {
    console.log('⚠️  loadActiveRidersFromDB exception:', e.message);
  }
}

// Helper: broadcast rider list ke semua client
function broadcastRiders() {
  const list = Object.values(activeRiders);
  io.emit('active_riders_update', list);
  // console.log(`📡 Broadcast: ${list.length} riders aktif`);
}

// Helper: upsert active_rider ke Supabase (safe — handle kolom landmark optional)
async function upsertActiveRider(riderData) {
  const row = {
    rider_id:   riderData.id,
    name:       riderData.name,
    brand:      riderData.brand  || '',
    logo:       riderData.logo   || '',
    lat:        riderData.lat,
    lng:        riderData.lng,
    status:     'online',
    start_time: riderData.startTime || new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  // Tambah landmark hanya jika rider mengirimkan (opsional)
  if (riderData.landmark !== undefined) {
    row.landmark = riderData.landmark;
  }

  const { error } = await supabase
    .from('active_riders')
    .upsert(row, { onConflict: 'rider_id' });

  if (error) {
    // Kalau landmark belum ada di DB, coba tanpa kolom itu
    if (error.message.includes('landmark')) {
      console.log('⚠️  Kolom landmark belum ada, upsert tanpa landmark...');
      delete row.landmark;
      const { error: err2 } = await supabase
        .from('active_riders')
        .upsert(row, { onConflict: 'rider_id' });
      if (err2) console.log('❌ Upsert gagal:', err2.message);
      else console.log('✅ Upsert berhasil (tanpa landmark)');
    } else {
      console.log('❌ Upsert failed:', error.message);
    }
  } else {
    console.log('✅ DB updated untuk rider:', riderData.name);
  }
}

// Load saat server start
loadActiveRidersFromDB();

// =======================================================
// SOCKET.IO EVENTS
// =======================================================
io.on('connection', (socket) => {
  console.log('🟢 Klien terhubung:', socket.id);

  // Langsung kirim data ke klien baru tanpa perlu request
  socket.emit('active_riders_update', Object.values(activeRiders));

  // --- CUSTOMER: minta daftar rider aktif ---
  socket.on('get_active_riders', () => {
    socket.emit('active_riders_update', Object.values(activeRiders));
  });

  // --- CHAT: join room agar pesan hanya ke peserta room ---
  socket.on('join_chat_room', (chatId) => {
    if (chatId) {
      socket.join(chatId);
      console.log(`💬 Socket ${socket.id} join room: ${chatId}`);
    }
  });

  socket.on('leave_chat_room', (chatId) => {
    if (chatId) socket.leave(chatId);
  });

  // --- CHAT: request history ---
  socket.on('request_chat_history', async (chatId) => {
    try {
      let query = supabase
        .from('messages')
        .select('*')
        .order('created_at', { ascending: true });

      if (chatId) query = query.eq('chat_id', chatId);

      const { data, error } = await query;
      if (error) { console.log('❌ Chat history error:', error.message); return; }
      socket.emit('chat_history_loaded', data || []);
    } catch (e) {
      console.log('❌ request_chat_history exception:', e.message);
    }
  });

  // --- CHAT: kirim pesan baru ---
  socket.on('send_message', async (data) => {
    try {
      const { error } = await supabase.from('messages').insert({
        chat_id:      data.chatId,
        message_data: data,
      });

      if (error) { console.log('❌ Gagal simpan pesan:', error.message); return; }

      // Kirim ke room jika ada yang join, fallback broadcast
      const roomSize = io.sockets.adapter.rooms.get(data.chatId)?.size || 0;
      if (roomSize > 0) {
        io.to(data.chatId).emit('receive_message', data);
      } else {
        io.emit('receive_message', data);
      }
    } catch (e) {
      console.log('❌ send_message exception:', e.message);
    }
  });

  // --- RIDER: mulai ngetem ---
  socket.on('start_ngetem', async (riderData) => {
    console.log(`🏍️  ${riderData.name} mulai ngetem [${riderData.lat?.toFixed(4)}, ${riderData.lng?.toFixed(4)}] landmark="${riderData.landmark || '-'}"`);

    // Update in-memory DULU agar broadcast langsung
    activeRiders[riderData.id] = {
      id:        riderData.id,
      name:      riderData.name,
      brand:     riderData.brand  || '',
      logo:      riderData.logo   || '',
      lat:       riderData.lat,
      lng:       riderData.lng,
      landmark:  riderData.landmark || '',
      status:    'online',
      startTime: riderData.startTime || new Date().toISOString(),
    };

    broadcastRiders(); // kirim dulu ke semua customer

    // Simpan ke DB (async, tidak blocking broadcast)
    upsertActiveRider(riderData);
  });

  // --- RIDER: update lokasi realtime ---
  socket.on('update_location', (data) => {
    if (!activeRiders[data.id]) return;

    activeRiders[data.id].lat = data.lat;
    activeRiders[data.id].lng = data.lng;

    broadcastRiders();

    // Update DB non-blocking
    supabase
      .from('active_riders')
      .update({ lat: data.lat, lng: data.lng, updated_at: new Date().toISOString() })
      .eq('rider_id', data.id)
      .then(({ error }) => {
        if (error) console.log('⚠️  update_location DB error:', error.message);
      });
  });

  // --- RIDER: selesai ngetem ---
  socket.on('stop_ngetem', async (riderId) => {
    if (!activeRiders[riderId]) {
      console.log(`⚠️  stop_ngetem: rider ${riderId} tidak ditemukan di memory`);
      broadcastRiders(); // tetap broadcast agar customer sync
      return;
    }

    console.log(`🛑 ${activeRiders[riderId].name} berhenti ngetem`);
    delete activeRiders[riderId];

    broadcastRiders(); // kirim dulu ke customer

    // Update DB
    const { error } = await supabase
      .from('active_riders')
      .update({ status: 'offline', updated_at: new Date().toISOString() })
      .eq('rider_id', riderId);

    if (error) console.log('⚠️  stop_ngetem DB error:', error.message);
  });

  // Disconnect: JANGAN hapus dari active_riders
  // Rider hilang hanya saat tekan "Berhenti Ngetem"
  socket.on('disconnect', () => {
    console.log('🔴 Klien terputus:', socket.id);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`\n${'='.repeat(45)}`);
  console.log(`🚀 Temu Kopling Backend — port ${PORT}`);
  console.log(`${'='.repeat(45)}\n`);
});
