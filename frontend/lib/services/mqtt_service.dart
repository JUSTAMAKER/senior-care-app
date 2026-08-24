import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static const _broker = '13.238.255.200';
  static const _port = 1883;
  static const topicFrame  = 'senior_care/camera/frame';
  static const topicAction = 'senior_care/action';

  static MqttServerClient? _client;
  static final StreamController<Uint8List> _frameController =
      StreamController<Uint8List>.broadcast();
  static final StreamController<Map<String, dynamic>> _actionController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Uint8List> get frameStream   => _frameController.stream;
  static Stream<Map<String, dynamic>> get actionStream => _actionController.stream;

  static Future<void> connect() async {
    final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_broker, clientId, _port);
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 30;
    _client!.connectTimeoutPeriod = 10000;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _client!.connectionMessage = connMsg;

    try {
      debugPrint('[MQTT] 연결 시도: $_broker:$_port');
      final status = await _client!.connect();
      debugPrint('[MQTT] 연결 상태: ${status?.state}');
    } catch (e) {
      debugPrint('[MQTT] 연결 예외: $e');
      _client!.disconnect();
      return;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('[MQTT] 토픽 구독: $topicFrame, $topicAction');
      _client!.subscribe(topicFrame,  MqttQos.atMostOnce);
      _client!.subscribe(topicAction, MqttQos.atMostOnce);
      _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> msgs) {
        for (final msg in msgs) {
          final pub = msg.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
              pub.payload.message);
          if (msg.topic == topicFrame) {
            try {
              final bytes = base64Decode(payload);
              _frameController.add(bytes);
            } catch (e) {
              debugPrint('[MQTT] 프레임 디코딩 실패: $e');
            }
          } else if (msg.topic == topicAction) {
            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              _actionController.add(data);
            } catch (e) {
              debugPrint('[MQTT] 액션 디코딩 실패: $e');
            }
          }
        }
      });
    } else {
      debugPrint('[MQTT] 연결 실패: ${_client!.connectionStatus}');
    }
  }

  static void _onConnected() => debugPrint('[MQTT] onConnected 콜백');
  static void _onDisconnected() {
    debugPrint('[MQTT] 연결 끊김 — 3초 후 재연결');
    Future.delayed(const Duration(seconds: 3), connect);
  }

  static void disconnect() => _client?.disconnect();
}
