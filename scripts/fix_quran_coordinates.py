"""
Fix ayah marker coordinates and polygons for selected Mushaf pages.

The coordinate JSON files use a 345 x 550 space that is stretched over the
dark page images (assets/quran_images_dark/NNN.webp). This script reads those
images, finds the real text lines and the silver ayah-end markers, and
rebuilds x / y / polygon for every ayah of the target pages.

Surah, ayah and page mapping always comes from hafs-ayah-meta.json and is
never changed. Only the TARGET_PAGES files are touched.

Usage (from the project root):
    python scripts/fix_quran_coordinates.py                # report only
    python scripts/fix_quran_coordinates.py --apply        # report + write JSON
    python scripts/fix_quran_coordinates.py --preview out  # also save overlay PNGs

Dependencies: Pillow, numpy
"""

import argparse
import json
import os
import re

import numpy as np
from PIL import Image, ImageDraw

TARGET_PAGES = [
    76, 77, 207, 208, 331, 332, 341, 342, 349, 350, 366, 367, 376, 377,
    414, 415, 417, 418, 445, 446, 452, 453, 498, 499, 506, 507, 523, 525,
    526, 545, 548, 549, 555, 556, 557, 558, 567, 577, 578, 584, 585, 591,
]

# On these pages the page image matches the existing JSON ayah list, not
# hafs-ayah-meta.json. They are fixed with their own ayah list (no mapping change).
KEEP_JSON_AYAHS_PAGES = [567, 584, 585, 591]

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
META_PATH = os.path.join(ROOT, "assets", "json", "hafs-ayah-meta.json")
COORDS_DIR = os.path.join(ROOT, "assets", "json", "quran_coordinates")
IMAGES_DIR = os.path.join(ROOT, "assets", "quran_images_dark")
REPORT_PATH = os.path.join(ROOT, "scripts", "quran_coordinates_report.md")

# Coordinate space used by the app (MoshafViewModel.coordinatePageWidth/Height).
COORD_WIDTH = 345.0
COORD_HEIGHT = 550.0

# Values smaller than this (in coordinate units) are treated as "already correct".
TOLERANCE = 1.5

# Marker limits in image pixels (markers are ~26 x 33 px with ~300 silver pixels).
MARKER_MIN_WIDTH = 20
MARKER_MAX_WIDTH = 40
MARKER_MIN_HEIGHT = 24
MARKER_MAX_HEIGHT = 42
MARKER_MIN_PIXELS = 150


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

def load_page_ayahs():
    """Returns {page: [(surah, ayah), ...]} in mushaf order from the meta file."""
    with open(META_PATH, encoding="utf-8") as f:
        meta = json.load(f)
    meta.sort(key=lambda item: item["id"])

    pages = {}
    for item in meta:
        pages.setdefault(item["page"], []).append((item["sura"], item["aya"]))
    return pages


def coords_path(page):
    """Returns the coordinate JSON path for a page (e.g. 076.json)."""
    return os.path.join(COORDS_DIR, f"{page:03d}.json")


def load_page_image(page):
    """Loads the dark page image as an RGBA int array."""
    path = os.path.join(IMAGES_DIR, f"{page:03d}.webp")
    return np.array(Image.open(path).convert("RGBA")).astype(int)


