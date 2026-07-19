import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/features/home/pages/main_screen.dart';
import 'package:temu_kopling_mobile/features/auth/pages/login_screen.dart';
import 'package:temu_kopling_mobile/features/chat/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gsjnczwvixorgekrnvva.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdzam5jend2aXhvcmdla3JudnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MzU1NTMsImV4cCI6MjA5MzQxMTU1M30.IglDSBdnbWtadPmupW0FcCMa2Q2ZzX5vqibAmFur9tQ',
  );

  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Temu Kopling',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBrown),
      ),
      home: session != null ? const MainScreen() : const LoginScreen(),
    );
  }
}
