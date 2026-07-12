import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_screen.dart'; // Mengambil MainScreen dari folder screens

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://gsjnczwvixorgekrnvva.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdzam5jend2aXhvcmdla3JudnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MzU1NTMsImV4cCI6MjA5MzQxMTU1M30.IglDSBdnbWtadPmupW0FcCMa2Q2ZzX5vqibAmFur9tQ',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temu Kopling',
      debugShowCheckedModeBanner: false, // Menghilangkan tulisan "DEBUG" merah di pojok kanan atas
      theme: ThemeData(
        useMaterial3: true,
        // Set tema warna coklat secara keseluruhan
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const MainScreen(),
    );
  }
}
