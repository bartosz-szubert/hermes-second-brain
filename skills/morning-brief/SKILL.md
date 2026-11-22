---
name: morning-brief
description: "Morning brief: weather, moto, languages, self-check."
version: 1.0.5
author: Bartek + Claude
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [brief, morning, weather, motorcycle, self-check, cron]
    category: productivity
---

# Morning Brief

Use this skill when a scheduled job or the user asks for the morning brief.

Write the brief for the user in Polish. Time zone: Europe/Warsaw. The brief must be readable in one minute. Omit any section with no content entirely (no heading, no "no data"). Do not change configuration, scheduled jobs or skills. Never write anywhere under `/opt/vault`.

## Working files

- Folder: `/opt/data/agent-data/brief/`
- `lokalizacja.md`: temporary location overrides, one per line in the format `YYYY-MM-DD..YYYY-MM-DD: <town>` (first and last day, both included; a single day has the same date twice). If today falls within a line's range, use that town (if several lines match, the last one wins); otherwise the default location `<HOME_TOWN>`.
- `log.md`: before reading anything else, read its last 30 lines so you do not repeat quotes, phrases or questions. After preparing the brief, before ending your response, append one line: `YYYY-MM-DD | pogoda: <town> | motocykl: <ratings> | cytat/zwrot: <text> | pytanie: <text> | self-check: <OK or problems>`.

## Location override (in conversation)

When the user writes a message starting with "Brief:" about where they will be (e.g. "Brief: jutro jestem w Krakowie", "Brief: do niedzieli jestem w Gdyni", "Brief: od 3.11 do 7.11 Poznań"):
1. Work out the first and last day from today's date in Europe/Warsaw (the date of the user's message, not the session start). "jutro" = tomorrow only; "do <day>" = from today to that day; a single day = first and last day the same. If the dates are unclear, ask one short question before writing.
2. Check the town with the geocoding URL from section 1; if there is no match or several towns in Poland share the name, ask which one.
3. Append one line to `lokalizacja.md` (create the file if missing): `YYYY-MM-DD..YYYY-MM-DD: <town>`. Do not edit or delete earlier lines.
4. Read the file back and confirm in one line, e.g. "Brief: Gdynia od 29.10 do 01.11." If the write failed, say so.

"Brief: wracam do domu" (or similar) ends an override early: append a line for `<HOME_TOWN>` from the given day (default: today) to the last day of the latest range that is still active, so it wins as the last matching line. If no override is active, just confirm that the default already applies.

## 1. Weather

Fetch with `web_extract`:
https://api.open-meteo.com/v1/forecast?latitude=<LAT>&longitude=<LON>&hourly=temperature_2m,precipitation_probability,wind_gusts_10m,weather_code,visibility&daily=sunset,temperature_2m_min,temperature_2m_max,precipitation_probability_max&timezone=Europe%2FWarsaw&forecast_days=1

For another town, first get its coordinates from https://geocoding-api.open-meteo.com/v1/search?name=<town>&count=1&language=pl&countryCode=PL and put them into the URL above.

Report as bullet points (see Message format): min–max temperature, maximum chance of precipitation, morning fog (weather code 45 or 48, or visibility < 1000 m) and the strongest gust, sunset time. Use only the fetched numbers; never guess.

## 2. Motorcycle (only from 1 March to 31 October)

Windows:
- Commute (working days only): departure 7:00–8:00 and return 16:00–18:00, rated separately.
- Ride: from 16:00 until sunset. If sunset is before 16:30, write "za krótki dzień" (day too short).

Criteria for every hour in a window: temperature ≥ 15°C, precipitation probability < 15%, gusts < 50 km/h.

Rating:
- `dobra` (good): every hour meets the criteria and there is no fog,
- `tak sobie` (so-so): criteria met but there is fog (code 45/48 or visibility < 1000 m), or one value is close to the limit (temperature 12–14.9°C, precipitation 15–30%, gusts 50–60 km/h),
- `zła` (bad): any other case.

Format: two bullet points, `Dojazd: wyjazd <rating>, powrót <rating> – <short reason>` and `Przejażdżka: <rating> – <short reason>`.

## 3. Languages

For each language: English (`/opt/data/agent-data/tutor-en/`) and German (`/opt/data/agent-data/tutor-de/`). If a language's folder or its `log.md` does not exist, skip that language without comment.

Read the language's `log.md` and `cards.md` and write one line per language:
- If there is an entry for yesterday: one sentence (number of exchanges, main type of mistakes) and the number of flashcards due today or earlier.
- If the latest entry is 3 or more days old: a short nudge with the date of the last practice.
- If there was no practice yesterday but fewer than 3 days have passed since the last one: only the number of cards due.

## 4. Self-check (diagnostic only: change nothing, fix nothing)

1. Read: read `/opt/vault-stan/podstawa.txt`.
2. Write: overwrite `/opt/data/tmp/selfcheck.txt` with the current date and time, read it back and check that the content matches. Do not try to delete the file (there is no delete tool; the file is meant to stay).
3. Internet: the result of fetching the weather data for this brief.
4. Sync: in `/opt/vault-stan/wyniki.md` check whether any packages from the last 24 hours were rejected.
5. Tools: if you have access to a terminal, code execution or a browser, report it as a problem.
6. Backup: read `/opt/data/agent-data/status/backup.txt` (one line written by the nightly backup on the host; you may only read it). Report a problem if the file is missing, if the line contains "BŁĄD" (quote the text after it), or if its date is not today (Europe/Warsaw): "Kopia: brak nowej kopii od <DD.MM>". Never try to run, fix or rewrite the backup or its status file.

Result: one line "Hermes: OK", or on problems a short list "Hermes: <what is not working> – <reason>" (backup problems as "Kopia: <problem>"). Never reveal tokens, secrets or configuration.

## 5. Quote or phrase of the day

On even days of the month a quote, on odd days an English phrase.
- Quote: short, with its author, verified with a web search (give a link to the source). If you cannot confirm the author, give a phrase instead.
- Phrase: an idiom or colloquial expression useful in project work or a presentation, formatted as *phrase* (Polish meaning) plus one example sentence. Never invent phrases; if you are not sure a phrase is idiomatic, pick another.

## 6. Question for today

One short journal question (rotating: reflection, mood, goal, gratitude), not repeating any in `log.md`. Add: "Odpowiedz w temacie Dziennik."

## Message format

Every piece of information is a separate bullet point starting with "- " under a bold section heading. One fact per bullet, no paragraphs. Keep this layout (omit sections and bullets with no content):

```
Brief – <weekday in Polish> <DD.MM>

**Pogoda (<town>)**
- Temperatura: <min>–<max>°C
- Opady: do <max>%
- Rano: <mgła / bez mgły>, porywy do <max> km/h
- Zachód słońca: <HH:MM>

**Motocykl**
- Dojazd: wyjazd <rating>, powrót <rating> – <short reason>
- Przejażdżka: <rating> – <short reason>

**Języki**
- Angielski: ...
- Niemiecki: ...

**Cytat dnia** (or **Zwrot dnia**)
- ...

**Pytanie na dziś**
- <question> Odpowiedz w temacie Dziennik.

**Self-check**
- Hermes: OK (or one bullet per problem)
```

No emoji, no introduction and no closing summary.