def parse_polygon(polygon):
    """Parses 'M x y L x y ... Z' into a list of point lists."""
    shapes = []
    for part in polygon.split("Z"):
        numbers = [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", part)]
        if numbers:
            shapes.append(list(zip(numbers[0::2], numbers[1::2])))
    return shapes


# ---------------------------------------------------------------------------
# Image analysis
# ---------------------------------------------------------------------------

def find_row_segments(row_counts, min_ink=3):
    """Returns (top, bottom) row ranges where each row has at least min_ink pixels."""
    segments = []
    start = None
    for y, count in enumerate(row_counts):
        if count >= min_ink and start is None:
            start = y
        elif count < min_ink and start is not None:
            segments.append((start, y - 1))
            start = None
    if start is not None:
        segments.append((start, len(row_counts) - 1))
    return segments


def find_headers(ink):
    """Finds surah header frames: clusters of rows that are almost fully inked."""
    width = ink.shape[1]
    full_rows = np.where(ink.sum(axis=1) > 0.85 * width)[0]

    headers = []
    for y in full_rows:
        if headers and y - headers[-1][1] < 80:
            headers[-1][1] = y
        else:
            headers.append([y, y])
    return [(top, bottom) for top, bottom in headers]


def estimate_line_pitch(segments):
    """Estimates the distance between two text lines from single-line segments."""
    distances = []
    for (top1, bottom1), (top2, bottom2) in zip(segments, segments[1:]):
        single1 = 35 <= bottom1 - top1 + 1 <= 75
        single2 = 35 <= bottom2 - top2 + 1 <= 75
        if single1 and single2 and 40 <= top2 - top1 <= 80:
            distances.append(top2 - top1)
    if not distances:
        return 55.0
    return float(np.median(distances))


def split_merged_segment(top, bottom, row_counts, pitch):
    """Splits a segment that holds several touching lines at the emptiest rows."""
    height = bottom - top + 1
    line_count = max(1, int(round((height + 5) / pitch)))
    if line_count == 1:
        return [(top, bottom)]

    parts = []
    part_top = top
    window = int(pitch * 0.25)
    for i in range(1, line_count):
        expected = int(top + i * height / line_count)
        low = max(part_top + 10, expected - window)
        high = min(bottom - 10, expected + window)
        split_y = low + int(np.argmin(row_counts[low:high + 1]))
        parts.append((part_top, split_y))
        part_top = split_y + 1
    parts.append((part_top, bottom))
    return parts


def find_lines(image):
    """Returns page lines as dicts: {top, bottom, kind} with kind text/basmala/header."""
    ink = image[..., 3] > 100
    width = ink.shape[1]

    headers = find_headers(ink)
    row_counts = ink.sum(axis=1)
    text_rows = row_counts.copy()
    for top, bottom in headers:
        text_rows[max(0, top - 3):bottom + 4] = 0

    # Tiny segments are loose diacritics between two lines.
    segments = [s for s in find_row_segments(text_rows) if s[1] - s[0] + 1 >= 12]
    pitch = estimate_line_pitch(segments)

    lines = []
    for top, bottom in headers:
        lines.append({"top": top, "bottom": bottom, "kind": "header"})

    for seg_top, seg_bottom in segments:
        for top, bottom in split_merged_segment(seg_top, seg_bottom, text_rows, pitch):
            columns = np.where(ink[top:bottom + 1].any(axis=0))[0]
            span = columns.max() - columns.min() + 1
            # Mushaf text lines are justified; the basmala is a short centered line.
            kind = "text" if span > 0.7 * width else "basmala"
            lines.append({"top": top, "bottom": bottom, "kind": kind})

    lines.sort(key=lambda line: line["top"])
    return lines


def find_markers(image, lines):
    """Finds silver ayah-end markers inside text lines. Returns dicts in reading order."""
    rgb = image[..., :3]
    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    # Quran text and headers are gold; ayah markers are silver/white.
    silver = (image[..., 3] > 100) & (saturation < 40) & (rgb.max(axis=2) > 90)

    markers = []
    for line_index, line in enumerate(lines):
        if line["kind"] != "text":
            continue
        band = silver[line["top"]:line["bottom"] + 1]
        column_has_silver = band.sum(axis=0) >= 2

        for left, right in find_row_segments(column_has_silver.astype(int), min_ink=1):
            if not MARKER_MIN_WIDTH <= right - left + 1 <= MARKER_MAX_WIDTH:
                continue
            block = band[:, left:right + 1]
            if block.sum() < MARKER_MIN_PIXELS:
                continue
            # Longest vertical run, so a small silver sign above/below is ignored.
            row_runs = find_row_segments(block.sum(axis=1), min_ink=2)
            run_top, run_bottom = max(row_runs, key=lambda run: run[1] - run[0])
            top = line["top"] + run_top
            bottom = line["top"] + run_bottom
            if not MARKER_MIN_HEIGHT <= bottom - top + 1 <= MARKER_MAX_HEIGHT:
                continue
            markers.append({
                "line": line_index,
                "left": left,
                "right": right,
                "center_x": (left + right) / 2,
                "center_y": (top + bottom) / 2,
            })

    # Reading order: top line first, then right to left.
    markers.sort(key=lambda m: (m["line"], -m["center_x"]))
    return markers


# ---------------------------------------------------------------------------
# Polygon building
# ---------------------------------------------------------------------------

def line_band_edges(lines, image_height):
    """Returns {line_index: (top, bottom)} pixel bands for text lines."""
    edges = {}
    for i, line in enumerate(lines):
        if line["kind"] != "text":
            continue
        previous = lines[i - 1] if i > 0 else None
        following = lines[i + 1] if i + 1 < len(lines) else None

        if previous is not None and previous["kind"] == "text":
            top = (previous["bottom"] + line["top"]) / 2
        else:
            top = max(0, line["top"] - 3)

        if following is not None and following["kind"] == "text":
            bottom = (line["bottom"] + following["top"]) / 2
        else:
            bottom = min(image_height, line["bottom"] + 3)

        edges[i] = (top, bottom)
    return edges


def first_text_line_above(lines, marker_line, lowest_allowed):
    """Walks up from marker_line and returns the first line of that text block."""
    start = marker_line
    while start - 1 > lowest_allowed and lines[start - 1]["kind"] == "text":
        start -= 1
    return start


def build_rectangles(lines, markers, ayahs, right_edge):
    """Builds pixel rectangles (left, top_line, right, bottom_line) per ayah."""
    all_rects = []
    for k, (surah, ayah) in enumerate(ayahs):
        marker = markers[k]
        end_line = marker["line"]
        previous = markers[k - 1] if k > 0 else None

        if previous is None or ayah == 1:
            # Starts at the top of its text block (page top or after a basmala).
            lowest = previous["line"] if previous is not None else -1
            start_line = first_text_line_above(lines, end_line, lowest)
            start_right = right_edge
        else:
            start_line = previous["line"]
            start_right = previous["left"] - 1
            # Previous marker ends its line, so this ayah starts on the next line.
            if start_right < 25:
                start_line += 1
                start_right = right_edge

        rects = []
        for line_index in range(start_line, end_line + 1):
            if lines[line_index]["kind"] != "text":
                continue
            left = marker["left"] - 1 if line_index == end_line else 0
            right = start_right if line_index == start_line else right_edge
            rects.append([left, line_index, right, line_index])

        # Merge stacked full-width lines into one rectangle (same style as before).
        merged = []
        for rect in rects:
            last = merged[-1] if merged else None
            if (last is not None and last[0] == rect[0] and last[2] == rect[2]
                    and rect[1] == last[3] + 1):
                last[3] = rect[3]
            else:
                merged.append(rect)
        all_rects.append(merged)
    return all_rects


def fmt(value):
    """Formats a number like the existing JSON (e.g. 0.0, 229.88)."""
    return str(round(float(value), 2))


def rects_to_polygon(rects):
    """Converts coordinate-space rectangles into the SVG-like polygon string."""
    parts = []
    for left, top, right, bottom in rects:
        parts.append(
            f"M {fmt(left)} {fmt(top)} L {fmt(right)} {fmt(top)} "
            f"L {fmt(right)} {fmt(bottom)} L {fmt(left)} {fmt(bottom)} Z"
        )
    return " ".join(parts)


def polygons_match(old_polygon, new_polygon):
    """True when both polygons have the same shapes within TOLERANCE."""
    old_shapes = parse_polygon(old_polygon)
    new_shapes = parse_polygon(new_polygon)
    if len(old_shapes) != len(new_shapes):
        return False
    for old_points, new_points in zip(old_shapes, new_shapes):
        if len(old_points) != len(new_points):
            return False
        for (ox, oy), (nx, ny) in zip(old_points, new_points):
            if abs(ox - nx) > TOLERANCE or abs(oy - ny) > TOLERANCE:
                return False
    return True


# ---------------------------------------------------------------------------
# Page processing
# ---------------------------------------------------------------------------

def analyze_page(page, expected_ayahs):
    """Detects corrections for one page. Returns a result dict (nothing is written)."""
    result = {"page": page, "status": "ok", "message": "", "changes": [], "entries": None}

    with open(coords_path(page), encoding="utf-8") as f:
        raw_text = f.read()
    entries = json.loads(raw_text)
    result["entries"] = entries
    result["indented"] = "\n" in raw_text.strip()

    json_ayahs = [(e["surahNumber"], e["ayahNumber"]) for e in entries]
    if json_ayahs != expected_ayahs:
        if page not in KEEP_JSON_AYAHS_PAGES:
            result["status"] = "skipped"
            result["message"] = "ayah list in JSON does not match hafs-ayah-meta.json"
            return result
        result["message"] = "meta differs from image; kept the existing JSON ayah list"
        expected_ayahs = json_ayahs

    image = load_page_image(page)
    height, width = image.shape[:2]
    lines = find_lines(image)
    markers = find_markers(image, lines)
    result["lines"] = lines
    result["markers"] = markers

    if len(markers) != len(expected_ayahs):
        result["status"] = "skipped"
        result["message"] = (
            f"found {len(markers)} markers but page has {len(expected_ayahs)} ayahs"
        )
        return result

    scale_x = COORD_WIDTH / width
    scale_y = COORD_HEIGHT / height

    # Keep the same right edge the existing polygons use (341.0 / 341.5).
    right_edge_coord = max(
        x for e in entries for shape in parse_polygon(e["polygon"]) for x, _ in shape
    )
    right_edge_px = right_edge_coord / scale_x

    edges = line_band_edges(lines, height)
    pixel_rects = build_rectangles(lines, markers, expected_ayahs, right_edge_px)

    for entry, marker, rects in zip(entries, markers, pixel_rects):
        new_x = round(marker["center_x"] * scale_x, 2)
        new_y = round(marker["center_y"] * scale_y, 2)

        coord_rects = []
        for left, top_line, right, bottom_line in rects:
            left_c = 0.0 if left <= 0 else left * scale_x
            right_c = right_edge_coord if right >= right_edge_px else right * scale_x
            coord_rects.append((
                left_c,
                edges[top_line][0] * scale_y,
                right_c,
                edges[bottom_line][1] * scale_y,
            ))
        new_polygon = rects_to_polygon(coord_rects)

        dx = new_x - entry["x"]
        dy = new_y - entry["y"]
        move_marker = abs(dx) > TOLERANCE or abs(dy) > TOLERANCE
        move_polygon = not polygons_match(entry["polygon"], new_polygon)
        if not move_marker and not move_polygon:
            continue

        result["changes"].append({
            "surah": entry["surahNumber"],
            "ayah": entry["ayahNumber"],
            "old_x": entry["x"],
            "old_y": entry["y"],
            "new_x": new_x if move_marker else entry["x"],
            "new_y": new_y if move_marker else entry["y"],
            "old_polygon": entry["polygon"],
            "new_polygon": new_polygon if move_polygon else entry["polygon"],
            "move_marker": move_marker,
            "move_polygon": move_polygon,
        })
    return result


def apply_page(result):
    """Writes the detected changes back to the page JSON (same formatting style)."""
    changes = {(c["surah"], c["ayah"]): c for c in result["changes"]}
    for entry in result["entries"]:
        change = changes.get((entry["surahNumber"], entry["ayahNumber"]))
        if change is None:
            continue
        entry["x"] = change["new_x"]
        entry["y"] = change["new_y"]
        entry["polygon"] = change["new_polygon"]

    if result["indented"]:
        text = json.dumps(result["entries"], ensure_ascii=False, indent=4)
    else:
        text = json.dumps(result["entries"], ensure_ascii=False)
    with open(coords_path(result["page"]), "w", encoding="utf-8") as f:
        f.write(text)


def save_preview(result, folder):
    """Draws the corrected polygons and markers on the dark page image."""
    page = result["page"]
    image = load_page_image(page).astype(np.uint8)
    canvas = Image.new("RGB", (image.shape[1], image.shape[0]), (0, 0, 0))
    source = Image.fromarray(image, "RGBA")
    canvas.paste(source, mask=source.split()[3])

    scale_x = canvas.width / COORD_WIDTH
    scale_y = canvas.height / COORD_HEIGHT
    changes = {(c["surah"], c["ayah"]): c for c in result["changes"]}
    colors = [(255, 60, 60), (60, 200, 60), (80, 120, 255), (220, 60, 220), (0, 200, 200)]

    draw = ImageDraw.Draw(canvas, "RGBA")
    for i, entry in enumerate(result["entries"]):
        change = changes.get((entry["surahNumber"], entry["ayahNumber"]))
        polygon = change["new_polygon"] if change else entry["polygon"]
        x = change["new_x"] if change else entry["x"]
        y = change["new_y"] if change else entry["y"]
        color = colors[i % len(colors)]
        for shape in parse_polygon(polygon):
            points = [(px * scale_x, py * scale_y) for px, py in shape]
            draw.polygon(points, outline=color + (255,), fill=color + (45,))
        cx, cy = x * scale_x, y * scale_y
        draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], outline=color + (255,), width=2)
        draw.text((cx + 7, cy - 6), str(entry["ayahNumber"]), fill=color + (255,))

    os.makedirs(folder, exist_ok=True)
    canvas.save(os.path.join(folder, f"{page:03d}.png"))


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

