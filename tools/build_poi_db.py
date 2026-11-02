#!/usr/bin/env python3
"""ساخت پایگاه آفلاین جاذبه‌ها/اقامتگاه‌ها/مراکز سلامت ایران برای اپ.

ورودی : فایل geojsonseq خروجی `osmium export` (فقط عناصر فیلترشده‌ی OpenStreetMap)
خروجی : assets/poi/iran_poi.bin  (JSON فشرده‌ی gzip؛ هر ردیف یک مکان)

ردیف: [lat, lon, "key=value;key=value", name, name_en, phone, website, osm_id]

استفاده:
  python3 tools/build_poi_db.py features.geojsonseq assets/poi/iran_poi.bin
"""
import gzip
import json
import math
import sys

# فقط همین کلیدها/مقدارها نگه داشته می‌شوند (هم‌راستا با _buildTags در map_places_service.dart)
WANT = {
    "tourism": {"attraction", "museum", "gallery", "viewpoint", "artwork", "hotel", "hostel", "guest_house",
                "motel", "camp_site", "caravan_site", "chalet", "apartment", "alpine_hut", "zoo", "theme_park"},
    "historic": {"monument", "castle", "archaeological_site", "ruins", "memorial", "fort", "tomb"},
    "leisure": {"park", "nature_reserve"},
    "amenity": {"hospital", "clinic", "doctors", "pharmacy", "spa"},
    "natural": {"waterfall", "hot_spring"},
}
BARE = {"healthcare"}  # هر مقداری


def kinds(tags):
    out = []
    for k, vals in WANT.items():
        v = tags.get(k)
        if v and v in vals:
            out.append(f"{k}={v}")
    for k in BARE:
        v = tags.get(k)
        if v:
            out.append(f"{k}={v}")
    return out


def flat_coords(c, acc):
    if not c:
        return
    if isinstance(c[0], (int, float)):
        acc.append(c)
    else:
        for x in c:
            flat_coords(x, acc)


def center(geom):
    if not geom:
        return None
    t = geom.get("type")
    co = geom.get("coordinates")
    if t == "Point":
        return co[1], co[0]
    pts = []
    flat_coords(co, pts)
    if not pts:
        return None
    lons = [p[0] for p in pts]
    lats = [p[1] for p in pts]
    return (min(lats) + max(lats)) / 2, (min(lons) + max(lons)) / 2


def main(src, dst):
    rows = []
    seen = set()
    n_in = 0
    with open(src, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip().lstrip("\x1e")
            if not line:
                continue
            try:
                ft = json.loads(line)
            except Exception:
                continue
            n_in += 1
            props = ft.get("properties") or {}
            tags = {k: str(v) for k, v in props.items() if not k.startswith("@")}
            ks = kinds(tags)
            if not ks:
                continue
            name = (tags.get("name:fa") or tags.get("name") or "").strip()
            name_en = (tags.get("name:en") or "").strip()
            if not name and not name_en:
                continue
            c = center(ft.get("geometry"))
            if not c:
                continue
            lat, lon = round(c[0], 5), round(c[1], 5)
            if not (24 <= lat <= 40.5 and 43 <= lon <= 64):  # محدودهٔ ایران (با حاشیه)
                continue
            # حذف تکراری (نقطه داخل چندضلعی همان مکان)
            key = (name or name_en, round(lat, 3), round(lon, 3), ks[0])
            if key in seen:
                continue
            seen.add(key)
            phone = (tags.get("phone") or tags.get("contact:phone") or "").strip()
            web = (tags.get("website") or tags.get("contact:website") or "").strip()
            typ = str(props.get("@type") or "")[:1]
            oid = (typ + str(props.get("@id"))) if props.get("@id") and typ else str(ft.get("id") or props.get("@id") or "")
            rows.append([lat, lon, ";".join(ks[:3]), name or name_en, name_en if name else "", phone[:40], web[:120], oid])
    rows.sort(key=lambda r: (r[0], r[1]))
    data = json.dumps(rows, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    with gzip.GzipFile(dst, "wb", compresslevel=9, mtime=0) as g:
        g.write(data)
    print(f"read {n_in} features, kept {len(rows)}, raw {len(data)/1e6:.1f} MB, gz {len(open(dst,'rb').read())/1e6:.1f} MB")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
