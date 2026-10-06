"""Crop Mushaf pages so the text and sura headers touch the image edges.

- Pages 1 and 2 are left untouched.
- Pages 3..604 are cropped with ONE shared box so every page keeps the same size.
- Left/right come from the sura header of the reference page (it is wider than the text).
- Top/bottom come from the highest / lowest content found on all cropped pages.

Originals are copied to assets/pages_original/ on the first run, and every run
reads from that backup, so running the script again gives the same result.

Usage (from the project root):
    python scripts/crop_quran_pages.py
"""

import shutil
from pathlib import Path

from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PAGES_DIR = PROJECT_ROOT / "assets" / "pages"
BACKUP_DIR = PROJECT_ROOT / "assets" / "pages_original"

FIRST_PAGE = 3
LAST_PAGE = 604
REFERENCE_PAGE = 50  # Page that starts with a sura header (Al Imran).


def page_name(page_number):
    """Return the file name of a page, e.g. 50 -> page-050.png."""
    return f"page-{page_number:03d}.png"


def load_alpha(path):
    """Open a page and return its alpha channel (the background is transparent)."""
    with Image.open(path) as image:
        return image.convert("RGBA").getchannel("A")


def find_header_columns(reference_path):
    """Return (left, right) of the sura header: the first block of rows that has content."""
    alpha = load_alpha(reference_path)
    width, height = alpha.size

    header_top = None
    header_bottom = None
    for y in range(height):
        row_has_content = alpha.crop((0, y, width, y + 1)).getbbox() is not None
        if row_has_content and header_top is None:
            header_top = y
        elif not row_has_content and header_top is not None:
            header_bottom = y
            break

    if header_top is None:
        raise ValueError(f"No content found in {reference_path.name}")
    if header_bottom is None:
        header_bottom = height

    left, _, right, _ = alpha.crop((0, header_top, width, header_bottom)).getbbox()
    return left, right


def find_vertical_bounds(page_paths, left, right):
    """Return (top, bottom) that fits the content of all pages inside the left/right strip."""
    top = None
    bottom = None
    for path in page_paths:
        alpha = load_alpha(path)
        box = alpha.crop((left, 0, right, alpha.height)).getbbox()
        if box is None:
            continue
        page_top = box[1]
        page_bottom = box[3]
        if top is None or page_top < top:
            top = page_top
        if bottom is None or page_bottom > bottom:
            bottom = page_bottom
    return top, bottom


def backup_originals(page_numbers):
    """Copy the original pages to BACKUP_DIR once, so they are never lost."""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    for page_number in page_numbers:
        source = PAGES_DIR / page_name(page_number)
        target = BACKUP_DIR / page_name(page_number)
        if source.exists() and not target.exists():
            shutil.copy2(source, target)


def main():
    """Back up the pages, measure one shared crop box, then crop every page with it."""
    all_numbers = range(FIRST_PAGE, LAST_PAGE + 1)
    backup_originals(all_numbers)

    page_numbers = [n for n in all_numbers if (BACKUP_DIR / page_name(n)).exists()]
    missing = [n for n in all_numbers if n not in page_numbers]
    original_paths = [BACKUP_DIR / page_name(n) for n in page_numbers]

    left, right = find_header_columns(BACKUP_DIR / page_name(REFERENCE_PAGE))
    top, bottom = find_vertical_bounds(original_paths, left, right)
    crop_box = (left, top, right, bottom)

    for path in original_paths:
        with Image.open(path) as image:
            image.crop(crop_box).save(PAGES_DIR / path.name, optimize=True)

    print(f"Crop box (left, top, right, bottom): {crop_box}")
    print(f"New page size: {right - left} x {bottom - top}")
    print(f"Cropped {len(page_numbers)} pages")
    if missing:
        print(f"Missing pages (skipped): {missing}")


if __name__ == "__main__":
    main()