def write_report(results, applied, report_path):
    """Writes a Markdown report of all detected corrections."""
    out = ["# Quran coordinate corrections", ""]
    out.append(f"Applied to JSON: **{'yes' if applied else 'no (report only)'}**")
    out.append("")
    out.append("| Page | Status | Ayahs | Changed | Max abs dx | Max abs dy | Note |")
    out.append("|---:|---|---:|---:|---:|---:|---|")
    for r in results:
        changes = r["changes"]
        max_dx = max((abs(c["new_x"] - c["old_x"]) for c in changes), default=0)
        max_dy = max((abs(c["new_y"] - c["old_y"]) for c in changes), default=0)
        count = len(r["entries"]) if r["entries"] else 0
        out.append(
            f"| {r['page']} | {r['status']} | {count} | {len(changes)} "
            f"| {max_dx:.2f} | {max_dy:.2f} | {r['message']} |"
        )
    out.append("")

    for r in results:
        if not r["changes"]:
            continue
        out.append(f"## Page {r['page']}")
        out.append("")
        out.append("| Ayah | x (old -> new) | y (old -> new) | Polygon |")
        out.append("|---|---|---|---|")
        for c in r["changes"]:
            polygon_note = "unchanged"
            if c["move_polygon"]:
                old_count = len(parse_polygon(c["old_polygon"]))
                new_count = len(parse_polygon(c["new_polygon"]))
                polygon_note = f"updated ({old_count} -> {new_count} rects)"
            out.append(
                f"| {c['surah']}:{c['ayah']} "
                f"| {c['old_x']} -> {c['new_x']} ({c['new_x'] - c['old_x']:+.2f}) "
                f"| {c['old_y']} -> {c['new_y']} ({c['new_y'] - c['old_y']:+.2f}) "
                f"| {polygon_note} |"
            )
        out.append("")

    with open(report_path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))


