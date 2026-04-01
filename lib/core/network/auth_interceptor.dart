/// @file lib/core/network/auth_interceptor.dart
/// @description API isteklerine otomatik olarak JWT token ekleyen güvenlik katmanı.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Cihazın şifreli deposundan token'ı oku
    final token = await _secureStorage.read(key: 'jwt_token');

    // Eğer token varsa ve istek bir Auth (login/register) isteği değilse header'a ekle
    if (token != null && !options.path.contains('/auth/')) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // İsteği yoluna devam ettir
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Eğer backend 401 (Unauthorized) dönerse, token süresi bitmiş demektir.
    // İleride buraya otomatik çıkış yapma (logout) mantığı eklenebilir.
    if (err.response?.statusCode == 401) {
      // TODO: Kullanıcıyı login ekranına at ve token'ı sil
    }
    super.onError(err, handler);
  }
}