#!/usr/bin/env python3
"""
دانلود و بروزرسانی کاشی‌های کم‌زوم ایران برای لایهٔ پایهٔ آفلاین اپ.

  python3 tools/download_offline_tiles.py             فقط کاشی‌های ناموجود را می‌گیرد
  python3 tools/download_offline_tiles.py --refresh   همهٔ کاشی‌ها را با نسخهٔ فعلی OSM مقایسه می‌کند
                                                      و فقط کاشیِ تغییرکرده را جایگزین می‌کند

خروجی:  assets/tiles/{z}_{x}_{y}.png   (زوم ۰ تا ۷ ≈ ۹۸ فایل)
ETagها در tools/tiles_etags.json نگهداری می‌شود (بیرون از assets تا وارد APK نشود)؛
در اجرای بعدی با If-None-Match پرسیده می‌شود و کاشی بدون تغییر دوباره دانلود نمی‌شود.

سیاست OpenStreetMap دانلود انبوه را منع می‌کند؛ این اسکریپت فقط چند ده کاشی می‌گیرد،
بین درخواست‌ها مکث می‌کند و User-Agent مشخص می‌فرستد. زوم بالاتر از ۷ را با همین اسکریپت نگیرید.
"""
import hashlib, json, math, os, sys, time, urllib.error, urllib.request

CONTACT = "info@cyrustourist.ir"
MAX_ZOOM = 7
LAT_MIN, LAT_MAX = 24.0, 40.5
LON_MIN, LON_MAX = 43.5, 64.5
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "tiles")
ETAGS = os.path.join(HERE, "tiles_etags.json")
URL = os.environ.get("TILE_URL", "https://tile.openstreetmap.org/{z}/{x}/{y}.png")
DELAY = float(os.environ.get("TILE_DELAY", "1.2"))


def tile(lat, lon, z):
    n = 2 ** z
    x = int((lon + 180.0) / 360.0 * n)
    y = int((1.0 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2.0 * n)
    return max(0, min(n - 1, x)), max(0, min(n - 1, y))


def sha(b):
    return hashlib.sha256(b).hexdigest()


# صفحهٔ «403 Access blocked» که OSM به‌جای نقشه می‌فرستد؛ هرگز نباید به‌عنوان کاشی ذخیره شود
BLOCKED_SHA = "b02c44252dac5a5e820ecef1e9bf9200e9407c042df668a466a1aa81a9ecca7a"


def valid_tile(data):
    return (
        len(data) > 100
        and data[:8] == b"\x89PNG\r\n\x1a\n"
        and sha(data) != BLOCKED_SHA
    )


def main():
    refresh = "--refresh" in sys.argv
    if MAX_ZOOM > 7:
        sys.exit("MAX_ZOOM must be <= 7")
    os.makedirs(OUT, exist_ok=True)
    try:
        etags = json.load(open(ETAGS, encoding="utf-8"))
    except Exception:
        etags = {}
    jobs = []
    for z in range(0, MAX_ZOOM + 1):
        x0, y1 = tile(LAT_MIN, LON_MIN, z)
        x1, y0 = tile(LAT_MAX, LON_MAX, z)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                jobs.append((z, x, y))
    print("tiles:", len(jobs), "mode:", "refresh" if refresh else "missing-only")
    added = changed = same = fail = 0
    changed_names = []
    for i, (z, x, y) in enumerate(jobs, 1):
        name = "%d_%d_%d.png" % (z, x, y)
        path = os.path.join(OUT, name)
        exists = os.path.exists(path) and os.path.getsize(path) > 0
        if exists and not refresh:
            same += 1
            continue
        headers = {"User-Agent": "CyrusTourist-offline-base/1.1 (%s)" % CONTACT}
        if exists and etags.get(name):
            headers["If-None-Match"] = etags[name]
        req = urllib.request.Request(URL.format(z=z, x=x, y=y), headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                data = r.read()
                et = r.headers.get("ETag")
            if not valid_tile(data):
                fail += 1
                print("FAIL", name, "invalid or blocked response")
                time.sleep(DELAY)
                continue
            if et:
                etags[name] = et
            if not exists:
                open(path, "wb").write(data)
                added += 1
                changed_names.append(name + " (new)")
            elif sha(data) != sha(open(path, "rb").read()):
                open(path, "wb").write(data)
                changed += 1
                changed_names.append(name)
            else:
                same += 1
        except urllib.error.HTTPError as e:
            if e.code == 304:
                same += 1
            else:
                fail += 1
                print("FAIL", name, e)
        except Exception as e:
            fail += 1
            print("FAIL", name, e)
        time.sleep(DELAY)
        if i % 10 == 0:
            print("%d/%d" % (i, len(jobs)))
    json.dump(etags, open(ETAGS, "w", encoding="utf-8"), indent=0, sort_keys=True)
    total = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT) if f.endswith(".png"))
    summary = "tiles new=%d updated=%d unchanged=%d failed=%d size=%.2f MB" % (added, changed, same, fail, total / 1048576.0)
    print(summary)
    for n in changed_names[:40]:
        print(" -", n)
    gs = os.environ.get("GITHUB_STEP_SUMMARY")
    if gs:
        with open(gs, "a", encoding="utf-8") as f:
            f.write("### Offline tiles\n%s\n" % summary)
    go = os.environ.get("GITHUB_OUTPUT")
    if go:
        with open(go, "a", encoding="utf-8") as f:
            f.write("updated=%d\n" % (added + changed))
    if fail > len(jobs) * 0.2:
        sys.exit("too many failures")


if __name__ == "__main__":
    main()
