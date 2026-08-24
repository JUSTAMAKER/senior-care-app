import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ElderDashboardScreen extends StatefulWidget {
  const ElderDashboardScreen({super.key});

  @override
  State<ElderDashboardScreen> createState() => _ElderDashboardScreenState();
}

class _ElderDashboardScreenState extends State<ElderDashboardScreen> {
  int _currentIndex = 0;
  bool _iAmOkayLoading = false;

  static const _green = Color(0xFF1a5c38);
  static const _bg = Color(0xFFf4f8f5);
  static const _border = Color(0xFFdde8e0);

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('앱 종료', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('종료', style: TextStyle(color: Color(0xFF1a5c38), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHome(),
              _buildNotifications(),
              _buildSettings(),
            ],
          ),
        ),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  // ─── 홈 ───────────────────────────────────────────────
  Widget _buildHome() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatusCard(),
                const SizedBox(height: 20),
                _buildIAmOkayButton(),
                const SizedBox(height: 20),
                _buildSOSButton(),
                const SizedBox(height: 20),
                _buildRobotCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Smart Care',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '정상',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a3d28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '모든 상태가 정상입니다',
              style: TextStyle(fontSize: 15, color: Color(0xFF7a9a85)),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFdde8e0)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(Icons.thermostat_outlined, '24°C', '온도'),
              _buildStatusItem(Icons.water_drop_outlined, '55%', '습도'),
              _buildStatusItem(Icons.directions_walk_outlined, '걷기 중', '활동'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: _green),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1a3d28),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7a9a85)),
        ),
      ],
    );
  }

  Widget _buildIAmOkayButton() {
    return GestureDetector(
      onTap: _iAmOkayLoading ? null : _handleIAmOkay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _iAmOkayLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Column(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    '저 괜찮아요',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '보호자에게 안심 신호를 보냅니다',
                    style: TextStyle(fontSize: 13, color: Color(0xFFa8d4b8)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: _handleSOS,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36),
            SizedBox(height: 8),
            Text(
              'SOS 긴급 호출',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '보호자에게 즉시 알림을 보냅니다',
              style: TextStyle(fontSize: 13, color: Color(0xFFffcdd2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRobotCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFe8f5ee),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.smart_toy_outlined, color: _green, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '케어 로봇',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a3d28),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '연결됨 · 대기 중',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7a9a85)),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _green, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text(
              '대화하기',
              style: TextStyle(fontSize: 13, color: _green),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 알림 ──────────────────────────────────────────────
  Widget _buildNotifications() {
    final alerts = [
      {'time': '오늘 10:30', 'msg': '보호자가 확인했습니다', 'icon': Icons.person_outline, 'color': _green},
      {'time': '오늘 09:15', 'msg': '케어 로봇이 인사했습니다', 'icon': Icons.smart_toy_outlined, 'color': const Color(0xFF1565C0)},
      {'time': '어제 20:00', 'msg': '저 괜찮아요 신호를 보냈습니다', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF4CAF50)},
    ];

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '알림',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1a3d28),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = alerts[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (a['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['msg'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1a3d28),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            a['time'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7a9a85)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── 설정 ──────────────────────────────────────────────
  Widget _buildSettings() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '설정',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1a3d28),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingItem(Icons.person_outline, '내 정보'),
              _buildSettingItem(Icons.notifications_outlined, '알림 설정'),
              _buildSettingItem(Icons.phone_outlined, '보호자 연락처'),
              _buildSettingItem(Icons.smart_toy_outlined, '로봇 설정'),
              const SizedBox(height: 16),
              _buildSettingItem(Icons.logout, '로그아웃', isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String label, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF1a3d28);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
        ),
        trailing: isDestructive
            ? null
            : const Icon(Icons.chevron_right, color: Color(0xFFafc8b8), size: 20),
        onTap: isDestructive ? _handleLogout : () {},
      ),
    );
  }

  // ─── 하단 네비게이션 ────────────────────────────────────
  Widget _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      selectedItemColor: _green,
      unselectedItemColor: const Color(0xFFafc8b8),
      backgroundColor: Colors.white,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: '알림'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '설정'),
      ],
    );
  }

  // ─── 이벤트 핸들러 ──────────────────────────────────────
  Future<void> _handleIAmOkay() async {
    setState(() => _iAmOkayLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _iAmOkayLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('보호자에게 안심 신호를 보냈습니다 ✓'),
          backgroundColor: Color(0xFF1a5c38),
        ),
      );
    }
  }

  void _handleSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'SOS 긴급 호출',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F)),
        ),
        content: const Text(
          '보호자에게 긴급 알림을 보내시겠습니까?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFF7a9a85))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('긴급 알림을 보냈습니다'),
                  backgroundColor: Color(0xFFD32F2F),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('호출하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
