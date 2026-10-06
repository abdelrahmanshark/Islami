"""
Scrape Sharawy category lectures from sharawe.com into JSON.
Does NOT download any MP3 files — only saves direct MP3 URLs.
"""

import json
import re
from pathlib import Path
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

BASE_URL = "https://www.sharawe.com"
# Starting category page provided by the caller.
CATEGORY_URL = f"{BASE_URL}/catsmktba-51.html"
# Exact category name from the caller (do not replace with scraped page title).
CATEGORY_NAME = "قصص الأنبياء"
OUTPUT_PATH = Path("assets/json/sharawe/storys_of_phrophets.json")

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}

session = requests.Session()
session.headers.update(HEADERS)


# Fetch a page and parse it with BeautifulSoup.
def get_soup(url):
    response = session.get(url, timeout=30)
    response.raise_for_status()
    response.encoding = response.apparent_encoding or "utf-8"
    return BeautifulSoup(response.content, "html.parser")


# Clean whitespace from scraped text.
def clean_text(text):
    return re.sub(r"\s+", " ", (text or "")).strip()


# Turn a relative href into an absolute https URL.
def absolute_url(href):
    if not href:
        return None
    return urljoin(BASE_URL + "/", href.strip())


# Extract catsmktba id from a URL.
def catsmktba_id(url):
    match = re.search(r"catsmktba[=-](\d+)", url or "", re.I)
    return match.group(1) if match else None


# Discover subcategory/section links (linktable catsmktba-*.html style).
def extract_sections(soup, page_url):
    sections = []
    seen = set()
    current_id = catsmktba_id(page_url)

    for link in soup.select("a.linktable[href*='catsmktba-']"):
        href = link.get("href", "").strip()
        full_url = absolute_url(href)
        section_id = catsmktba_id(full_url)

        if not section_id or section_id == current_id:
            continue
        if section_id in seen:
            continue

        title = clean_text(link.get_text())
        if title.startswith("المحاضرات") or not title:
            continue

        seen.add(section_id)
        sections.append({"title": title, "url": full_url})

    return sections


# Find pagination page links for the same catsmktba category.
def extract_pagination_urls(soup, page_url):
    section_id = catsmktba_id(page_url)
    if not section_id:
        return []

    urls = []
    seen = {page_url}

    for link in soup.find_all("a", href=True):
        href = link["href"].strip()
        full_url = absolute_url(href)
        if not full_url:
            continue

        same_section = catsmktba_id(full_url) == section_id
        has_page_query = "page=" in full_url.lower()
        numbered_page = bool(
            re.search(rf"catsmktba-{section_id}[-_]p?age[-_]?\d+", full_url, re.I)
        )

        if same_section and (has_page_query or numbered_page):
            if full_url not in seen:
                seen.add(full_url)
                urls.append(full_url)

    return urls


# Extract lectures (title + mp3_url) from one listing page.
def extract_lectures_from_page(soup):
    lectures = []

    for play_link in soup.find_all("a", href=re.compile(r"play-\d+\.html", re.I)):
        title = clean_text(play_link.get_text())
        if not title:
            continue

        # Title cell is followed by the controls cell that holds the MP3 link.
        title_td = play_link.find_parent("td")
        if not title_td:
            continue

        controls_td = title_td.find_next_sibling("td")
        if not controls_td:
            continue

        mp3_link = controls_td.find("a", href=re.compile(r"\.mp3($|\?)", re.I))
        if not mp3_link:
            continue

        mp3_url = absolute_url(mp3_link.get("href"))
        if not mp3_url:
            continue
        # Skip site placeholder/intro audio, not a real lecture file.
        if mp3_url.rstrip("/").lower().endswith("/intro.mp3"):
            continue

        lectures.append({"title": title, "mp3_url": mp3_url})

    return lectures


# Scrape lectures from a page and follow its pagination.
def scrape_lectures_from_urls(start_urls):
    lectures = []
    seen_mp3 = set()
    visited = set()
    to_visit = list(start_urls)

    while to_visit:
        url = to_visit.pop(0)
        if url in visited:
            continue
        visited.add(url)

        print(f"  Fetching: {url}")
        soup = get_soup(url)

        for lecture in extract_lectures_from_page(soup):
            mp3_url = lecture["mp3_url"]
            if mp3_url in seen_mp3:
                continue
            seen_mp3.add(mp3_url)
            lectures.append(lecture)

        for page_url in extract_pagination_urls(soup, url):
            if page_url not in visited:
                to_visit.append(page_url)

    return lectures


# Expand nested catsmktba pages until leaf sections that list lectures.
def collect_leaf_sections(section):
    soup = get_soup(section["url"])
    nested = extract_sections(soup, section["url"])
    if not nested:
        return [section]

    leaves = []
    for child in nested:
        leaves.extend(collect_leaf_sections(child))
    return leaves


# Scrape all lecture pages for one subcategory section.
def scrape_section_lectures(section_url):
    return scrape_lectures_from_urls([section_url])


# Resolve output path and overwrite any existing file.
def prepare_output_path(path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    return path


# Build the full JSON hierarchy and save it.
def main():
    print(f"Category: {CATEGORY_NAME}")
    print(f"Start URL: {CATEGORY_URL}")

    first_soup = get_soup(CATEGORY_URL)
    sections_meta = extract_sections(first_soup, CATEGORY_URL)

    # Follow pagination for subcategory discovery if any exist.
    for page_url in extract_pagination_urls(first_soup, CATEGORY_URL):
        page_soup = get_soup(page_url)
        for section in extract_sections(page_soup, page_url):
            if all(s["url"] != section["url"] for s in sections_meta):
                sections_meta.append(section)

    # Nested categories (e.g. pillars) expand into leaf lecture sections.
    leaf_sections = []
    seen_urls = set()
    for section in sections_meta:
        for leaf in collect_leaf_sections(section):
            if leaf["url"] in seen_urls:
                continue
            seen_urls.add(leaf["url"])
            leaf_sections.append(leaf)

    if not sections_meta:
        leaf_sections = [{"title": CATEGORY_NAME, "url": CATEGORY_URL}]

    print(f"Found {len(leaf_sections)} leaf sections to scrape")
    sections = []

    for section in leaf_sections:
        print(f"  Scraping section: {section['title']}")
        lectures = scrape_section_lectures(section["url"])
        print(f"    -> {len(lectures)} lectures")
        if lectures:
            sections.append({"title": section["title"], "lectures": lectures})

    data = {
        "category": CATEGORY_NAME,
        "sections": sections,
    }

    output_path = prepare_output_path(OUTPUT_PATH)
    output_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    total = sum(len(s["lectures"]) for s in sections)
    empty = [s["title"] for s in leaf_sections if s["title"] not in {x["title"] for x in sections}]
    print(f"Saved {len(sections)} sections / {total} lectures to {output_path.resolve()}")
    if empty:
        print(f"Empty sections skipped: {empty}")


if __name__ == "__main__":
    main()
