import json

WAHIDI_PATH = "assets/json/asbab_wahidi.json"
MUHARRAR_PATH = "assets/json/asbab_muharrar.json"
OUTPUT_PATH = "assets/json/asbab.json"

WAHIDI_SOURCE = "الواحدي"
MUHARRAR_SOURCE = "المحرر"


# Read a JSON file and return its content as a Python dictionary.
def load_json(path):
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


# Write data to a JSON file, keeping Arabic letters readable.
def save_json(path, data):
    with open(path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)


# Join the text of all content pages of one entry without changing it.
def join_content_text(entry):
    texts = []
    for content in entry["content"]:
        texts.append(content["text"])
    return "\n".join(texts)


# Turn one source file into a dictionary: (surah, ayahs) -> text.
# Entries that share the same "ayahs" range in their content are the same
# reason repeated for every ayah of the range, so they are grouped into one.
def read_source(path):
    data = load_json(path)

    groups = {}
    for entry in data["ayahs"]:
        range_id = entry["content"][0]["ayahs"]
        group_key = (entry["surah"], range_id)

        if group_key not in groups:
            groups[group_key] = {
                "surah": entry["surah"],
                "ayahs": [],
                "text": join_content_text(entry),
            }
        groups[group_key]["ayahs"].append(entry["ayah"])

    reasons = {}
    for group in groups.values():
        ayahs = sorted(group["ayahs"])
        key = (group["surah"], tuple(ayahs))
        reasons[key] = group["text"]

    return reasons


# Merge both sources into one sorted list of entries with their reasons.
def merge_sources(wahidi, muharrar):
    all_keys = set(wahidi.keys()) | set(muharrar.keys())
    sorted_keys = sorted(all_keys)

    merged = []
    for key in sorted_keys:
        surah, ayahs = key
        reasons = []

        if key in wahidi:
            reasons.append({"source": WAHIDI_SOURCE, "text": wahidi[key]})
        if key in muharrar:
            reasons.append({"source": MUHARRAR_SOURCE, "text": muharrar[key]})

        merged.append({
            "surah": surah,
            "ayahs": list(ayahs),
            "reasons": reasons,
        })

    return merged


# Run the merge, save the result, and print a short summary.
def main():
    wahidi = read_source(WAHIDI_PATH)
    muharrar = read_source(MUHARRAR_PATH)

    merged = merge_sources(wahidi, muharrar)
    save_json(OUTPUT_PATH, merged)

    in_both = 0
    for key in wahidi:
        if key in muharrar:
            in_both += 1

    print("Al-Wahidi entries:", len(wahidi))
    print("Al-Muharrar entries:", len(muharrar))
    print("Merged entries:", len(merged))
    print("Found in both sources:", in_both)
    print("Only in Al-Wahidi:", len(wahidi) - in_both)
    print("Only in Al-Muharrar:", len(muharrar) - in_both)
    print("Output:", OUTPUT_PATH)


if __name__ == "__main__":
    main()
