/// @file lib/features/auth/domain/user_model.dart
/// @description Kullanıcı profili ve bakiye bilgilerini temsil eden veri modeli.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final double balance;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.balance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'], // Backend'deki db tag'i ile birebir aynı
      email: json['email'],
      role: json['role'],
      // Go backend'den double veya int gelebilir, num ile güvene alıyoruz
      balance: (json['balance'] as num).toDouble(),
    );
  }
}