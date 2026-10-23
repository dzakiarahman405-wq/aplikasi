import 'package:flutter/material.dart';
import '../services/remote_service.dart';
import 'trackpad_view.dart';
import 'shortcuts_view.dart';
import 'screen_mirror_view.dart';
import 'connect_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = RemoteService();
  int _currentIndex = 0;

  final List<Widget> _views = const [
    TrackpadView(),
    ShortcutsView(),
    ScreenMirrorView(),
  ];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!_service.isConnected && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ConnectScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131B2E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'PC: ${_service.serverIp}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off, color: Colors.redAccent),
            tooltip: 'Putuskan Koneksi',
            onPressed: () {
              _service.disconnect();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: const Color(0xFF131B2E),
        indicatorColor: const Color(0xFF38BDF8).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mouse_outlined, color: Colors.white60),
            selectedIcon: Icon(Icons.mouse, color: Color(0xFF38BDF8)),
            label: 'Trackpad',
          ),
          NavigationDestination(
            icon: Icon(Icons.keyboard_outlined, color: Colors.white60),
            selectedIcon: Icon(Icons.keyboard, color: Color(0xFF38BDF8)),
            label: 'Shortcut',
          ),
          NavigationDestination(
            icon: Icon(Icons.tv_outlined, color: Colors.white60),
            selectedIcon: Icon(Icons.tv, color: Color(0xFF38BDF8)),
            label: 'Layar PC',
          ),
        ],
      ),
    );
  }
}
