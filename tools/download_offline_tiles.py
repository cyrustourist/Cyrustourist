#!/usr/bin/env python3
"""
دانلود کاشی‌های کم‌زوم ایران برای لایهٔ پایهٔ آفلاین اپ.
اجرا (روی کامپیوتر خودتان، از ریشهٔ پروژه):   python3 tools/download_offline_tiles.py
خروجی:  assets/tiles/{z}_{x}_{y}.png   (زوم ۰ تا ۷ ≈ ۹۰ تا ۱۰۰ فایل)

سیاست OpenStreetMap دانلود انبوه را منع می‌کند؛ این اسکریپت فقط چند ده کاشی می‌گیرد،
بین درخواست‌ها مکث می‌کند و User-Agent مشخص می‌فرستد. زوم بالاتر از ۷ را با همین اسکریپت نگیرید.
"""
import math, os, sys, time, urllib.request

CONTACT = "info@cyrustourist.ir"       # ایمیل تماس را در صورت نیاز عوض کنید
MAX_ZOOM = 7                           # بالاتر نبرید (سیاست OSM + حجم APK)
LAT_MIN, LAT_MAX = 24.0, 40.5
LON_MIN, LON_MAX = 43.5, 64.5
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "tiles")

def tile(lat, lon, z):
    n = 2 ** z
    x = int((lon + 180.0) / 360.0 * n)
    y = int((1.0 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2.0 * n)
    return max(0, min(n - 1, x)), max(0, min(n - 1, y))

def main():
    if MAX_ZOOM > 7:
        sys.exit("MAX_ZOOM must be <= 7")
    os.makedirs(OUT, exist_ok=True)
    jobs = []
    for z in range(0, MAX_ZOOM + 1):
        x0, y1 = tile(LAT_MIN, LON_MIN, z)
        x1, y0 = tile(LAT_MAX, LON_MAX, z)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                jobs.append((z, x, y))
    print("tiles:", len(jobs))
    ok = fail = 0
    for i, (z, x, y) in enumerate(jobs, 1):
        path = os.path.join(OUT, "%d_%d_%d.png" % (z, x, y))
        if os.path.exists(path) and os.path.getsize(path) > 0:
            ok += 1
            continue
        url = "https://tile.openstreetmap.org/%d/%d/%d.png" % (z, x, y)
        req = urllib.request.Request(url, headers={"User-Agent": "CyrusTourist-offline-base/1.0 (%s)" % CONTACT})
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                data = r.read()
            with open(path, "wb") as f:
                f.write(data)
            ok += 1
        except Exception as e:
            fail += 1
            print("FAIL", url, e)
        time.sleep(1.2)
        if i % 10 == 0:
            print("%d/%d" % (i, len(jobs)))
    total = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT) if f.endswith(".png"))
    print("done ok=%d fail=%d size=%.2f MB" % (ok, fail, total / 1048576.0))

if __name__ == "__main__":
    main()
