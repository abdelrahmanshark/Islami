/**
 * Fetches sermons from the Sermons by Islamic Network API
 * and saves only Arabic MP3 editions for the Flutter app.
 *
 * Usage: node scripts/fetch_sermons.js
 * Output: assets/data/sermons.json
 */

const fs = require('fs');
const path = require('path');

const API_BASE = 'https://sermons.islamic.network/api';
const OUTPUT_PATH = path.join(__dirname, '..', 'assets', 'data', 'sermons.json');

// Fetches JSON from a URL and throws a clear error on failure.
async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Request failed (${response.status}): ${url}`);
  }
  return response.json();
}

// Returns the Arabic MP3 edition URL, or null if none exists.
function findArabicMp3Url(editions) {
  if (!Array.isArray(editions)) return null;

  const arabicMp3 = editions.find(
    (edition) => edition.language === 'ar' && edition.format === 'mp3',
  );

  return arabicMp3?.url ?? null;
}

// Maps one API sermon to the app's slim JSON shape.
function toAppSermon(sermon) {
  const audioUrl = findArabicMp3Url(sermon.editions);
  if (!audioUrl) return null;

  return {
    titleEn: sermon.title ?? '',
    titleAr: '',
    audioUrl,
  };
}

// Extracts sermons from a year payload (array of month groups).
function extractSermonsFromYear(yearData) {
  const result = [];

  if (!Array.isArray(yearData)) return result;

  for (const monthGroup of yearData) {
    const sermons = monthGroup?.sermons;
    if (!Array.isArray(sermons)) continue;

    for (const sermon of sermons) {
      const appSermon = toAppSermon(sermon);
      if (appSermon) result.push(appSermon);
    }
  }

  return result;
}

async function main() {
  console.log('Fetching sources...');
  const sources = await fetchJson(`${API_BASE}/sources.json`);

  const allSermons = [];
  const seenAudioUrls = new Set();

  for (const source of sources) {
    const handle = source.handle;
    const years = source.years ?? [];

    console.log(`Source: ${handle} (${years.length} years)`);

    for (const year of years) {
      const url = `${API_BASE}/${handle}/${year}.json`;
      process.stdout.write(`  ${year}... `);

      try {
        const yearData = await fetchJson(url);
        const sermons = extractSermonsFromYear(yearData);

        let added = 0;
        for (const sermon of sermons) {
          // Skip duplicate audio URLs across months/years.
          if (seenAudioUrls.has(sermon.audioUrl)) continue;
          seenAudioUrls.add(sermon.audioUrl);
          allSermons.push(sermon);
          added += 1;
        }

        console.log(`${added} Arabic MP3 sermons`);
      } catch (error) {
        console.log(`skipped (${error.message})`);
      }
    }
  }

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, `${JSON.stringify(allSermons, null, 2)}\n`, 'utf8');

  console.log(`\nSaved ${allSermons.length} sermons to ${OUTPUT_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
