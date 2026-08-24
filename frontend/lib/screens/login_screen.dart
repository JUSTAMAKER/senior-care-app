import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _biometricAvailable = false;
  final _localAuth = LocalAuthentication();
  final _googleSignIn = GoogleSignIn(
    serverClientId:
        '316733259076-fhkuj7mlhctt251hp69kvhgoji9s52vc.apps.googleusercontent.com',
  );

  static const _green = Color.fromRGBO(26, 92, 56, 1);
  static const _bg = Color(0xFFf4f8f5);
  static const _border = Color(0xFFc8ddd0);
  static const _fieldBg = Color(0xFFf4f8f5);

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (canCheck && isDeviceSupported) {
        final savedToken = await AuthService.getAccessToken();
        if (mounted) {
          setState(() => _biometricAvailable = savedToken != null);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildLogoArea(),
              _buildLoginCard(),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 24),
                child: Text(
                  '© 2026 Smart Care System',
                  style: TextStyle(fontSize: 11, color: Color(0xFFafc8b8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoArea() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.home_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Smart Care',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: _green,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'AI Care System',
            style: TextStyle(fontSize: 12, color: Color(0xFF7a9a85)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFdde8e0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이메일
          _label('이메일'),
          _inputField(
            controller: _emailCtrl,
            hint: '이메일을 입력하세요',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // 비밀번호
          _label('비밀번호'),
          _inputField(
            controller: _passwordCtrl,
            hint: '비밀번호를 입력하세요',
            icon: _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            obscure: _obscure,
            onIconTap: () => setState(() => _obscure = !_obscure),
          ),

          // 비밀번호 찾기
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '비밀번호 찾기',
                style: TextStyle(fontSize: 12, color: _green),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 로그인 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleEmailLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // 구분선
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFdde8e0))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '또는',
                  style: TextStyle(fontSize: 11, color: Color(0xFFafc8b8)),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFdde8e0))),
            ],
          ),
          const SizedBox(height: 12),

          // Google 로그인
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _loading ? null : _handleGoogleLogin,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _border, width: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google 로고 SVG는 assets로 추가, 임시로 아이콘 사용
                  Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 18,
                    height: 18,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Google 계정으로 로그인',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1a3d28),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 회원가입
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              icon: const Icon(
                Icons.person_add_outlined,
                size: 16,
                color: _green,
              ),
              label: const Text(
                '회원가입',
                style: TextStyle(fontSize: 13, color: _green),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _border, width: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Face ID 버튼 (저장된 토큰 있을 때만 표시)
          if (_biometricAvailable) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider(color: Color(0xFFdde8e0))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Face ID로 빠른 로그인',
                    style: TextStyle(fontSize: 11, color: Color(0xFFafc8b8)),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFFdde8e0))),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _loading ? null : _handleFaceIDLogin,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFf4f8f5),
                      shape: BoxShape.circle,
                      border: Border.all(color: _border, width: 1),
                    ),
                    child: const Icon(
                      Icons.face_outlined,
                      size: 28,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '생체 인증',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7a9a85)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF7a9a85)),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    VoidCallback? onIconTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1a3d28)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFafc8b8), fontSize: 13),
        filled: true,
        fillColor: _fieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1),
        ),
        suffixIcon: GestureDetector(
          onTap: onIconTap,
          child: Icon(icon, size: 16, color: const Color(0xFFafc8b8)),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      print('googleUser: $googleUser');
      if (googleUser == null) {
        // 사용자가 취소한 경우
        setState(() => _loading = false);
        return;
      }

      final auth = await googleUser.authentication;
      print('idToken: ${auth.idToken}');
      print('accessToken: ${auth.accessToken}');
      if (auth.idToken != null) {
        final result = await AuthService.loginWithGoogle(
          idToken: auth.idToken!,
          name: googleUser.displayName ?? '',
          phone: '', // Google엔 전화번호 없으니 빈값, 나중에 추가 입력받기
        );
        print('result: ${result.success}, ${result.errorMessage}');

        if (result.success) {
          final role = result.user?['role'] as String?;
          await AuthService.saveTokens(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
            role: role,
          );
          if (mounted) {
            Navigator.pushReplacementNamed(context, AuthService.routeForRole(role));
          }
        } else {
          _showError(result.errorMessage!);
        }
      }
    } catch (e) {
      print('에러: $e');
      _showError('Google 로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showError('이메일과 비밀번호를 입력해주세요');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (result.success) {
        final role = result.user?['role'] as String?;
        await AuthService.saveTokens(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken!,
          role: role,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, AuthService.routeForRole(role));
        }
      } else {
        _showError(result.errorMessage!);
      }
    } catch (e) {
      _showError('서버에 연결할 수 없습니다: $e'); // 에러 내용 표시
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleFaceIDLogin() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Face ID로 로그인합니다',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      _showError('Face ID 인증에 실패했습니다');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }
}
