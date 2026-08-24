import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _green = Color(0xFF1a5c38);
  static const _bg = Color(0xFFf4f8f5);
  static const _border = Color(0xFFdde8e0);

  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _loading = true);
    try {
      final token = await AuthService.getAccessToken();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/events'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() => _events = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      print('[알림] 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolveEvent(String id) async {
    try {
      final token = await AuthService.getAccessToken();
      await http.patch(
        Uri.parse('${AuthService.baseUrl}/api/events/$id/resolve'),
        headers: {'Authorization': 'Bearer $token'},
      );
      _fetchEvents();
    } catch (e) {
      print('[알림] 확인 처리 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _events.where((e) => e['resolved'] == false).toList();
    final read   = _events.where((e) => e['resolved'] == true).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('알림',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1a3d28)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: _green),
                    onPressed: _fetchEvents,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _green))
                  : _events.isEmpty
                      ? const Center(
                          child: Text('알림이 없습니다', style: TextStyle(color: Color(0xFF7a9a85))),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchEvents,
                          color: _green,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (unread.isNotEmpty) ...[
                                _sectionLabel('읽지 않은 알림'),
                                ...unread.map((e) => _eventCard(e)),
                                const SizedBox(height: 8),
                              ],
                              if (read.isNotEmpty) ...[
                                _sectionLabel('확인된 알림'),
                                ...read.map((e) => _eventCard(e)),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(context),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _green),
    ),
  );

  Widget _eventCard(Map<String, dynamic> e) {
    final bool resolved = e['resolved'] == true;
    final eventType = e['event_type'] as String? ?? '';
    final isFall = eventType == 'fall_detected';

    final color = isFall ? const Color(0xFFe05c5c) : const Color(0xFFe8942a);
    final icon  = isFall ? Icons.warning_amber_rounded : Icons.access_time_rounded;
    final title = isFall ? '낙상 감지됨' : '장시간 누워있음';
    final location = e['location'] as String? ?? '';
    final confidence = ((e['confidence'] as num?) ?? 0) * 100;
    final occurredAt = e['occurred_at'] as String? ?? '';
    final timeStr = _formatTime(occurredAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: resolved ? Colors.white : const Color(0xFFfff5f5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resolved ? _border : color.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: resolved ? FontWeight.normal : FontWeight.w600,
                        color: const Color(0xFF1a3d28),
                      ),
                    ),
                    if (!resolved)
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$location · 신뢰도 ${confidence.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7a9a85)),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(timeStr,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFafc8b8)),
                    ),
                    if (!resolved)
                      GestureDetector(
                        onTap: () => _resolveEvent(e['id'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('확인 완료',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
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
          final active = i == 1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 0) Navigator.pushReplacementNamed(context, '/dashboard');
                if (i == 2) Navigator.pushReplacementNamed(context, '/records');
                if (i == 3) Navigator.pushReplacementNamed(context, '/settings');
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? items[i]['activeIcon'] as IconData : items[i]['icon'] as IconData,
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
