import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:birrmetrics/core/storage/secure_storage.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      
      final token = res.data['access_token'];
      if (token != null) {
        await SecureStorage.saveToken(token);
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Registration failed');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = res.data['access_token'];
      if (token != null) {
        await SecureStorage.saveToken(token);
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  Future<bool> hasToken() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}