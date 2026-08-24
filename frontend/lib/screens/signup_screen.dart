import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  String _role = 'caregiver';

  static const _green = Color(0xFF1a5c38);
  static const _border = Color(0xFFc8ddd0);
  static const _fieldBg = Color(0xFFf4f8f5);
  static const _labelColor = Color(0xFF7a9a85);

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _pwCtrl.dispose(); _pwConfirmCtrl.dispose();
    super.dispose();
  }

  void _toggleAgreeAll(bool? val) {
    setState(() {
      _agreeAll = val ?? false;
      _agreeTerms = _agreeAll;
      _agreePrivacy = _agreeAll;
    });
  }

  void _updateAgreeAll() {
    setState(() => _agreeAll = _agreeTerms && _agreePrivacy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf4f8f5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('회원가입',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1a3d28)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFdde8e0)),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('가입 유형'),
              _roleCard(),
              _sectionLabel('기본 정보'),
              _infoCard(),
              _sectionLabel('비밀번호'),
              _passwordCard(),
              _termsCard(),
              _submitButton(),
              _loginLink(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _green),
    ),
  );

  Widget _roleCard() {
    return _card(Row(
      children: [
        Expanded(child: _roleOption('caregiver', Icons.person_outline, '보호자', '독거노인을 돌보는 분')),
        const SizedBox(width: 10),
        Expanded(child: _roleOption('elder', Icons.elderly_outlined, '대상자', '케어를 받는 독거노인')),
      ],
    ));
  }

  Widget _roleOption(String value, IconData icon, String title, String subtitle) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFe8f5ee) : const Color(0xFFf4f8f5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _green : _border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: selected ? _green : const Color(0xFFafc8b8)),
            const SizedBox(height: 6),
            Text(title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? _green : const Color(0xFF7a9a85),
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFFafc8b8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return _card(Column(
      children: [
        _field(label: '이름', ctrl: _nameCtrl, hint: '이름을 입력하세요',
          icon: Icons.person_outline,
          validator: (v) => v!.isEmpty ? '이름을 입력해주세요' : null,
        ),
        const SizedBox(height: 12),
        _field(label: '연락처', ctrl: _phoneCtrl, hint: '010-0000-0000',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [_PhoneFormatter()],
          validator: (v) {
            if (v!.isEmpty) return '연락처를 입력해주세요';
            if (!RegExp(r'^010-\d{4}-\d{4}$').hasMatch(v)) return '올바른 형식으로 입력해주세요';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _field(label: '이메일', ctrl: _emailCtrl, hint: '이메일을 입력하세요',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v!.isEmpty) return '이메일을 입력해주세요';
            if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다';
            return null;
          },
        ),
      ],
    ));
  }

  Widget _passwordCard() {
    return _card(Column(
      children: [
        _field(label: '비밀번호', ctrl: _pwCtrl, hint: '8자 이상 입력하세요',
          icon: _obscurePw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          obscure: _obscurePw,
          onIconTap: () => setState(() => _obscurePw = !_obscurePw),
          validator: (v) {
            if (v!.length < 8) return '비밀번호는 8자 이상이어야 합니다';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _field(label: '비밀번호 확인', ctrl: _pwConfirmCtrl, hint: '비밀번호를 다시 입력하세요',
          icon: _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          obscure: _obscureConfirm,
          onIconTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
          validator: (v) {
            if (v != _pwCtrl.text) return '비밀번호가 일치하지 않습니다';
            return null;
          },
        ),
      ],
    ));
  }

  Widget _termsCard() {
    return _card(Column(
      children: [
        _checkRow(
          checked: _agreeAll,
          label: '전체 동의',
          bold: true,
          onChanged: _toggleAgreeAll,
        ),
        const Divider(color: Color(0xFFdde8e0), height: 16),
        _checkRow(
          checked: _agreeTerms,
          label: '[필수] 서비스 이용약관 동의',
          onChanged: (v) { setState(() => _agreeTerms = v ?? false); _updateAgreeAll(); },
        ),
        const SizedBox(height: 6),
        _checkRow(
          checked: _agreePrivacy,
          label: '[필수] 개인정보 처리방침 동의',
          onChanged: (v) { setState(() => _agreePrivacy = v ?? false); _updateAgreeAll(); },
        ),
      ],
    ));
  }

  Widget _checkRow({required bool checked, required String label, bool bold = false, required ValueChanged<bool?> onChanged}) {
    return Row(
      children: [
        Checkbox(
          value: checked,
          onChanged: onChanged,
          activeColor: _green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: const BorderSide(color: _border, width: 0.5),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 6),
        Text(label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF7a9a85),
            fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _loading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('가입 완료', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
        ),
      ),
    );
  }

  Widget _loginLink() => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('이미 계정이 있으신가요? ', style: TextStyle(fontSize: 12, color: Color(0xFFafc8b8))),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('로그인', style: TextStyle(fontSize: 12, color: _green)),
        ),
      ],
    ),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFdde8e0), width: 0.5),
    ),
    child: child,
  );

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onIconTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 11, color: _labelColor),
          children: const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFe05c5c)))],
        )),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1a3d28)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFafc8b8), fontSize: 12),
            filled: true,
            fillColor: _fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _green, width: 1)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFe05c5c), width: 0.5)),
            suffixIcon: GestureDetector(
              onTap: onIconTap,
              child: Icon(icon, size: 15, color: const Color(0xFFafc8b8)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms || !_agreePrivacy) {
      _showError('필수 약관에 동의해주세요');
      return;
    }
    setState(() => _loading = true);
    try {
      await _signupWithEmail();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signupWithEmail() async {
    final result = await AuthService.signup(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text,
      role: _role,
    );
    if (result.success) {
      await AuthService.saveTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken!,
        role: _role,
      );
      if (mounted) Navigator.pushReplacementNamed(context, AuthService.routeForRole(_role));
    } else {
      _showError(result.errorMessage!);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;
    if (digits.length >= 4 && digits.length <= 7) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else if (digits.length > 7) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, digits.length.clamp(0, 11))}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}