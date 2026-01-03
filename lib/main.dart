import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Locale init error: $e');
  }

  // Initialize Hive and Local Storage (PENTING: harus sebelum Supabase!)
  try {
    await LocalStorageService.initialize();
  } catch (e) {
    debugPrint('LocalStorage init error: $e');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Initialize Notifications (safe for Android 14+)
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(
    const ProviderScope(
      child: MutabaahYaumiApp(),
    ),
  );
}

class MutabaahYaumiApp extends ConsumerWidget {
  const MutabaahYaumiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Amal Syarafi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.initial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.status == AuthStatus.authenticated) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
