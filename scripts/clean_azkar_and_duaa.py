import json
import os
import shutil

JSON_PATH = "assets/json/azkar_and_duaa.json"
BACKUP_PATH = "assets/json/azkar_and_duaa_backup.json"

# Possible key names used by different versions of the source data.
CATEGORY_NAME_KEYS = ["category", "Category", "name", "Name", "title", "Title"]
ITEMS_KEYS = ["items", "Items", "Adhkar", "adhkar", "azkar", "Azkar", "array"]
TEXT_KEYS = ["text", "Text", "content", "Content", "zekr", "Zekr", "dua", "Dua"]
COUNT_KEYS = ["count", "Count", "repeat", "Repeat", "times", "Times"]

ARABIC_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")


# Read the JSON file and return its content.
def load_json(path):
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


# Write the data to the JSON file, keeping Arabic letters readable.
def save_json(path, data):
    with open(path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)


# Copy the original file once, so re-running never overwrites the first backup.
def create_backup():
    if os.path.exists(BACKUP_PATH):
        print("Backup already exists, keeping it:", BACKUP_PATH)
        return
    shutil.copyfile(JSON_PATH, BACKUP_PATH)
    print("Backup created:", BACKUP_PATH)


# Return the value of the first key found in the dictionary, or None.
def get_first_value(data, keys):
    for key in keys:
        if key in data:
            return data[key]
    return None


# Convert a count value to a positive integer, or None if it cannot be determined.
def parse_count(value):
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value if value > 0 else None
    if isinstance(value, float):
        return int(value) if value > 0 else None
    if isinstance(value, str):
        digits = value.strip().translate(ARABIC_DIGITS)
        if digits.isdigit() and int(digits) > 0:
            return int(digits)
    return None


# Clean one item and return (item, was_count_defaulted), or (None, False) if invalid.
def clean_item(raw_item):
    if isinstance(raw_item, str):
        text = raw_item
        raw_count = None
    elif isinstance(raw_item, dict):
        text = get_first_value(raw_item, TEXT_KEYS)
        raw_count = get_first_value(raw_item, COUNT_KEYS)
    else:
        return None, False

    if not isinstance(text, str) or not text.strip():
        return None, False

    count = parse_count(raw_count)
    was_defaulted = count is None
    if was_defaulted:
        count = 1

    return {"text": text.strip(), "count": count}, was_defaulted


# Turn the source data into a list of (category_name, raw_items) pairs.
def extract_raw_categories(data):
    raw_categories = []

    # Shape 1: { "category name": { "Adhkar": [...] } } or { "category name": [...] }
    if isinstance(data, dict):
        for name, value in data.items():
            if isinstance(value, dict):
                items = get_first_value(value, ITEMS_KEYS)
            else:
                items = value
            raw_categories.append((name, items))

    # Shape 2: [ { "category": "...", "items": [...] } ]
    elif isinstance(data, list):
        for entry in data:
            if not isinstance(entry, dict):
                continue
            name = get_first_value(entry, CATEGORY_NAME_KEYS)
            items = get_first_value(entry, ITEMS_KEYS)
            raw_categories.append((name, items))

    return raw_categories


# Build the cleaned list of categories and count how many items got a default count.
def clean_data(data):
    categories = []
    categories_by_name = {}
    defaulted_count = 0

    for name, raw_items in extract_raw_categories(data):
        if not isinstance(name, str) or not name.strip():
            continue
        if not isinstance(raw_items, list):
            continue

        name = name.strip()
        category = categories_by_name.get(name)
        if category is None:
            category = {"category": name, "items": []}
            categories_by_name[name] = category
            categories.append(category)

        for raw_item in raw_items:
            item, was_defaulted = clean_item(raw_item)
            if item is None:
                continue
            category["items"].append(item)
            if was_defaulted:
                defaulted_count += 1

    non_empty_categories = []
    for category in categories:
        if category["items"]:
            non_empty_categories.append(category)

    return non_empty_categories, defaulted_count


# Run the cleaning steps, back up the original, and overwrite it with the result.
def main():
    data = load_json(JSON_PATH)
    cleaned, defaulted_count = clean_data(data)

    if not cleaned:
        print("No valid categories found. File was not modified.")
        return

    create_backup()
    save_json(JSON_PATH, cleaned)

    total_items = 0
    for category in cleaned:
        total_items += len(category["items"])

    print("Categories:", len(cleaned))
    print("Total items:", total_items)
    print("Items with count defaulted to 1:", defaulted_count)


if __name__ == "__main__":
    main()
