import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _green = Color(0xFF1a5c38);
  static const _bg = Color(0xFFf4f8f5);
  static const _border = Color(0xFFdde8e0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text('설정',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1a3d28),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 내 프로필
                  _sectionLabel('내 프로필'),
                  _profileCard(
                    name: '권찬솔',
                    sub: 'kwonchansol@gmail.com',
                    icon: Icons.person_outline,
                    iconBg: const Color(0xFFe8f5ee),
                    iconColor: _green,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),

                  // 어르신 프로필
                  _sectionLabel('담당 어르신'),
                  _profileCard(
                    name: '이순',
                    sub: '서울시 종로구 · 84세',
                    icon: Icons.elderly_outlined,
                    iconBg: const Color(0xFFfff4e8),
                    iconColor: const Color(0xFFe8942a),
                    onTap: () {},
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe8f5ee),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('모니터링 중',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 앱 설정
                  _sectionLabel('앱 설정'),
                  _settingsCard([
                    _settingsRow(
                      icon: Icons.notifications_outlined,
                      iconBg: const Color(0xFFe8f5ee),
                      iconColor: _green,
                      label: '알림 설정',
                      onTap: () {},
                    ),
                    const Divider(color: Color(0xFFf4f8f5), height: 1),
                    _settingsRow(
                      icon: Icons.lock_outline,
                      iconBg: const Color(0xFFe8f5ee),
                      iconColor: _green,
                      label: '개인정보 처리방침',
                      onTap: () {},
                    ),
                    const Divider(color: Color(0xFFf4f8f5), height: 1),
                    _settingsRow(
                      icon: Icons.info_outline,
                      iconBg: const Color(0xFFe8f5ee),
                      iconColor: _green,
                      label: '앱 버전',
                      onTap: null,
                      trailing: const Text('1.0.0',
                        style: TextStyle(fontSize: 12, color: Color(0xFFafc8b8)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // 로그아웃
                  _sectionLabel('계정'),
                  _settingsCard([
                    _settingsRow(
                      icon: Icons.logout,
                      iconBg: const Color(0xFFfdf0f0),
                      iconColor: const Color(0xFFe05c5c),
                      label: '로그아웃',
                      labelColor: const Color(0xFFe05c5c),
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(context),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _green,
        ),
      ),
    );
  }

  Widget _profileCard({
    required String name,
    required String sub,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1a3d28),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(sub,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7a9a85)),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing
            else const Icon(Icons.chevron_right, size: 18, color: Color(0xFFafc8b8)),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    Color? labelColor,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: labelColor ?? const Color(0xFF1a3d28),
                ),
              ),
            ),
            trailing ?? (onTap != null
              ? const Icon(Icons.chevron_right, size: 18, color: Color(0xFFafc8b8))
              : const SizedBox()),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1a3d28)),
        ),
        content: const Text('정말 로그아웃 하시겠습니까?',
          style: TextStyle(fontSize: 13, color: Color(0xFF7a9a85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
              style: TextStyle(color: Color(0xFF7a9a85)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('로그아웃',
              style: TextStyle(color: Color(0xFFe05c5c), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': '홈'},
      {'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications, 'label': '알림'},
      {'icon': Icons.bar_chart_outlined, 'activeIcon': Icons.bar_chart, 'label': '기록'},
      {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings, 'label': '설정'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFdde8e0), width: 0.5)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == 3; // 설정 탭 활성
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 0) Navigator.pushReplacementNamed(context, '/dashboard');
                if (i == 1) Navigator.pushReplacementNamed(context, '/notifications');
                if (i == 2) Navigator.pushReplacementNamed(context, '/records');
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active
                        ? items[i]['activeIcon'] as IconData
                        : items[i]['icon'] as IconData,
                      color: active ? _green : const Color(0xFFafc8b8),
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(items[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? _green : const Color(0xFFafc8b8),
                        fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}