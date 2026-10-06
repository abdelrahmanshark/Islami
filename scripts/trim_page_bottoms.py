"""Remove the empty space under the text of the cropped Mushaf pages.

crop_quran_pages.py cropped pages 3..604 with one shared box, so a few tall
pages (mostly the last ones) left ~100 px of empty space under most pages.

This script picks one shared height that fits most pages, then:
- Pages whose content fits are cropped to that height.
- Taller pages are scaled down evenly (no stretching) to that height and
  centered with transparent padding on the left and right.
Every page keeps the same size, so the app layout does not change.

The current pages are copied to assets/pages_before_bottom_trim/ on the first
run, and every run reads from that backup, so running it again gives the same result.

Usage (from the project root):
    python scripts/trim_page_bottoms.py          # report only
    python scripts/trim_page_bottoms.py --apply  # report + write the pages
"""

import argparse
import shutil
from pathlib import Path

from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PAGES_DIR = PROJECT_ROOT / "assets" / "pages"
BACKUP_DIR = PROJECT_ROOT / "assets" / "pages_before_bottom_trim"

FIRST_PAGE = 3
LAST_PAGE = 604

# Share of pages that must fit the new height without scaling (0..100).
FIT_PERCENTILE = 95

# Empty rows kept under the lowest content of the shared height.
BOTTOM_PADDING = 0


def page_name(page_number):
    """Return the file name of a page, e.g. 50 -> page-050.png."""
    return f"page-{page_number:03d}.png"


def find_content_bottom(path):
    """Return the y just below the lowest non-transparent pixel of a page."""
    with Image.open(path) as image:
        box = image.convert("RGBA").getchannel("A").getbbox()
    if box is None:
        return 0
    return box[3]


def backup_pages(page_numbers):
    """Copy the current pages to BACKUP_DIR once, so they are never lost."""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    for page_number in page_numbers:
        source = PAGES_DIR / page_name(page_number)
        target = BACKUP_DIR / page_name(page_number)
        if source.exists() and not target.exists():
            shutil.copy2(source, target)


def pick_target_height(bottoms):
    """Return the height that FIT_PERCENTILE % of the pages fit in."""
    sorted_bottoms = sorted(bottoms)
    index = round(len(sorted_bottoms) * FIT_PERCENTILE / 100) - 1
    index = max(0, min(index, len(sorted_bottoms) - 1))
    return sorted_bottoms[index] + BOTTOM_PADDING


def trim_page(path, content_bottom, target_height):
    """Return the page cropped to target_height, scaled down first if it is taller."""
    with Image.open(path) as source:
        image = source.convert("RGBA")
    width = image.width

    if content_bottom <= target_height:
        return image.crop((0, 0, width, target_height))

    content = image.crop((0, 0, width, content_bottom))
    scale = target_height / content_bottom
    scaled_width = round(width * scale)
    scaled = content.resize((scaled_width, target_height), Image.Resampling.LANCZOS)

    page = Image.new("RGBA", (width, target_height), (0, 0, 0, 0))
    page.paste(scaled, ((width - scaled_width) // 2, 0))
    return page


def main():
    """Measure every page, print the plan, and write the pages when --apply is given."""
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--apply", action="store_true", help="write the trimmed pages")
    args = parser.parse_args()

    all_numbers = range(FIRST_PAGE, LAST_PAGE + 1)
    backup_pages(all_numbers)

    page_numbers = [n for n in all_numbers if (BACKUP_DIR / page_name(n)).exists()]
    missing = [n for n in all_numbers if n not in page_numbers]

    bottoms = {}
    for page_number in page_numbers:
        bottoms[page_number] = find_content_bottom(BACKUP_DIR / page_name(page_number))

    with Image.open(BACKUP_DIR / page_name(page_numbers[0])) as first_page:
        width, old_height = first_page.size
    target_height = pick_target_height(list(bottoms.values()))
    scaled_pages = [n for n in page_numbers if bottoms[n] > target_height]

    print(f"Old page size: {width} x {old_height}")
    print(f"New page size: {width} x {target_height} ({old_height - target_height} px removed)")
    print(f"Pages cropped only: {len(page_numbers) - len(scaled_pages)}")
    print(f"Pages scaled down ({len(scaled_pages)}):")
    for page_number in scaled_pages:
        scale = target_height / bottoms[page_number]
        side_padding = (width - round(width * scale)) // 2
        print(f"  page {page_number:3d}: scale {scale:.3f}, side padding {side_padding} px")
    if missing:
        print(f"Missing pages (skipped): {missing}")

    if not args.apply:
        print("\nReport only. Run again with --apply to write the pages.")
        return

    for page_number in page_numbers:
        source = BACKUP_DIR / page_name(page_number)
        page = trim_page(source, bottoms[page_number], target_height)
        page.save(PAGES_DIR / page_name(page_number), optimize=True)
    print(f"\nWrote {len(page_numbers)} pages to {PAGES_DIR}")


if __name__ == "__main__":
    main()
