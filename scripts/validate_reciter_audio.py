"""
Validate the Surah 002 (Al-Baqarah) audio link for every reciter in the app.

The reciter list is built exactly like the app does it
(see lib/data/radio/radio_repository.dart):
  1. Fetch reciters from the mp3quran API (same URL as RadioRemoteDataSource).
     Each reciter's server = the first item in its "moshaf" list.
  2. Load Mishary from assets/json/mshary.json (same as MsharyLocalDataSource).
     His server = the folder part of the first sura's mp3 URL.
  3. Remove the old API Mishary entry (and any API duplicate of the new name),
     then put the local Mishary entry at the top.

The audio URL is built like the app: server + "002.mp3".

This script only reads data. It never changes the app's files.
The report is overwritten on every run, so it is safe to run repeatedly.

Usage:
    python scripts/validate_reciter_audio.py
"""

import json
import os
import sys
from datetime import datetime

import requests

# Same values used by the app.
RECITERS_API_URL = "https://mp3quran.net/api/v3/reciters?language=ar"
OLD_API_MSHARY_NAME = "مشاري العفاسي"
MSHARY_DISPLAY_NAME = "مشاري راشد العفاسي"
MSHARY_LOCAL_ID = 1008008

SURA_NUMBER = 2
TIMEOUT_SECONDS = 15

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
MSHARY_JSON_PATH = os.path.join(PROJECT_ROOT, "assets", "json", "mshary.json")
REPORT_PATH = os.path.join(SCRIPT_DIR, "broken_reciters_surah_002.json")

# Result categories.
WORKING = "working"
NOT_FOUND = "not_found"
HTTP_ERROR = "http_error"
REQUEST_ERROR = "request_error"


def fetch_api_reciters(session):
    """Download the reciters list from the mp3quran API (like RadioRemoteDataSource)."""
    response = session.get(RECITERS_API_URL, timeout=TIMEOUT_SECONDS)
    response.raise_for_status()
    data = response.json()

    reciters = []
    for item in data.get("reciters", []):
        server = None
        moshaf_list = item.get("moshaf")
        if isinstance(moshaf_list, list) and len(moshaf_list) > 0:
            server = moshaf_list[0].get("server")

        reciters.append({
            "id": item.get("id"),
            "name": (item.get("name") or "").strip(),
            "server": server,
        })
    return reciters


def load_mshary_reciter():
    """Build the Mishary reciter from mshary.json (like MsharyLocalDataSource)."""
    with open(MSHARY_JSON_PATH, encoding="utf-8") as file:
        suras = json.load(file)

    if len(suras) == 0:
        raise ValueError("mshary.json is empty")

    first = suras[0]
    mp3_url = first.get("mp3", "")
    slash_index = mp3_url.rfind("/")
    if slash_index >= 0:
        server = mp3_url[: slash_index + 1]
    else:
        server = mp3_url

    name = (first.get("category") or "").strip()
    if name == "":
        name = MSHARY_DISPLAY_NAME

    return {"id": MSHARY_LOCAL_ID, "name": name, "server": server}


def load_all_reciters(session):
    """Merge API reciters with local Mishary (like RadioRepositoryImpl.getReciters)."""
    api_reciters = fetch_api_reciters(session)
    mshary = load_mshary_reciter()

    filtered = []
    for reciter in api_reciters:
        name = reciter["name"]
        if name != OLD_API_MSHARY_NAME and name != mshary["name"]:
            filtered.append(reciter)

    return [mshary] + filtered


def build_sura_url(server, sura_number):
    """Build the sura audio URL the same way the app does: server + '002.mp3'."""
    padded = str(sura_number).zfill(3)
    return f"{server}{padded}.mp3"