def main():
    """Analyzes the target pages, writes the report and optionally applies it."""
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--apply", action="store_true", help="write corrections to the JSON files")
    parser.add_argument("--preview", metavar="DIR", help="save corrected overlay PNGs to DIR")
    parser.add_argument(
        "--pages", type=int, nargs="+", metavar="N",
        help="only process these pages (must be listed in TARGET_PAGES)",
    )
    parser.add_argument("--report", metavar="PATH", default=REPORT_PATH, help="report file path")
    args = parser.parse_args()

    pages = TARGET_PAGES
    if args.pages:
        unknown = [p for p in args.pages if p not in TARGET_PAGES]
        if unknown:
            parser.error(f"pages not in TARGET_PAGES: {unknown}")
        pages = args.pages

    page_ayahs = load_page_ayahs()
    results = []
    for page in pages:
        result = analyze_page(page, page_ayahs.get(page, []))
        results.append(result)
        print(f"page {page:3d}: {result['status']:7s} changed={len(result['changes']):2d} {result['message']}")
        if args.preview and result["status"] == "ok":
            save_preview(result, args.preview)

    if args.apply:
        for result in results:
            if result["status"] == "ok" and result["changes"]:
                apply_page(result)

    write_report(results, args.apply, args.report)
    print(f"\nReport: {args.report}")
    if not args.apply:
        print("Report only. Run again with --apply to write the corrections.")


if __name__ == "__main__":
    main()
