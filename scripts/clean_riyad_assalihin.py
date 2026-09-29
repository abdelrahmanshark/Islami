import json

JSON_PATH = "assets/json/riyad_assalihin.json"


# Read the JSON file and return its content as a Python dictionary.
def load_json(path):
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


# Write the dictionary back to the JSON file, keeping Arabic letters readable.
def save_json(path, data):
    with open(path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False)


# Build the cleaned structure: Arabic chapters, each holding its own Arabic hadiths.
def clean_data(data):
    chapters = []
    chapters_by_id = {}

    for chapter in data["chapters"]:
        clean_chapter = {
            "id": chapter["id"],
            "title": chapter["arabic"],
            "hadiths": [],
        }
        chapters.append(clean_chapter)
        chapters_by_id[chapter["id"]] = clean_chapter

    for hadith in data["hadiths"]:
        chapter = chapters_by_id.get(hadith["chapterId"])
        if chapter is None:
            print("Skipped hadith with unknown chapterId:", hadith["id"])
            continue

        chapter["hadiths"].append({
            "id": hadith["id"],
            "text": hadith["arabic"],
        })

    return {"chapters": chapters}


# Run the cleaning steps and overwrite the original file.
def main():
    data = load_json(JSON_PATH)
    cleaned = clean_data(data)
    save_json(JSON_PATH, cleaned)

    total_hadiths = 0
    for chapter in cleaned["chapters"]:
        total_hadiths += len(chapter["hadiths"])

    print("Chapters:", len(cleaned["chapters"]))
    print("Hadiths:", total_hadiths)


if __name__ == "__main__":
    main()
