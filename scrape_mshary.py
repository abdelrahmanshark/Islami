"""
Scrape all 114 Alafasi (مشاري راشد العفاسي) surahs from surahquran.com.
Saves direct MP3 URLs to assets/json/mshary.json — does not download files.
"""

import json
import re
from pathlib import Path
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

BASE_URL = "https://surahquran.com"
INDEX_URL = f"{BASE_URL}/mp3/Alafasi/"
CATEGORY = "مشاري راشد العفاسي"
OUTPUT_PATH = Path("assets/json/mshary.json")

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


# Collect surah number + Arabic name + page URL from the index table.
def extract_surah_list(soup):
    surahs = []
    seen = set()

    for link in soup.find_all("a", href=True):
        href = link["href"].strip()
        match = re.search(r"/mp3/Alafasi/(\d+)\.html", href, re.I)
        if not match:
            continue

        number = int(match.group(1))
        if number < 1 or number > 114 or number in seen:
            continue

        name = clean_text(link.get_text())
        if not name:
            continue

        seen.add(number)
        surahs.append(
            {
                "number": number,
                "name": name,
                "page_url": urljoin(BASE_URL + "/", href),
            }
        )

    surahs.sort(key=lambda item: item["number"])
    return surahs


# Pull the direct .mp3 URL from a single surah page.
def extract_mp3_url(soup, page_url):
    # Prefer the audio player source tag.
    source = soup.find("source", src=re.compile(r"\.mp3($|\?)", re.I))
    if source and source.get("src"):
        return urljoin(page_url, source["src"].strip())

    # Fallback: any anchor pointing at an mp3 file.
    link = soup.find("a", href=re.compile(r"\.mp3($|\?)", re.I))
    if link and link.get("href"):
        return urljoin(page_url, link["href"].strip())

    # Last resort: regex in page HTML.
    html = str(soup)
    match = re.search(r"https?://[^\s\"'<>]+\.mp3", html, re.I)
    if match:
        return match.group(0)

    return None


# Scrape all surah pages and build the JSON list.
def scrape_all():
    print(f"Index: {INDEX_URL}")
    index_soup = get_soup(INDEX_URL)
    surah_list = extract_surah_list(index_soup)
    print(f"Found {len(surah_list)} surah links on index")

    results = []
    for item in surah_list:
        number = item["number"]
        padded = f"{number:03d}"
        print(f"  [{padded}] {item['name']} -> {item['page_url']}")

        page_soup = get_soup(item["page_url"])
        mp3_url = extract_mp3_url(page_soup, item["page_url"])
        if not mp3_url:
            raise RuntimeError(f"No MP3 found for surah {padded}: {item['page_url']}")

        results.append(
            {
                "number": padded,
                "name": item["name"],
                "mp3": mp3_url,
                "category": CATEGORY,
            }
        )

    return results


# Write JSON output (overwrite existing file).
def save_json(data, path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return path


def main():
    results = scrape_all()

    if len(results) != 114:
        raise RuntimeError(f"Expected 114 surahs, got {len(results)}")

    numbers = {item["number"] for item in results}
    expected = {f"{n:03d}" for n in range(1, 115)}
    missing = sorted(expected - numbers)
    if missing:
        raise RuntimeError(f"Missing surah numbers: {missing}")

    output_path = save_json(results, OUTPUT_PATH)
    print(f"Saved {len(results)} surahs to {output_path.resolve()}")
    print("First:", results[0])
    print("Last:", results[-1])


if __name__ == "__main__":
    main()
