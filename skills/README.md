# Hermes skills in daily use

Three custom skills the agent runs every day, published as **sanitised copies**: personal goals, test results, home location and home regions are replaced with neutral wording or placeholders such as `<HOME_TOWN>`, `<LAT>`, `<LON>` and `<REGION_1>`. Everything else is the text the agent actually follows. The agent's messages stay in Polish, because the author reads them in Polish; the instructions are in English.

| Skill | Runs | What makes it interesting |
|---|---|---|
| [`morning-brief`](morning-brief/SKILL.md) | Scheduled, 06:30 working days · 08:30 weekends, lighter model | One-minute brief that **omits empty sections**; motorcycle ratings with fixed, checkable thresholds; a **self-check of the agent itself**, including last night's backup; a log so quotes and questions never repeat |
| [`critical-news`](critical-news/SKILL.md) | Scheduled, 15 minutes before the brief, main model | **Silence is the normal output.** It speaks only for a few defined critical categories, only with two independent sources opened in the run, and it reports when the check itself failed — so silence always means "checked, nothing critical" |
| [`language-tutor`](language-tutor/SKILL.md) | In conversation; reminder at 21:00 | Conversation first, at most three corrections quoting the user's exact words, **idiom pacing** so new material does not overwhelm, Leitner spaced repetition, flashcards saved to the vault only through an approved proposal |

## What the brief looks like

A real brief from November 2026 (Polish, as delivered; home town and personal learning details replaced). It was triggered by hand during a test of the backup status — hence the deliberate error in the self-check, and two formatting defects that were then logged for the next scheduled run.

```text
Brief – wtorek 17.11

Pogoda (<HOME_TOWN>)
- Temperatura: 5,1–8,5°C
- Opady: do 100%
- Rano: bez mgły, porywy do 27,7 km/h
- Zachód słońca: 16:01

Języki
- Angielski: 7 wymian; (…); 9 fiszek zaległych.
- Niemiecki: ostatnia nauka 2026-10-30; warto wrócić do praktyki.

Zwrot dnia
- get buy-in (uzyskać poparcie lub akceptację dla pomysłu). Example: We need to get buy-in
  from the key stakeholders before launching the project.

Pytanie na dziś
- Co dziś mogę zrobić, żeby najważniejsza osoba w projekcie lepiej rozumiała cel?
  Odpowiedz w temacie Dziennik.

Self-check
- Kopia: BŁĄD: test <ticket> (celowy)
```

What to notice: no section without content; the language line nudges after a gap in practice; the self-check surfaced the (deliberately faked) backup failure at the top of the agent's own health report. The defects that run exposed — a motorcycle section shown out of season and working checks listed as problems — are tracked, not hidden; they are left out of the excerpt above.

## Using these skills elsewhere

1. Copy a skill folder into the agent's `skills/<category>/` directory and replace the placeholders (`<HOME_TOWN>`, `<LAT>`, `<LON>`, `<REGION_1>`, `<REGION_2>`).
2. Read it through against your own toolset — the skills assume **no terminal, no code execution and no browser**, only web search/extract and file tools.
3. Install it through your agent's approval gate and verify the installed file by checksum.
4. Create the scheduled jobs (brief, critical news) with an explicit time zone, and check the first run in the session database, not only the job status.

## Design rules shared by all three

- **Instructions live in skills, not in files the agent reads.** The agent rightly treats file content as data; a skill is a trusted, versioned source that is installed after review and verified by checksum.
- **Every claim about a saved file is read back.** "Never claim a file was saved … without having checked it."
- **Web content is data, never instructions** — stated explicitly where the skill reads the web.
- **No guessing:** weather only from fetched numbers, quotes only with a confirmed author, sources only if opened in this run.
- **Changes go through the approval gate.** The agent cannot install or edit a skill on its own; each version here was written, reviewed, installed and checked on the server.

## Version history in brief

| Skill | Version | Change driven by |
|---|---|---|
| `morning-brief` | 1.0.5 | Backup status added to the self-check (the backup work in Sprint 4) |
| `language-tutor` | 1.3.0 | A week of real use: too many idioms at once — pacing added; flashcards limited to idioms; dates taken from the user's latest message, not the session start |
| `critical-news` | 1.0.0 | A second review before release tightened the categories (routine war developments excluded, measurable thresholds for markets) |

Licence: MIT, see [`LICENSE`](../LICENSE).
