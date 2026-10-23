import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ServerConnectionState { disconnected, connecting, connected, error }

class RemoteService extends ChangeNotifier {
  static final RemoteService _instance = RemoteService._internal();
  factory RemoteService() => _instance;
  RemoteService._internal();

  WebSocketChannel? _wsChannel;
  RawDatagramSocket? _udpSocket;
  String _serverIp = '';
  int _httpPort = 5000;
  int _udpPort = 5001;

  ServerConnectionState _state = ServerConnectionState.disconnected;
  ServerConnectionState get state => _state;
  bool get isConnected => _state == ServerConnectionState.connected;
  String get serverIp => _serverIp;
  int get httpPort => _httpPort;

  Future<void> connect(String ip, {int httpPort = 5000, int udpPort = 5001, String? pin}) async {
    _serverIp = ip.trim();
    _httpPort = httpPort;
    _udpPort = udpPort;
    _state = ServerConnectionState.connecting;
    notifyListeners();

    try {
      // 1. Inisialisasi UDP Socket untuk mouse movement
      _udpSocket?.close();
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      // 2. Inisialisasi WebSocket Channel
      final uri = Uri.parse('ws://$_serverIp:$_httpPort/ws');
      _wsChannel?.sink.close();
      _wsChannel = WebSocketChannel.connect(uri);

      _wsChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'auth_result' && data['status'] == 'ok') {
              _state = ServerConnectionState.connected;
              notifyListeners();
            }
          } catch (e) {
            // Ignore format error
          }
        },
        onDone: () {
          _state = ServerConnectionState.disconnected;
          notifyListeners();
        },
        onError: (err) {
          _state = ServerConnectionState.error;
          notifyListeners();
        },
      );

      _state = ServerConnectionState.connected;
      notifyListeners();

      if (pin != null && pin.isNotEmpty) {
        sendWsCommand({'type': 'auth', 'pin': pin});
      }
    } catch (e) {
      _state = ServerConnectionState.error;
      notifyListeners();
    }
  }

  void disconnect() {
    _wsChannel?.sink.close();
    _udpSocket?.close();
    _state = ServerConnectionState.disconnected;
    notifyListeners();
  }

  // Kirim perintah reliabel via WebSocket (Klik, Ketik, Shortcut, Power)
  void sendWsCommand(Map<String, dynamic> data) {
    if (_wsChannel != null && _state == ServerConnectionState.connected) {
      try {
        _wsChannel!.sink.add(jsonEncode(data));
      } catch (e) {
        debugPrint('Error kirim WebSocket: $e');
      }
    }
  }

  // Kirim delta gerakan mouse via UDP (Ultra Low Latency)
  void sendMouseMove(double dx, double dy, {double sensitivity = 1.0}) {
    if (_udpSocket != null && _serverIp.isNotEmpty) {
      try {
        final payload = jsonEncode({
          'type': 'move',
          'dx': dx,
          'dy': dy,
          'sensitivity': sensitivity,
        });
        _udpSocket!.send(utf8.encode(payload), InternetAddress(_serverIp), _udpPort);
      } catch (e) {
        // Fallback ke WebSocket jika UDP gagal
        sendWsCommand({
          'type': 'move',
          'dx': dx,
          'dy': dy,
          'sensitivity': sensitivity,
        });
      }
    }
  }
}
