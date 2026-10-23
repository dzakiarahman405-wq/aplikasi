"""
Screen Capture & Frame Streaming Engine
Dirancang untuk latensi rendah, efisiensi bandwidth, dan fallback otomatis.
"""

import sys
import io
import time
import asyncio
from typing import Tuple, Optional

# Coba import mss (paling cepat untuk screen grab)
try:
    import mss
    HAS_MSS = True
except ImportError:
    HAS_MSS = False

# Coba import PIL untuk manipulasi & kompresi JPEG
try:
    from PIL import Image, ImageGrab
    HAS_PIL = True
except ImportError:
    HAS_PIL = False


class ScreenCaptureEngine:
    def __init__(self):
        self._sct = None
        if HAS_MSS:
            try:
                self._sct = mss.mss()
            except Exception as e:
                print(f"[WARN] Inisialisasi mss gagal: {e}. Beralih ke fallback.")
                self._sct = None

        self._monitor = None
        self._update_monitor_dims()

    def _update_monitor_dims(self):
        """Ambil dimensi monitor utama."""
        if self._sct and self._sct.monitors:
            # monitors[1] adalah layar utama di mss
            self._monitor = self._sct.monitors[1]
        elif HAS_PIL:
            img = ImageGrab.grab()
            self._monitor = {"left": 0, "top": 0, "width": img.width, "height": img.height}
        else:
            self._monitor = {"left": 0, "top": 0, "width": 1920, "height": 1080}

    def get_dimensions(self) -> Tuple[int, int]:
        """Kembalikan (lebar, tinggi) layar utama."""
        if self._monitor:
            return (self._monitor["width"], self._monitor["height"])
        return (1920, 1080)

    def capture_frame(self, max_width: int = 1280, quality: int = 50) -> Optional[bytes]:
        """
        Tangkap frame layar saat ini dan kompresi ke format JPEG.
        - max_width: resolusi horizontal maksimum untuk hemat bandwidth.
        - quality: kualitas JPEG (1-100), default 50 untuk rasio latensi/kualitas optimal.
        """
        try:
            pil_img = None

            # 1. Prioritas Utama: MSS
            if self._sct and self._monitor:
                sct_img = self._sct.grab(self._monitor)
                if HAS_PIL:
                    # Konversi BGRA mss ke RGB PIL Image
                    pil_img = Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")

            # 2. Fallback: ImageGrab PIL
            if pil_img is None and HAS_PIL:
                pil_img = ImageGrab.grab()

            if pil_img is None:
                return None

            # Resize proporsional jika lebar melebihi max_width
            w, h = pil_img.size
            if w > max_width:
                new_h = int((max_width / w) * h)
                pil_img = pil_img.resize((max_width, new_h), Image.Resampling.BILINEAR)

            # Kompresi ke JPEG buffer in-memory
            output = io.BytesIO()
            pil_img.save(output, format="JPEG", quality=quality, optimize=False)
            return output.getvalue()

        except Exception as e:
            # Tangani error capture sementara (misal saat UAC prompt / lock screen)
            return None


# Global singleton instance
screen_engine = ScreenCaptureEngine()
