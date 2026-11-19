# Postmortem: journal bot replied with garbled text (2026-09-26)

**Status:** final · **Written:** 2026-11-17 · **Format:** blameless

## Summary

On 26 September 2026 the private journal profile of the Hermes agent answered in Telegram with a 13,000-character block of incoherent text. The model's inference endpoint returned its raw reasoning trace in the answer field, and the agent forwarded it unchanged. The cause was the template's default configuration: a free model variant served through a third-party inference API, accepted before any model evaluation was done. The incident led to a clean rebuild of the agent and a model selection based on real-task tests.

## Impact

- One user (the author); private journal conversations in Telegram.
- The journal was unusable for about a day: one reply of 13,294 characters of mixed, incoherent text, followed by further unreliable behaviour until the configuration was changed.
- No data loss, no data exposure outside the system, no cost impact (free tier).

## Timeline (Europe/Warsaw)

Times come from the archived sessions database of the old installation unless marked otherwise.

| When | What |
|---|---|
| 21 Sep | Main configuration (from the hosting template) sets the default model to `upstage/solar-pro4:free` with provider `nous` and the Nous Research inference API as base URL. Confirmed in the archived `config.yaml`. |
| before 26 Sep | Earlier symptom: the bot sent extra, unwanted messages next to confirmations; the full default toolset was still enabled. *(author's observation at the time, not checked in data)* |
| 26 Sep 00:28–00:34 | Normal journal exchange (five short replies). |
| 26 Sep 11:24 | **Incident reply:** 13,294 characters, `finish_reason = stop`. The answer text is an exact prefix of the model's reasoning field (13,296 characters). |
| 26 Sep | Investigation: the profile configuration and the persona file were checked; the persona was clean. The container had no `sqlite3` binary, so the sessions database was queried with the container's Python. The prefix relationship above was found this way. |
| 26 Sep | First fix attempt: reasoning effort lowered to `low` (present in the journal profile's configuration saved that day). The reply then reportedly degraded into one repeated word. *(not confirmed: no such reply is stored in the database)* |
| 26 Sep 18:24 | A normal-looking reply (329 characters). |
| 26 Sep 19:52 | A second long reply (5,355 characters). Whether it was also garbled was not established — confirming it would mean reading private journal content. |
| 26 Sep | Fix: the provider override was removed and the model routed through the platform's default provider with its own key; the result was a clean "no credits" error instead of incoherent text, which confirmed the routing as the cause. *(the error itself is not stored in the database)* |
| after 26 Sep | The archive holds 17 sessions on `upstage/solar-pro4:free` and 1 on `upstage/solar-pro4` (the model without the free suffix). |

## Root cause

The default model came from the hosting template: a free model variant on a third-party inference API. On 26 September that endpoint returned the model's internal reasoning as the answer. Nothing between the endpoint and the user checked the answer, so it was delivered as is.

## Contributing factors

- **No model decision of our own.** The template's default was accepted without evaluation, so a free variant with no service guarantees served a private, everyday function.
- **Untrimmed default toolset.** The agent had far more tools than the journal needed, which made its behaviour harder to reason about (the earlier extra messages).
- **No observability.** No check of answer quality, no daily health check, no spending or credit alerts.
- **Missing diagnostic tooling** in the container (no `sqlite3`), which slowed the investigation.

## What went well

- The cause was found in data, not guessed: comparing the answer and reasoning fields in the sessions database showed the exact mechanism.
- The fix was confirmed by a clear, expected error rather than by "it seems to work".
- The old database and configuration were archived before the rebuild, which made this write-up checkable seven weeks later.

## What went poorly

- The first fix (lower reasoning effort) treated a symptom of the endpoint as a model setting.
- Parts of the original account (the repeated-word reply, the "no credits" error) were never captured and could not be confirmed when this postmortem was written.

## Actions

| Action | Status (17 Nov 2026) |
|---|---|
| Clean rebuild of the agent with a reviewed, minimal toolset | Done (Sprint 2) |
| Model selection with tests on real tasks, cost measured from the sessions database | Done (22 Oct) |
| Toolsets reviewed per channel, including scheduled jobs | Done (28 Oct) |
| Daily self-check run by a script on the host, result in the morning brief | Interim self-check in the brief live; script version planned |
| Spending limits and cost alerts | Backlog |
| Off-server backup with the backup status in the morning brief | Running since 13 Nov |

## Lessons

- **A template's defaults are decisions someone else made.** Review the model, provider and toolset of any template before it handles real data.
- **Compare what the model returned with what the user received.** The sessions database already held both fields; the diagnosis took one comparison once someone looked.
- **Capture evidence during the incident.** Two claims in this timeline could not be confirmed later because nobody saved them at the time.

## How this was verified

On 17 Nov 2026 the archived database was copied to a temporary folder and queried there (the archive itself was not opened, because its write-ahead log held unmerged changes). Queries returned only counts, lengths, timestamps and an answer-is-prefix-of-reasoning flag — no journal content was read. The configuration files were read with lines containing keys masked. The temporary copy was deleted afterwards.
