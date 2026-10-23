"""
Windows Native Input & System Controller
Menggunakan Windows Win32 API langsung via ctypes (SendInput & mouse_event)
untuk performa instan tanpa lag dan tanpa dependensi eksternal.
"""

import sys
import os
import time
import ctypes
from ctypes import wintypes

IS_WINDOWS = sys.platform.startswith("win")

if IS_WINDOWS:
    user32 = ctypes.windll.user32

    # Konstanta Mouse Event
    MOUSEEVENTF_MOVE = 0x0001
    MOUSEEVENTF_LEFTDOWN = 0x0002
    MOUSEEVENTF_LEFTUP = 0x0004
    MOUSEEVENTF_RIGHTDOWN = 0x0008
    MOUSEEVENTF_RIGHTUP = 0x0010
    MOUSEEVENTF_MIDDLEDOWN = 0x0020
    MOUSEEVENTF_MIDDLEUP = 0x0040
    MOUSEEVENTF_WHEEL = 0x0800
    MOUSEEVENTF_HWHEEL = 0x1000
    MOUSEEVENTF_ABSOLUTE = 0x8000

    # Konstanta Keyboard Event
    KEYEVENTF_EXTENDEDKEY = 0x0001
    KEYEVENTF_KEYUP = 0x0002
    KEYEVENTF_UNICODE = 0x0004
    KEYEVENTF_SCANCODE = 0x0008

    # Win32 SendInput Structures
    PULONG_PTR = ctypes.POINTER(wintypes.ULONG)

    class MOUSEINPUT(ctypes.Structure):
        _fields_ = (
            ("dx", wintypes.LONG),
            ("dy", wintypes.LONG),
            ("mouseData", wintypes.DWORD),
            ("dwFlags", wintypes.DWORD),
            ("time", wintypes.DWORD),
            ("dwExtraInfo", wintypes.PULONG),
        )

    class KEYBDINPUT(ctypes.Structure):
        _fields_ = (
            ("wVk", wintypes.WORD),
            ("wScan", wintypes.WORD),
            ("dwFlags", wintypes.DWORD),
            ("time", wintypes.DWORD),
            ("dwExtraInfo", wintypes.PULONG),
        )

    class HARDWAREINPUT(ctypes.Structure):
        _fields_ = (
            ("uMsg", wintypes.DWORD),
            ("wParamL", wintypes.WORD),
            ("wParamH", wintypes.WORD),
        )

    class _INPUTunion(ctypes.Union):
        _fields_ = (
            ("mi", MOUSEINPUT),
            ("ki", KEYBDINPUT),
            ("hi", HARDWAREINPUT),
        )

    class INPUT(ctypes.Structure):
        _fields_ = (
            ("type", wintypes.DWORD),
            ("union", _INPUTunion),
        )

    INPUT_MOUSE = 0
    INPUT_KEYBOARD = 1

    # Virtual Key Codes
    VK_CODES = {
        "backspace": 0x08,
        "tab": 0x09,
        "enter": 0x0D,
        "shift": 0x10,
        "ctrl": 0x11,
        "alt": 0x12,
        "pause": 0x13,
        "capslock": 0x14,
        "esc": 0x1B,
        "escape": 0x1B,
        "space": 0x20,
        "pageup": 0x21,
        "pagedown": 0x22,
        "end": 0x23,
        "home": 0x24,
        "left": 0x25,
        "up": 0x26,
        "right": 0x27,
        "down": 0x28,
        "insert": 0x2D,
        "delete": 0x2E,
        "win": 0x5B,
        "f1": 0x70, "f2": 0x71, "f3": 0x72, "f4": 0x73,
        "f5": 0x74, "f6": 0x75, "f7": 0x76, "f8": 0x77,
        "f9": 0x78, "f10": 0x79, "f11": 0x7A, "f12": 0x7B,
        "volumemute": 0xAD,
        "volumedown": 0xAE,
        "volumeup": 0xAF,
        "medianext": 0xB0,
        "mediaprev": 0xB1,
        "mediastop": 0xB2,
        "mediaplaypause": 0xB3,
    }


