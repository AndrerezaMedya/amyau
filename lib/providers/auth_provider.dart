import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../core/services/local_storage_service.dart';

/// State untuk authentication
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state class
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// Auth Notifier dengan Riverpod
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient? _supabase;

  AuthNotifier(this._supabase) : super(const AuthState()) {
    _checkCurrentSession();
  }

  /// Check session saat app start
  Future<void> _checkCurrentSession() async {
    // If Supabase not initialized, go to unauthenticated state
    if (_supabase == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final session = _supabase!.auth.currentSession;
      if (session != null) {
        // PENTING: Buka user boxes sebelum load profile
        await LocalStorageService.openUserBoxes(session.user.id);
        await _loadUserProfile(session.user.id);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error: $e',
      );
    }
  }

  /// Load user profile dari Supabase
  Future<void> _loadUserProfile(String userId) async {
    if (_supabase == null) return;

    try {
      final response =
          await _supabase!.from('users').select().eq('id', userId).single();

      final user = UserModel.fromJson(response);

      // PENTING: Buka user-specific storage boxes
      await LocalStorageService.openUserBoxes(userId);
      await LocalStorageService.saveCurrentUser(user);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      // Jika profile tidak ada, gunakan data dari session
      final sessionUser = _supabase!.auth.currentUser;
      if (sessionUser != null) {
        final user = UserModel(
          id: sessionUser.id,
          username: sessionUser.email ?? 'User',
          createdAt: DateTime.now(),
        );

        // PENTING: Buka user-specific storage boxes
        await LocalStorageService.openUserBoxes(sessionUser.id);
        await LocalStorageService.saveCurrentUser(user);

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Gagal memuat profil pengguna',
        );
      }
    }
  }

  /// Login dengan username dan password
  Future<void> login(String email, String password) async {
    if (_supabase == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Tidak dapat terhubung ke server',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _supabase!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Login gagal. Periksa kredensial Anda.',
        );
      }
    } on AuthException catch (e) {
      String message = 'Terjadi kesalahan saat login';

      if (e.message.contains('Invalid login credentials')) {
        message = 'Email atau password salah';
      } else if (e.message.contains('Email not confirmed')) {
        message = 'Email belum dikonfirmasi';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Tidak dapat terhubung ke server',
      );
    }
  }

  /// Sign Up - Registrasi user baru
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String gender,
  }) async {
    if (_supabase == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Tidak dapat terhubung ke server',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _supabase!.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'gender': gender,
        },
      );

      if (response.user != null) {
        // Trigger function akan auto-create user profile dengan SECURITY DEFINER
        // Jadi tidak perlu manual insert lagi

        // Check apakah perlu email confirmation
        if (response.session != null) {
          // Langsung login (email confirmation disabled)
          await _loadUserProfile(response.user!.id);
        } else {
          // Perlu email confirmation
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage:
                'Pendaftaran berhasil! Silakan cek email untuk konfirmasi.',
          );
        }
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Gagal mendaftar. Coba lagi.',
        );
      }
    } on AuthException catch (e) {
      String message = 'Terjadi kesalahan saat mendaftar';

      if (e.message.contains('already registered')) {
        message = 'Email sudah terdaftar. Silakan login.';
      } else if (e.message.contains('invalid')) {
        message = 'Format email tidak valid';
      } else if (e.message.contains('weak password')) {
        message = 'Password terlalu lemah (minimal 6 karakter)';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Tidak dapat terhubung ke server: $e',
      );
    }
  }

  /// Logout - Clear all user data to prevent data leakage
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      await _supabase?.auth.signOut();

      // PENTING: Clear semua data user untuk mencegah kebocoran
      await LocalStorageService.clearAll();

      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      // Tetap clear local data meskipun signOut gagal
      await LocalStorageService.clearAll();

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Gagal logout',
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider untuk Supabase client
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (e) {
    return null;
  }
});

/// Provider untuk Auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthNotifier(supabase);
});

/// Provider untuk current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// Provider untuk auth status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
