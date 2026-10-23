"""
Pure Standard Library Server (Zero Dependencies)
Dapat berjalan langsung menggunakan Python bawaan tanpa perlu 'pip install' sama sekali!
"""

import os
import sys
import json
import time
import socket
import threading
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

from win_input import controller
from screen_capture import screen_engine

PORT = 5000
UDP_PORT = 5001
STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")


def get_local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


class RemoteRequestHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=STATIC_DIR, **kwargs)

    def log_message(self, format, *args):
        # Mute logging berlebihan untuk performa
        pass

    def do_GET(self):
        if self.path == "/" or self.path == "":
            self.path = "/index.html"
            return super().do_GET()

        elif self.path == "/api/info":
            w, h = screen_engine.get_dimensions()
            data = {
                "screen_width": w,
                "screen_height": h,
                "os": sys.platform,
                "pin_required": False,
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(data).encode("utf-8"))
            return

        elif self.path == "/stream.mjpg":
            self.send_response(200)
            self.send_header("Content-Type", "multipart/x-mixed-replace; boundary=frame")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.send_header("Pragma", "no-cache")
            self.send_header("Expires", "0")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()

            try:
                while True:
                    frame = screen_engine.capture_frame(max_width=1200, quality=45)
                    if frame:
                        self.wfile.write(b"--frame\r\n")
                        self.wfile.write(b"Content-Type: image/jpeg\r\n")
                        self.wfile.write(f"Content-Length: {len(frame)}\r\n\r\n".encode("utf-8"))
                        self.wfile.write(frame)
                        self.wfile.write(b"\r\n")
                    time.sleep(0.04)  # ~25 FPS
            except Exception:
                return

        return super().do_GET()

    def do_POST(self):
        if self.path == "/api/command":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            try:
                data = json.loads(body.decode("utf-8"))
                result = self.process_command(data)
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(result or {"status": "ok"}).encode("utf-8"))
            except Exception as e:
                self.send_response(400)
                self.end_headers()
            return

        self.send_response(404)
        self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def process_command(self, data: dict):
        cmd = data.get("type")

        if cmd == "move":
            dx = float(data.get("dx", 0))
            dy = float(data.get("dy", 0))
            sens = float(data.get("sensitivity", 1.0))
            controller.move_rel(dx, dy, sensitivity=sens)

        elif cmd == "tap_coordinate":
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

        elif cmd == "cmd_exec":
            import subprocess
            command = data.get("command", "").strip()
            if command:
                try:
                    res = subprocess.run(
                        command,
                        shell=True,
                        capture_output=True,
                        text=True,
                        errors="replace",
                        timeout=15
                    )
                    out = (res.stdout + res.stderr).strip()
                    return {
                        "status": "ok",
                        "output": out if out else "[Perintah berhasil dijalankan tanpa output]",
                        "success": res.returncode == 0
                    }
                except Exception as e:
                    return {"status": "error", "output": str(e), "success": False}
        return {"status": "ok"}


def start_udp_listener():
    def _worker():
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            sock.bind(("0.0.0.0", UDP_PORT))
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
        except Exception:
            pass
        finally:
            sock.close()

    t = threading.Thread(target=_worker, daemon=True)
    t.start()


if __name__ == "__main__":
    ip = get_local_ip()
    start_udp_listener()

    print("\n" + "=" * 60)
    print("🚀 NATIVE PC REMOTE SERVER (STANDALONE ZERO-DEPENDENCY)")
    print("=" * 60)
    print(f"👉 Buka browser di Smartphone Anda:")
    print(f"   http://{ip}:{PORT}")
    print("=" * 60)
    print("Server siap menerima perintah. Tekan Ctrl+C untuk berhenti.\n")

    server = ThreadingHTTPServer(("0.0.0.0", PORT), RemoteRequestHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer dihentikan.")
        server.server_close()