def check_url(session, url):
    """
    Check if the URL exists without downloading the audio.
    Returns (category, status_code, error_message, final_url).
    """
    try:
        # HEAD is the cheapest check. Redirects are followed.
        response = session.head(url, timeout=TIMEOUT_SECONDS, allow_redirects=True)
        if 200 <= response.status_code < 300:
            return WORKING, response.status_code, None, response.url

        # Some servers do not handle HEAD correctly, so double-check with GET.
        # stream=True means the body is not downloaded; we close right away.
        with session.get(
            url,
            timeout=TIMEOUT_SECONDS,
            allow_redirects=True,
            stream=True,
            headers={"Range": "bytes=0-0"},
        ) as get_response:
            status = get_response.status_code
            final_url = get_response.url

        if 200 <= status < 300:
            return WORKING, status, None, final_url
        if status == 404:
            return NOT_FOUND, status, "404 Not Found", final_url
        return HTTP_ERROR, status, f"HTTP {status}", final_url

    except requests.exceptions.Timeout:
        return REQUEST_ERROR, None, "Timeout", url
    except requests.exceptions.ConnectionError as error:
        return REQUEST_ERROR, None, f"Connection error: {error}", url
    except requests.exceptions.RequestException as error:
        return REQUEST_ERROR, None, f"Request error: {error}", url


def save_report(report):
    """Write the report to a temp file first, then replace, so a crash never leaves a broken file."""
    temp_path = REPORT_PATH + ".tmp"
    with open(temp_path, "w", encoding="utf-8") as file:
        json.dump(report, file, ensure_ascii=False, indent=2)
    os.replace(temp_path, REPORT_PATH)


def main():
    """Load reciters, check each Surah 002 link, print a summary, and save the report."""
    # Make Arabic names print correctly on the Windows console.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    session = requests.Session()
    session.headers.update({"User-Agent": "islami-audio-link-validator/1.0"})

    print("Loading reciters...")
    try:
        reciters = load_all_reciters(session)
    except (requests.exceptions.RequestException, ValueError, OSError) as error:
        print(f"Could not load reciters: {error}")
        sys.exit(1)

    total = len(reciters)
    print(f"Found {total} reciters. Checking Surah {SURA_NUMBER:03d}...\n")

    working_count = 0
    not_found = []
    http_errors = []
    request_errors = []

    for index, reciter in enumerate(reciters, start=1):
        name = reciter["name"] or f"(no name, id={reciter['id']})"
        server = reciter["server"]

        if not server:
            url = None
            category, status, error, final_url = REQUEST_ERROR, None, "No server URL in reciter data", None
        else:
            url = build_sura_url(server, SURA_NUMBER)
            category, status, error, final_url = check_url(session, url)

        if category == WORKING:
            working_count += 1
            print(f"[{index}/{total}] OK       {name}")
            continue

        print(f"[{index}/{total}] BROKEN   {name} -> {error}")
        broken_item = {
            "id": reciter["id"],
            "name": name,
            "url": url,
            "final_url": final_url,
            "status_code": status,
            "error": error,
        }
        if category == NOT_FOUND:
            not_found.append(broken_item)
        elif category == HTTP_ERROR:
            http_errors.append(broken_item)
        else:
            request_errors.append(broken_item)

    other_errors_count = len(http_errors) + len(request_errors)
    all_broken = not_found + http_errors + request_errors

    print("\n========== SUMMARY ==========")
    print(f"Total reciters checked : {total}")
    print(f"Working                : {working_count}")
    print(f"404 Not Found          : {len(not_found)}")
    print(f"Other errors           : {other_errors_count}")
    print(f"  - HTTP errors        : {len(http_errors)}")
    print(f"  - Request errors     : {len(request_errors)}")

    if len(all_broken) > 0:
        print("\n========== BROKEN RECITERS ==========")
        for item in all_broken:
            status_text = item["status_code"] if item["status_code"] is not None else "-"
            print(f"- {item['name']}")
            print(f"    URL   : {item['url']}")
            print(f"    Status: {status_text} | {item['error']}")
    else:
        print("\nAll reciter links are working.")

    report = {
        "checked_at": datetime.now().isoformat(timespec="seconds"),
        "sura_number": SURA_NUMBER,
        "total_checked": total,
        "working_count": working_count,
        "not_found_count": len(not_found),
        "other_errors_count": other_errors_count,
        "not_found": not_found,
        "http_errors": http_errors,
        "request_errors": request_errors,
    }
    save_report(report)
    print(f"\nReport saved to: {REPORT_PATH}")


if __name__ == "__main__":
    main()
