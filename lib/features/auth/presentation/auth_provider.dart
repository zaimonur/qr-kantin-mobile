/// @file lib/features/auth/presentation/auth_provider.dart
/// @description Kullanıcı oturum durumunu ve bakiye güncellemelerini yöneten sağlayıcı.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth.repository.dart';
import '../domain/user_model.dart';
import '../../../core/network/dio_client.dart';

// 1. DioClient Provider'ı (Tüm repository'lerde ortak kullanılacak)
final dioClientProvider = Provider((ref) => DioClient());

// 2. AuthRepository Provider'ı
final authRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRepository(dioClient.dio);
});

// 3. Kullanıcının aktif durumunu (oturumunu) yöneten StateNotifier
class AuthNotifier extends StateNotifier<User?> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(null);

  Future<void> login(String email, String password) async {
    // API'den dönen User nesnesini Riverpod state'ine eşitliyoruz
    final user = await _repository.login(email, password);
    state = user;
  }
  //Bakiye güncellenmesi
  void updateBalance(double newBalance) {
    if (state != null) {
      state = User(
        id: state!.id,
        fullName: state!.fullName,
        email: state!.email,
        role: state!.role,
        balance: newBalance, // Mevcut kullanıcı verisini koruyarak sadece bakiyeyi günceller.
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = null; // State null olunca UI otomatik login ekranına döner
  }
}

// UI katmanından erişeceğimiz ana Provider
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});