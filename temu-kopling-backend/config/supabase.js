const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Mengambil URL dan Key dari file .env yang tadi Mas buat
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

// Membuat jembatan (client) ke database Supabase
const supabase = createClient(supabaseUrl, supabaseKey);

module.exports = supabase;
