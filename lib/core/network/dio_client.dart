/// @file lib/core/network/dio_client.dart
/// @description Merkezi HTTP istemcisi (Dio) yapılandırması ve interceptor yönetimi.
/// @author Onur Zaim
/// @license Yazılı izin alınmadan ticari amaçla kullanılamaz.

import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        // Sunucu IP adresimiz ve backend'in çalıştığı port
        baseUrl: 'http://localhost:1323',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Yazdığımız Interceptor'ı Dio'ya bağlıyoruz
    _dio.interceptors.add(AuthInterceptor());

    // Geliştirme aşamasında giden/gelen istekleri terminalde görmek için LogInterceptor
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));
  }

  // Sadece bu instance'ı dışarı açıyoruz
  Dio get dio => _dio;
}