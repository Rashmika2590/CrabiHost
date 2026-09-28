import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';

// ── Repository provider ──────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Auth state ───────────────────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Auth notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  final AuthRepository _repo;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final valid = await _repo.validateToken();
    if (valid) {
      try {
        final user = await _repo.getProfile();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.login(email: email, password: password);
      final user = await _repo.getProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Guest Mode / Demo bypass for testing
  Future<void> loginGuest() async {
    state = state.copyWith(isLoading: true, error: null);
    const demoUser = UserModel(
      uid: 'guest_demo_host_001',
      email: 'demo.host@crabigo.com',
      firstName: 'Demo',
      lastName: 'Host',
      phone: '+94771234567',
      role: 'host',
    );
    state = const AuthState(status: AuthStatus.authenticated, user: demoUser);
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _repo.forgotPassword(email);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
