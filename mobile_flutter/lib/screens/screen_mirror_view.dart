import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/remote_service.dart';

class ScreenMirrorView extends StatefulWidget {
  const ScreenMirrorView({super.key});

  @override
  State<ScreenMirrorView> createState() => _ScreenMirrorViewState();
}

class _ScreenMirrorViewState extends State<ScreenMirrorView> {
  final _service = RemoteService();
  bool _isStreaming = true;
  final GlobalKey _imageKey = GlobalKey();

  void _onTapScreen(TapUpDetails details) {
    HapticFeedback.lightImpact();
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final localPos = details.localPosition;

      // Normalisasi koordinat ke skala 0.0 - 1.0
      final normX = (localPos.dx / size.width).clamp(0.0, 1.0);
      final normY = (localPos.dy / size.height).clamp(0.0, 1.0);

      _service.sendWsCommand({
        'type': 'tap_coordinate',
        'x': normX,
        'y': normY,
        'button': 'left',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamUrl = 'http://${_service.serverIp}:${_service.httpPort}/stream.mjpg';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ketuk layar untuk klik di PC', style: TextStyle(color: Colors.white54, fontSize: 12)),
              TextButton.icon(
                onPressed: () {
                  setState(() => _isStreaming = !_isStreaming);
                },
                icon: Icon(_isStreaming ? Icons.pause : Icons.play_arrow, size: 18),
                label: Text(_isStreaming ? 'Jeda' : 'Lanjut'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: _isStreaming
                    ? GestureDetector(
                        onTapUp: _onTapScreen,
                        child: Image.network(
                          streamUrl,
                          key: _imageKey,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'Gagal memuat stream layar.\nPastikan server aktif dan izinkan koneksi LAN.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54),
                              ),
                            );
                          },
                        ),
                      )
                    : const Text('Stream Dijeda', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
