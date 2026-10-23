import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/remote_service.dart';

class TrackpadView extends StatefulWidget {
  const TrackpadView({super.key});

  @override
  State<TrackpadView> createState() => _TrackpadViewState();
}

class _TrackpadViewState extends State<TrackpadView> {
  final _service = RemoteService();
  double _sensitivity = 1.4;
  double _lastScrollY = 0;

  void _vibrate([int durationMs = 15]) {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Surface Area Trackpad + Side Scrollbar
          Expanded(
            child: Row(
              children: [
                // Trackpad Utama
                Expanded(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      _service.sendMouseMove(
                        details.delta.dx,
                        details.delta.dy,
                        sensitivity: _sensitivity,
                      );
                    },
                    onTap: () {
                      _vibrate();
                      _service.sendWsCommand({'type': 'click', 'button': 'left'});
                    },
                    onSecondaryTap: () {
                      _vibrate(30);
                      _service.sendWsCommand({'type': 'click', 'button': 'right'});
                    },
                    onLongPressStart: (_) {
                      _vibrate(40);
                      _service.sendWsCommand({'type': 'mouse_down', 'button': 'left'});
                    },
                    onLongPressEnd: (_) {
                      _vibrate(15);
                      _service.sendWsCommand({'type': 'mouse_up', 'button': 'left'});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1527),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Text(
                          'AREA TRACKPAD\n\n👆 Geser: Gerak Kursor\n👆 Ketuk: Klik Kiri\n✌️ Tekan Lama: Drag & Drop',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Side Scrollbar
                GestureDetector(
                  onVerticalDragStart: (details) {
                    _lastScrollY = details.localPosition.dy;
                  },
                  onVerticalDragUpdate: (details) {
                    final dy = details.localPosition.dy - _lastScrollY;
                    if (dy.abs() > 2) {
                      _service.sendWsCommand({'type': 'scroll', 'dy': -dy * 0.15, 'dx': 0});
                      _lastScrollY = details.localPosition.dy;
                    }
                  },
                  child: Container(
                    width: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'SCROLL',
                          style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Klik Kiri & Kanan Fisik Virtual
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _vibrate();
                      _service.sendWsCommand({'type': 'click', 'button': 'left'});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF131B2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: const Text('KLIK KIRI', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _vibrate(25);
                      _service.sendWsCommand({'type': 'click', 'button': 'right'});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF131B2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: const Text('KLIK KANAN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Slider Sensitivitas
          Row(
            children: [
              const Text('Sensitivitas: ', style: TextStyle(color: Colors.white60, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _sensitivity,
                  min: 0.5,
                  max: 3.0,
                  activeColor: const Color(0xFF38BDF8),
                  onChanged: (val) => setState(() => _sensitivity = val),
                ),
              ),
              Text('${_sensitivity.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
