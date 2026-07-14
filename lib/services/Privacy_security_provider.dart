import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dreamventz/config/supabase_config.dart';

enum PasswordChangeStatus { idle, loading, success, error }

class PasswordChangeState {
  final PasswordChangeStatus status;
  final String? errorMessage;

  const PasswordChangeState({
    this.status = PasswordChangeStatus.idle,
    this.errorMessage,
  });

  PasswordChangeState copyWith({
    PasswordChangeStatus? status,
    String? errorMessage,
  }) =>
      PasswordChangeState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class PrivacySecurityNotifier extends Notifier<PasswordChangeState> {
  @override
  PasswordChangeState build() => const PasswordChangeState();

  /// Works for email+password users.
  /// Google-only users cannot change password — call [isPasswordUser] first.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(status: PasswordChangeStatus.loading);
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Re-authenticate with current password first
      await SupabaseConfig.client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      // Now update to new password
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      state = state.copyWith(status: PasswordChangeStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: PasswordChangeStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: PasswordChangeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const PasswordChangeState();

  /// Returns true if the current user signed up with email+password.
  bool isPasswordUser() {
    final user = SupabaseConfig.currentUser;
    if (user == null) return false;
    // Supabase stores provider info in app_metadata
    final provider = user.appMetadata['provider'] as String?;
    return provider == 'email';
  }
}

final privacySecurityProvider =
    NotifierProvider<PrivacySecurityNotifier, PasswordChangeState>(
  PrivacySecurityNotifier.new,
);