class WindowsInputController:
    """Kontroler native untuk simulasi kursor, klik, ketik, media, dan sistem."""

    def __init__(self):
        pass

    # ================= MOUSE CONTROLS =================

    def move_rel(self, dx: float, dy: float, sensitivity: float = 1.0, accel: bool = True):
        """Gerakkan kursor secara relatif."""
        if not IS_WINDOWS:
            return

        mult = sensitivity
        if accel:
            dist = (dx**2 + dy**2) ** 0.5
            if dist > 15:
                mult *= 1.3
            elif dist > 35:
                mult *= 1.6

        final_dx = int(dx * mult)
        final_dy = int(dy * mult)

        if final_dx != 0 or final_dy != 0:
            user32.mouse_event(MOUSEEVENTF_MOVE, final_dx, final_dy, 0, 0)

    def move_to_normalized(self, norm_x: float, norm_y: float):
        """Pindahkan kursor ke koordinat absolut (0.0 s.d 1.0) di layar."""
        if not IS_WINDOWS:
            return
        abs_x = int(norm_x * 65535)
        abs_y = int(norm_y * 65535)
        user32.mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE, abs_x, abs_y, 0, 0)

    def mouse_down(self, button: str = "left"):
        """Tekan tombol mouse tanpa melepas."""
        if not IS_WINDOWS:
            return
        btn = button.lower()
        if btn == "left":
            user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
        elif btn == "right":
            user32.mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0)
        elif btn == "middle":
            user32.mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0)

    def mouse_up(self, button: str = "left"):
        """Lepaskan tombol mouse."""
        if not IS_WINDOWS:
            return
        btn = button.lower()
        if btn == "left":
            user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
        elif btn == "right":
            user32.mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0)
        elif btn == "middle":
            user32.mouse_event(MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0)

    def click(self, button: str = "left"):
        """Klik mouse tunggal."""
        self.mouse_down(button)
        time.sleep(0.015)
        self.mouse_up(button)

    def double_click(self, button: str = "left"):
        """Klik ganda."""
        self.click(button)
        time.sleep(0.06)
        self.click(button)

    def scroll(self, dy: float, dx: float = 0):
        """Scroll vertikal (dy) dan horizontal (dx)."""
        if not IS_WINDOWS:
            return
        if dy != 0:
            user32.mouse_event(MOUSEEVENTF_WHEEL, 0, 0, int(dy * 120), 0)
        if dx != 0:
            user32.mouse_event(MOUSEEVENTF_HWHEEL, 0, 0, int(dx * 120), 0)

    # ================= KEYBOARD CONTROLS =================

    def key_down(self, key_name: str):
        if not IS_WINDOWS:
            return
        key_lower = key_name.lower()
        if key_lower in VK_CODES:
            vk = VK_CODES[key_lower]
            user32.keybd_event(vk, 0, 0, 0)
        elif len(key_name) == 1:
            vk = user32.VkKeyScanW(ord(key_name)) & 0xFF
            if vk != 0:
                user32.keybd_event(vk, 0, 0, 0)

    def key_up(self, key_name: str):
        if not IS_WINDOWS:
            return
        key_lower = key_name.lower()
        if key_lower in VK_CODES:
            vk = VK_CODES[key_lower]
            user32.keybd_event(vk, 0, KEYEVENTF_KEYUP, 0)
        elif len(key_name) == 1:
            vk = user32.VkKeyScanW(ord(key_name)) & 0xFF
            if vk != 0:
                user32.keybd_event(vk, 0, KEYEVENTF_KEYUP, 0)

    def press_key(self, key_name: str):
        self.key_down(key_name)
        time.sleep(0.015)
        self.key_up(key_name)

    def type_unicode_char(self, char: str):
        """Kirim 1 karakter unicode via Win32 SendInput (aman untuk semua simbol/huruf)."""
        if not IS_WINDOWS:
            return
        for code in char.encode("utf-16-le"):
            pass
        code_point = ord(char)

        # Input Down
        inp_down = INPUT()
        inp_down.type = INPUT_KEYBOARD
        inp_down.union.ki = KEYBDINPUT(0, code_point, KEYEVENTF_UNICODE, 0, None)

        # Input Up
        inp_up = INPUT()
        inp_up.type = INPUT_KEYBOARD
        inp_up.union.ki = KEYBDINPUT(0, code_point, KEYEVENTF_UNICODE | KEYEVENTF_KEYUP, 0, None)

        inputs = (INPUT * 2)(inp_down, inp_up)
        user32.SendInput(2, inputs, ctypes.sizeof(INPUT))

    def type_text(self, text: str):
        """Ketik seluruh string teks."""
        if not IS_WINDOWS:
            return
        for char in text:
            if char == "\n":
                self.press_key("enter")
            elif char == "\t":
                self.press_key("tab")
            else:
                self.type_unicode_char(char)
            time.sleep(0.005)

    def hotkey(self, *keys):
        """Kombinasi tombol shortcut."""
        for k in keys:
            self.key_down(k)
            time.sleep(0.01)
        time.sleep(0.02)
        for k in reversed(keys):
            self.key_up(k)
            time.sleep(0.01)

    # ================= MEDIA & SHORTCUTS =================

    def volume_up(self):
        self.press_key("volumeup")

    def volume_down(self):
        self.press_key("volumedown")

    def volume_mute(self):  
        self.press_key("volumemute")

    def media_play_pause(self):
        self.press_key("mediaplaypause")

    def media_next(self):
        self.press_key("medianext")

    def media_prev(self):
        self.press_key("mediaprev")

    # ================= SYSTEM POWER =================

    def lock_pc(self):
        if IS_WINDOWS:
            user32.LockWorkStation()

    def sleep_pc(self):
        if IS_WINDOWS:
            os.system("rundll32.exe powrprof.dll,SetSuspendState 0,1,0")

    def restart_pc(self, delay_sec: int = 5):
        if IS_WINDOWS:
            os.system(f'shutdown /r /t {delay_sec} /c "Restart diminta dari Remote HP"')

    def shutdown_pc(self, delay_sec: int = 5):
        if IS_WINDOWS:
            os.system(f'shutdown /s /t {delay_sec} /c "Shutdown diminta dari Remote HP"')

    def cancel_shutdown(self):
        if IS_WINDOWS:
            os.system("shutdown /a")


controller = WindowsInputController()
