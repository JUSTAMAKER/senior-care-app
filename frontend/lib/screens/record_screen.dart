import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  static const _green = Color(0xFF1a5c38);
  static const _bg = Color(0xFFf4f8f5);
  static const _border = Color(0xFFdde8e0);

  String _selectedFilter = '전체';
  final List<String> _filters = ['전체', '정상', '주의', '위험'];

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
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _typeOf(Map<String, dynamic> e) {
    final t = e['event_type'] as String? ?? '';
    if (t == 'fall_detected') return '위험';
    if (t == 'lying_down') return '주의';
    return '정상';
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == '전체') return _events;
    return _events.where((e) => _typeOf(e) == _selectedFilter).toList();
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final day = DateTime(dt.year, dt.month, dt.day);
      final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (day == today) return '오늘 $hm';
      if (day == yesterday) return '어제 $hm';
      return '${dt.month}/${dt.day} $hm';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text('기록',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1a3d28)),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: _filters.map((f) {
                  final active = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? _green : const Color(0xFFf4f8f5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? _green : const Color(0xFFc8ddd0),
                          width: 0.5,
                        ),
                      ),
                      child: Text(f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                          color: active ? Colors.white : const Color(0xFF7a9a85),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _green))
                  : RefreshIndicator(
                      onRefresh: _fetchEvents,
                      color: _green,
                      child: _filtered.isEmpty
                          ? const Center(
                              child: Text('해당하는 기록이 없습니다',
                                style: TextStyle(fontSize: 13, color: Color(0xFFafc8b8)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final record = _filtered[index];
                                final timeStr = _formatTime(record['occurred_at'] as String? ?? '');
                                final dateLabel = timeStr.split(' ')[0];
                                final prevDateLabel = index == 0
                                    ? null
                                    : _formatTime(_filtered[index - 1]['occurred_at'] as String? ?? '').split(' ')[0];
                                final showDate = index == 0 || dateLabel != prevDateLabel;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (showDate) ...[
                                      if (index != 0) const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(dateLabel,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _green),
                                        ),
                                      ),
                                    ],
                                    _recordCard(record, timeStr),
                                  ],
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(context),
    );
  }

  Widget _recordCard(Map<String, dynamic> e, String timeStr) {
    final type = _typeOf(e);
    final eventType = e['event_type'] as String? ?? '';
    final isFall = eventType == 'fall_detected';
    final isLying = eventType == 'lying_down';
    final location = e['location'] as String? ?? '';
    final confidence = ((e['confidence'] as num?) ?? 0) * 100;

    final Color color;
    final Color bgColor;
    final IconData icon;
    final String activity;
    final String desc;

    if (isFall) {
      color = const Color(0xFFe05c5c);
      bgColor = const Color(0xFFfdf0f0);
      icon = Icons.warning_amber_rounded;
      activity = '낙상 감지';
      desc = '${location.isNotEmpty ? '$location에서 ' : ''}낙상이 감지되었습니다. (신뢰도 ${confidence.toStringAsFixed(0)}%)';
    } else if (isLying) {
      color = const Color(0xFFe8942a);
      bgColor = const Color(0xFFfff4e8);
      icon = Icons.access_time_rounded;
      activity = '장시간 누워있음';
      desc = '${location.isNotEmpty ? '$location에서 ' : ''}장시간 누워있는 상태가 감지되었습니다.';
    } else {
      color = const Color(0xFF2e7d52);
      bgColor = const Color(0xFFe8f5ee);
      icon = Icons.directions_walk;
      activity = e['action'] as String? ?? '활동 감지';
      desc = '활동이 감지되었습니다.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
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
                    Text(activity,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1a3d28)),
                    ),
                    _typeBadge(type, color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF7a9a85))),
                const SizedBox(height: 6),
                Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFFafc8b8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
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
          final active = i == 2;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 0) Navigator.pushReplacementNamed(context, '/dashboard');
                if (i == 1) Navigator.pushNamed(context, '/notifications');
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
