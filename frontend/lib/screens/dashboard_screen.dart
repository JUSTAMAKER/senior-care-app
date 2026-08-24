import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/mqtt_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _recentEvents = [];
  int _unreadCount = 0;
  Uint8List? _cameraFrame;
  StreamSubscription<Uint8List>? _frameSub;
  String _currentAction = '연결 중...';
  double _currentConfidence = 0.0;
  StreamSubscription<Map<String, dynamic>>? _actionSub;
  bool _cameraOnline = false;
  Timer? _offlineTimer;

  static const _green = Color(0xFF1a5c38);
  static const _bg = Color(0xFFf4f8f5);
  static const _border = Color(0xFFdde8e0);

  @override
  void initState() {
    super.initState();
    _fetchRecentEvents();
    _connectMqtt();
  }

  Future<void> _connectMqtt() async {
    await MqttService.connect();
    _frameSub = MqttService.frameStream.listen((bytes) {
      if (mounted) {
        setState(() {
          _cameraFrame = bytes;
          _cameraOnline = true;
        });
        _offlineTimer?.cancel();
        _offlineTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _cameraOnline = false);
        });
      }
    });
    _actionSub = MqttService.actionStream.listen((data) {
      if (mounted) setState(() {
        _currentAction = data['action'] as String? ?? '알 수 없음';
        _currentConfidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _frameSub?.cancel();
    _actionSub?.cancel();
    _offlineTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRecentEvents() async {
    try {
      final token = await AuthService.getAccessToken();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/events'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        final events = data.cast<Map<String, dynamic>>();
        if (mounted) {
          setState(() {
            _recentEvents = events.take(3).toList();
            _unreadCount = events.where((e) => e['resolved'] == false).length;
          });
        }
      }
    } catch (_) {}
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

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
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStatusCard(),
                    _buildCameraSection(),
                    _buildInfoGrid(),
                    _buildRecentAlerts(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    ));
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            '이순 ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1a3d28),
            ),
          ),
          const Text(
            '어르신 ▾',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    // 미확인 이벤트 중 가장 최근 것으로 상태 결정
    final unresolved = _recentEvents.where((e) => e['resolved'] == false).toList();
    final latestType = unresolved.isNotEmpty ? unresolved.first['event_type'] as String? : null;

    final Color dotColor;
    final Color bgColor;
    final Color iconColor;
    final IconData icon;
    final String title;
    final String subtitle;

    if (latestType == 'fall_detected') {
      dotColor = const Color(0xFFe05c5c);
      bgColor  = const Color(0xFFfdf0f0);
      iconColor = const Color(0xFFe05c5c);
      icon     = Icons.warning_amber_rounded;
      title    = '위험 — 낙상 감지';
      subtitle = '즉시 확인이 필요합니다';
    } else if (latestType == 'lying_down') {
      dotColor = const Color(0xFFe8942a);
      bgColor  = const Color(0xFFfff4e8);
      iconColor = const Color(0xFFe8942a);
      icon     = Icons.access_time_rounded;
      title    = '주의 — 장시간 누워있음';
      subtitle = '상태를 확인해주세요';
    } else {
      dotColor = const Color(0xFF2e7d52);
      bgColor  = const Color(0xFFe8f5ee);
      iconColor = _green;
      icon     = Icons.favorite_border;
      title    = '정상';
      subtitle = '모든 상태가 정상입니다';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: latestType != null ? dotColor.withOpacity(0.4) : _border,
          width: latestType != null ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: dotColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7a9a85)),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '실시간 모니터링',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1a3d28),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _cameraOnline ? Colors.red[400] : Colors.grey[500],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 6),
                    const SizedBox(width: 4),
                    Text(
                      _cameraOnline ? 'LIVE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _cameraFrame != null
                  ? Image.memory(
                      _cameraFrame!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white54),
                            SizedBox(height: 12),
                            Text('카메라 연결 중...',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _infoCard(
              icon: _currentAction == 'Fall Down'
                  ? Icons.warning_amber_rounded
                  : _currentAction == 'Lying Down'
                      ? Icons.access_time_rounded
                      : Icons.directions_walk,
              iconBg: _currentAction == 'Fall Down'
                  ? const Color(0xFFfdf0f0)
                  : _currentAction == 'Lying Down'
                      ? const Color(0xFFfff4e8)
                      : const Color(0xFFe8f5ee),
              iconColor: _currentAction == 'Fall Down'
                  ? const Color(0xFFe05c5c)
                  : _currentAction == 'Lying Down'
                      ? const Color(0xFFe8942a)
                      : _green,
              title: '현재 활동',
              value: _currentAction,
              sub: _currentConfidence > 0
                  ? '신뢰도 ${(_currentConfidence * 100).toStringAsFixed(1)}%'
                  : '분석 중...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xFF7a9a85)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1a3d28),
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Color(0xFFafc8b8)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('최근 알림',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1a3d28)),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications').then((_) => _fetchRecentEvents()),
                child: const Text('전체보기', style: TextStyle(fontSize: 11, color: _green)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentEvents.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Text('최근 알림이 없습니다', style: TextStyle(fontSize: 12, color: Color(0xFFafc8b8))),
            )
          else
            ..._recentEvents.map((e) {
              final isFall = e['event_type'] == 'fall_detected';
              final resolved = e['resolved'] == true;
              final color = isFall ? const Color(0xFFe05c5c) : const Color(0xFFe8942a);
              final text  = isFall ? '낙상 감지됨' : '장시간 누워있음';
              final time  = _formatTime(e['occurred_at'] as String? ?? '');
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: resolved ? const Color(0xFFafc8b8) : color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: resolved ? FontWeight.normal : FontWeight.w500,
                              color: const Color(0xFF1a3d28),
                            ),
                          ),
                          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFFafc8b8))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFFafc8b8)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': '홈'},
      {
        'icon': Icons.notifications_outlined,
        'activeIcon': Icons.notifications,
        'label': '알림',
      },
      {
        'icon': Icons.bar_chart_outlined,
        'activeIcon': Icons.bar_chart,
        'label': '기록',
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': '설정',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFdde8e0), width: 0.5)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = _currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 1) {
                  Navigator.pushNamed(context, '/notifications');
                } else if (i == 2) {
                  Navigator.pushReplacementNamed(context, '/records');
                }
                if (i == 3)
                  Navigator.pushReplacementNamed(context, '/settings');
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Icon(
                          active
                              ? items[i]['activeIcon'] as IconData
                              : items[i]['icon'] as IconData,
                          color: active ? _green : const Color(0xFFafc8b8),
                          size: 22,
                        ),
                        if (i == 1 && _unreadCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? _green : const Color(0xFFafc8b8),
                        fontWeight: active
                            ? FontWeight.w500
                            : FontWeight.normal,
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
