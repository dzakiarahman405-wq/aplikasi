import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/remote_service.dart';

class ShortcutsView extends StatefulWidget {
  const ShortcutsView({super.key});

  @override
  State<ShortcutsView> createState() => _ShortcutsViewState();
}

class _ShortcutsViewState extends State<ShortcutsView> {
  final _service = RemoteService();
  final _textController = TextEditingController();

  void _vibrate([int durationMs = 15]) {
    HapticFeedback.lightImpact();
  }

  void _sendText() {
    final text = _textController.text;
    if (text.isNotEmpty) {
      _vibrate();
      _service.sendWsCommand({'type': 'type_text', 'text': text});
      _textController.clear();
    }
  }

  void _sendKey(String key) {
    _vibrate();
    _service.sendWsCommand({'type': 'key_press', 'key': key});
  }

  void _sendHotkey(List<String> keys) {
    _vibrate(20);
    _service.sendWsCommand({'type': 'hotkey', 'keys': keys});
  }

  void _sendMedia(String action) {
    _vibrate();
    _service.sendWsCommand({'type': 'media', 'action': action});
  }

  void _sendPower(String action) {
    _vibrate(30);
    if (action == 'shutdown' || action == 'restart') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF131B2E),
          title: Text('${action.toUpperCase()} Komputer?'),
          content: Text('Yakin ingin melakukan $action sekarang? Komputer akan dimatikan/direstart dalam 5 detik.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(ctx);
                _service.sendWsCommand({'type': 'power', 'action': action, 'delay': 5});
              },
              child: const Text('Lanjutkan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      _service.sendWsCommand({'type': 'power', 'action': action});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. Text Input Field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ketik teks ke PC...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF131B2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sendText,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text('Kirim', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2. Tombol Navigasi Utama
        _buildSectionHeader('Tombol Navigasi'),
        Row(
          children: [
            _buildKeyBtn('ESC', () => _sendKey('esc')),
            _buildKeyBtn('TAB', () => _sendKey('tab')),
            _buildKeyBtn('⌫ HAPUS', () => _sendKey('backspace')),
            _buildKeyBtn('⏎ ENTER', () => _sendKey('enter')),
          ],
        ),
        const SizedBox(height: 14),

        // 3. Tombol Shortcut Windows
        _buildSectionHeader('Shortcut Windows'),
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            _buildGridBtn('WIN', () => _sendHotkey(['win'])),
            _buildGridBtn('Desktop', () => _sendHotkey(['win', 'd'])),
            _buildGridBtn('Alt+Tab', () => _sendHotkey(['alt', 'tab'])),
            _buildGridBtn('Alt+F4', () => _sendHotkey(['alt', 'f4'])),
            _buildGridBtn('Copy', () => _sendHotkey(['ctrl', 'c'])),
            _buildGridBtn('Paste', () => _sendHotkey(['ctrl', 'v'])),
            _buildGridBtn('Undo', () => _sendHotkey(['ctrl', 'z'])),
            _buildGridBtn('Pilih Semua', () => _sendHotkey(['ctrl', 'a'])),
          ],
        ),
        const SizedBox(height: 18),

        // 4. Kontrol Audio & Media
        _buildSectionHeader('Audio & Media Player'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF131B2E), borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Row(
                children: [
                  _buildActionBtn(Icons.volume_down, 'Vol -', () => _sendMedia('vol_down')),
                  _buildActionBtn(Icons.volume_off, 'Mute', () => _sendMedia('vol_mute')),
                  _buildActionBtn(Icons.volume_up, 'Vol +', () => _sendMedia('vol_up')),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              Row(
                children: [
                  _buildActionBtn(Icons.skip_previous, 'Prev', () => _sendMedia('prev')),
                  _buildActionBtn(Icons.play_arrow, 'Play/Pause', () => _sendMedia('play_pause')),
                  _buildActionBtn(Icons.skip_next, 'Next', () => _sendMedia('next')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 5. Daya & Power
        _buildSectionHeader('Daya Komputer'),
        Row(
          children: [
            _buildActionBtn(Icons.lock, 'Kunci', () => _sendPower('lock')),
            _buildActionBtn(Icons.nightlight_round, 'Sleep', () => _sendPower('sleep'), color: Colors.amber),
            _buildActionBtn(Icons.restart_alt, 'Restart', () => _sendPower('restart'), color: Colors.orange),
            _buildActionBtn(Icons.power_settings_new, 'Shutdown', () => _sendPower('shutdown'), color: Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1),
      ),
    );
  }

  Widget _buildKeyBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF131B2E),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildGridBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF131B2E),
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap, {Color color = const Color(0xFF38BDF8)}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
