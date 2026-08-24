import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  
  // 로컬 개발 시 본인 IP로 변경 (localhost는 Android 에뮬레이터에서 안 됨)
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://13.238.255.200:8080',
  );

  // ───────────────────────────────
  // 회원가입 (이메일)
  // ───────────────────────────────
  static Future<AuthResult> signup({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    return _handleResponse(res);
  }

  // ───────────────────────────────
  // 로그인 (이메일)
  // ───────────────────────────────
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(res);
  }

  // ───────────────────────────────
  // Google 로그인/가입
  // ───────────────────────────────
  static Future<AuthResult> loginWithGoogle({
    required String idToken,
    required String name,
    required String phone,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': idToken,
        'name': name,
        'phone': phone,
      }),
    );
    return _handleResponse(res);
  }

  // ───────────────────────────────
  // 토큰 저장/조회/삭제
  // ───────────────────────────────
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    if (role != null) await _storage.write(key: 'user_role', value: role);
  }

  static Future<String?> getUserRole() async {
    return _storage.read(key: 'user_role');
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: 'access_token');
  }

  static Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: 'access_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static String routeForRole(String? role) {
    return role == 'elder' ? '/elder' : '/dashboard';
  }

  // ───────────────────────────────
  // 공통 응답 처리
  // ───────────────────────────────
  static AuthResult _handleResponse(http.Response res) {
    final body = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return AuthResult.success(
        accessToken: body['access_token'],
        refreshToken: body['refresh_token'],
        user: body['user'],
      );
    }

    // 에러 메시지는 Go 백엔드에서 오는 한국어 메시지 그대로 사용
    return AuthResult.failure(body['error'] ?? '알 수 없는 오류가 발생했습니다');
  }
}

// ───────────────────────────────
// 결과 모델
// ───────────────────────────────
class AuthResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  AuthResult._({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) => AuthResult._(
    success: true,
    accessToken: accessToken,
    refreshToken: refreshToken,
    user: user,
  );

  factory AuthResult.failure(String message) => AuthResult._(
    success: false,
    errorMessage: message,
  );
}