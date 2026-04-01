/// @file lib/features/auth/data/auth.repository.dart
/// @description Kullanıcı kayıt, giriş ve oturum kapatma API işlemlerini yöneten depo.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRepository(this._dio);

  Future<void> register(String fullName, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'full_name': fullName,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        // Kayıt başarılı, token dönmüyor çünkü giriş yapması için onay lazım.
        return;
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'Kayıt başarısız oldu.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final userJson = data['user'];

        // Token'ı cihaza güvenli bir şekilde kaydet
        await _secureStorage.write(key: 'jwt_token', value: token);

        return User.fromJson(userJson);
      }
    } on DioException catch (e) {
      // Backend'in gönderdiği hata mesajını yakala (örn: "Email veya şifre hatalı")
      final errorMessage = e.response?.data['error'] ?? 'Giriş başarısız oldu.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
    return null;
  }

  // Çıkış yaparken token'ı sil
  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
  }
}