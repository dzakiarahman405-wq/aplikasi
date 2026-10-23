"""
Main Remote Server & Agent
Menangani WebSockets, HTTP Static PWA, MJPEG Screen Stream, dan UDP Fast-Input.
"""

import os
import sys
import json
import time
import socket
import asyncio
import threading
from aiohttp import web, WSMsgType

from win_input import controller
from screen_capture import screen_engine

# Coba import qrcode untuk kemudahan koneksi di terminal
try:
    import qrcode
    HAS_QR = True
except ImportError:
    HAS_QR = False

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False

DEFAULT_HTTP_PORT = 5000
DEFAULT_UDP_PORT = 5001
CONFIG_PIN = os.environ.get("REMOTE_PIN", None)  # Kosongkan jika tanpa PIN


def get_local_ip() -> str:
    """Deteksi IP lokal aktif yang terhubung ke Wi-Fi / LAN."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Menghubungkan ke IP umum (tidak mengirim paket sebenarnya) untuk deteksi interface aktif
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def print_banner(ip: str, port: int, pin: str = None):
    """Cetak petunjuk koneksi dan QR code di terminal."""
    url = f"http://{ip}:{port}"
    print("\n" + "=" * 60)
    print("🚀 NATIVE PC REMOTE SERVER SEDANG BERJALAN")
    print("=" * 60)
    print(f"👉 Buka browser di Smartphone Anda:")
    print(f"   \033[1;32m{url}\033[0m")
    if pin:
        print(f"🔐 PIN Keamanan : \033[1;33m{pin}\033[0m")
    else:
        print("🔓 Mode Keamanan : Akses Terbuka (LAN Jaringan Sama)")

    if HAS_QR:
        print("\nAtau Scan QR Code ini dari kamera HP Anda:")
        qr = qrcode.QRCode(box_size=1, border=2)
        qr.add_data(url)
        qr.print_ascii(invert=True)

    print("=" * 60)
    print("Log aktivitas:\n")


class RemoteServer:
    def __init__(self, http_port: int = DEFAULT_HTTP_PORT, udp_port: int = DEFAULT_UDP_PORT, pin: str = None):
        self.http_port = http_port
        self.udp_port = udp_port
        self.pin = pin
        self.authenticated_clients = set()
        self.active_websockets = set()
        self.app = web.Application()
        self._setup_routes()

    def _setup_routes(self):
        # WebSocket Endpoint
        self.app.router.add_get("/ws", self.handle_websocket)

        # Screen Streaming (MJPEG)
        self.app.router.add_get("/stream.mjpg", self.handle_mjpeg_stream)

        # REST API
        self.app.router.add_get("/api/info", self.handle_system_info)
        self.app.router.add_get("/api/ping", lambda r: web.json_response({"status": "ok", "time": time.time()}))

        # Static files untuk PWA Remote
        static_dir = os.path.join(os.path.dirname(__file__), "static")
        if os.path.exists(static_dir):
            self.app.router.add_static("/static", static_dir, name="static")
            self.app.router.add_get("/", lambda r: web.FileResponse(os.path.join(static_dir, "index.html")))
        else:
            self.app.router.add_get("/", lambda r: web.Response(text="Static files tidak ditemukan.", content_type="text/plain"))

    # ================= REST & SCREEN STREAM =================

    async def handle_system_info(self, request):
        """Kembalikan data sistem: dimensi layar, memori, CPU, baterai."""
        w, h = screen_engine.get_dimensions()
        data = {
            "screen_width": w,
            "screen_height": h,
            "os": sys.platform,
            "pin_required": bool(self.pin),
        }
        if HAS_PSUTIL:
            try:
                data["cpu_percent"] = psutil.cpu_percent(interval=None)
                data["ram_percent"] = psutil.virtual_memory().percent
                battery = psutil.sensors_battery()
                if battery:
                    data["battery_percent"] = battery.percent
                    data["battery_charging"] = battery.power_plugged
            except Exception:
                pass
        return web.json_response(data)

    async def handle_mjpeg_stream(self, request):
        """Stream layar PC secara real-time via format MJPEG."""
        response = web.StreamResponse(
            status=200,
            reason="OK",
            headers={
                "Content-Type": "multipart/x-mixed-replace; boundary=frame",
                "Cache-Control": "no-cache, no-store, must-revalidate",
                "Pragma": "no-cache",
                "Expires": "0",
                "Connection": "close",
            },
        )
        await response.prepare(request)

        target_fps = 30
        frame_interval = 1.0 / target_fps

        try:
            while True:
                start_time = time.time()
                # Kompresi frame: resolusi max 1200px, kualitas 50 untuk menjaga latensi tetap rendah
                frame = screen_engine.capture_frame(max_width=1200, quality=50)
                if frame:
                    header = (
                        b"--frame\r\n"
                        b"Content-Type: image/jpeg\r\n"
                        b"Content-Length: " + str(len(frame)).encode("utf-8") + b"\r\n\r\n"
                    )
                    await response.write(header + frame + b"\r\n")

                elapsed = time.time() - start_time
                sleep_time = max(0.001, frame_interval - elapsed)
                await asyncio.sleep(sleep_time)

        except (asyncio.CancelledError, ConnectionResetError):
            pass
        return response

    # ================= WEBSOCKET COMMAND HANDLER =================

    async def handle_websocket(self, request):
        ws = web.WebSocketResponse(heartbeat=15.0)
        await ws.prepare(request)

        client_id = id(ws)
        self.active_websockets.add(ws)
        # Jika tidak ada PIN, langsung terautentikasi
        if not self.pin:
            self.authenticated_clients.add(client_id)

        try:
            async for msg in ws:
                if msg.type == WSMsgType.TEXT:
                    try:
                        data = json.loads(msg.data)
                        await self.process_command(ws, client_id, data)
                    except json.JSONDecodeError:
                        pass
                elif msg.type == WSMsgType.ERROR:
                    print(f"[WS] Error koneksi: {ws.exception()}")
        finally:
            self.active_websockets.discard(ws)
            self.authenticated_clients.discard(client_id)
        return ws

    async def process_command(self, ws, client_id, data: dict):
        cmd = data.get("type")

        # 1. Autentikasi PIN
        if cmd == "auth":
            entered_pin = str(data.get("pin", ""))
            if not self.pin or entered_pin == str(self.pin):
                self.authenticated_clients.add(client_id)
                await ws.send_json({"type": "auth_result", "status": "ok"})
                print(f"[AUTH] Klien {client_id} berhasil terautentikasi.")
            else:
                await ws.send_json({"type": "auth_result", "status": "failed", "message": "PIN salah!"})
            return

        # Cek apakah sudah terautentikasi
        if self.pin and client_id not in self.authenticated_clients:
            await ws.send_json({"type": "error", "message": "Harap masukkan PIN terlebih dahulu."})
            return

        # 2. Mouse Movement & Taps
        if cmd == "move":
            dx = float(data.get("dx", 0))
            dy = float(data.get("dy", 0))
            sens = float(data.get("sensitivity", 1.0))
            controller.move_rel(dx, dy, sensitivity=sens)

        elif cmd == "tap_coordinate":
            # Klik koordinat absolut dari tampilan screen mirror
            norm_x = float(data.get("x", 0))
            norm_y = float(data.get("y", 0))
            button = data.get("button", "left")
            controller.move_to_normalized(norm_x, norm_y)
            controller.click(button)

        elif cmd == "click":
            button = data.get("button", "left")
            controller.click(button)

        elif cmd == "double_click":
            button = data.get("button", "left")
            controller.double_click(button)

        elif cmd == "mouse_down":
            button = data.get("button", "left")
            controller.mouse_down(button)

        elif cmd == "mouse_up":
            button = data.get("button", "left")
            controller.mouse_up(button)

        elif cmd == "scroll":
            dy = float(data.get("dy", 0))
            dx = float(data.get("dx", 0))
            controller.scroll(dy, dx)

        # 3. Keyboard Input
        elif cmd == "type_text":
            text = data.get("text", "")
            controller.type_text(text)

        elif cmd == "key_press":
            key = data.get("key", "")
            controller.press_key(key)

        elif cmd == "hotkey":
            keys = data.get("keys", [])
            if keys:
                controller.hotkey(*keys)

        # 4. Media & Audio Controls
        elif cmd == "media":
            action = data.get("action")
            if action == "vol_up":
                controller.volume_up()
            elif action == "vol_down":
                controller.volume_down()
            elif action == "vol_mute":
                controller.volume_mute()
            elif action == "play_pause":
                controller.media_play_pause()
            elif action == "next":
                controller.media_next()
            elif action == "prev":
                controller.media_prev()

        # 5. Power & System Controls
        elif cmd == "power":
            action = data.get("action")
            if action == "lock":
                controller.lock_pc()
            elif action == "sleep":
                controller.sleep_pc()
            elif action == "restart":
                controller.restart_pc(delay_sec=int(data.get("delay", 5)))
            elif action == "shutdown":
                controller.shutdown_pc(delay_sec=int(data.get("delay", 5)))
            elif action == "cancel":
                controller.cancel_shutdown()

        # 6. Remote CMD / Terminal Execution
        elif cmd == "cmd_exec":
            command = data.get("command", "").strip()
            if command:
                try:
                    proc = await asyncio.create_subprocess_shell(
                        command,
                        stdout=asyncio.subprocess.PIPE,
                        stderr=asyncio.subprocess.PIPE
                    )
                    stdout, stderr = await proc.communicate()
                    # Decode dengan cp1252/utf-8 Windows safe
                    out_text = stdout.decode("cp1252", errors="replace") + stderr.decode("cp1252", errors="replace")
                    result_msg = out_text.strip() if out_text.strip() else "[Perintah berhasil dieksekusi tanpa output]"
                    await ws.send_json({
                        "type": "cmd_result",
                        "command": command,
                        "output": result_msg,
                        "success": proc.returncode == 0
                    })
                except Exception as e:
                    await ws.send_json({
                        "type": "cmd_result",
                        "command": command,
                        "output": f"Gagal mengeksekusi: {str(e)}",
                        "success": False
                    })

    # ================= FAST UDP THREAD =================

    def start_udp_listener(self):
        """Thread background UDP untuk mouse movement ultra-cepat dari native app."""
        def _udp_worker():
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            try:
                sock.bind(("0.0.0.0", self.udp_port))
                while True:
                    data, _ = sock.recvfrom(512)
                    try:
                        msg = json.loads(data.decode("utf-8"))
                        if msg.get("type") == "move":
                            dx = float(msg.get("dx", 0))
                            dy = float(msg.get("dy", 0))
                            sens = float(msg.get("sensitivity", 1.0))
                            controller.move_rel(dx, dy, sensitivity=sens)
                    except Exception:
                        pass
            except Exception as e:
                print(f"[UDP] Listener error: {e}")
            finally:
                sock.close()

        t = threading.Thread(target=_udp_worker, daemon=True)
        t.start()


def run_app():
    ip = get_local_ip()
    server = RemoteServer(http_port=DEFAULT_HTTP_PORT, udp_port=DEFAULT_UDP_PORT, pin=CONFIG_PIN)
    server.start_udp_listener()
    print_banner(ip, DEFAULT_HTTP_PORT, CONFIG_PIN)
    web.run_app(server.app, host="0.0.0.0", port=DEFAULT_HTTP_PORT, print=False)


if __name__ == "__main__":
    run_app()
