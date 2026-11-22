# Roadmap

## Stage 1 — public (September – November 2026)

**Goal:** a personal agent in daily use, built on a secure, observable base, with the whole build documented in public.

| Area | Delivered | Where |
|---|---|---|
| Secure base | Server hardening, panels off the internet, key-only SSH, least-privilege tokens | [security](security.md) |
| Clean agent | Rebuild from scratch, reviewed toolsets per channel, approval gates | [architecture](architecture.md) |
| Model | Chosen from real-task tests, usage measured from the database | [model selection](model-selection.md) |
| Knowledge base | Obsidian vault in a private repository; agent reads all, writes only approved batches | [knowledge base](knowledge-base.md) |
| Daily agents | Morning brief with self-check, critical-news watch, journal, language tutors | [README](../README.md#what-it-does-every-day) |
| Operations | Nightly encrypted off-site backup with its status in the brief | [`ops/backup`](../ops/backup/) |
| Learning from failure | A blameless postmortem; a missed sprint goal and its retrospective | [postmortem](../POSTMORTEM.md), [project management](project-management.md) |
| Publication | This repository | — |

### Stage 1 exit criteria

Set when Sprint 4 was planned, checked at its review on 20 November. Stage 1 closed on 22 November with four of five criteria met and one carried forward:

| Criterion | Status (22 Nov) |
|---|---|
| Off-site backup running, a restore tested, failures visible in the brief | Met |
| The journal incident written up as a blameless postmortem | Met |
| This repository public, every file reviewed for private data | Met on 22 Nov — two days after Sprint 4, as two Kanban items; every file, screenshot and the whole commit history checked |
| The English tutor used on five days of the sprint, checked in the learning log | Met — seven days |
| The agent observable through a script-based self-check | **Moved to stage 1 follow-ups** at the scope checkpoint; an interim self-check runs in the brief |

## Carried forward from stage 1

Open items, each in the backlog with a Definition of Done, pulled onto the Kanban board roughly in this order — by risk reduced per point of effort:

| # | Item | Why it matters |
|---|---|---|
| 1 | **Security updates for the server and n8n**, with a fixed patching rhythm | Many patches were pending; the server is reachable from the internet |
| 2 | **Self-check run by a script on the host**, result in a read-only folder for the agent | Health checks that do not depend on the agent's own judgement; moved out of Sprint 4 at the scope checkpoint |
| 3 | **Model and cost review** after the first month — including the models released in November | The review plan with decision rules is in [model selection](model-selection.md#review-plan-first-month-of-daily-use) |
| 4 | **Full restore rehearsal** on a fresh server | Only a single-file restore has been tested so far |
| 5 | **Cost alerts and per-agent caps** for any pay-as-you-go use | No automatic model fallback exists yet |
| 6 | **Read isolation between profiles** | Today a tested rule, not a technical boundary |
| 7 | **Pinned container images** and a controlled restart test | Fewer surprises from upstream changes |

## Stage 2 — private

New agents and integrations that touch private areas of life are built in private repositories and tracked in the same Jira project. This repository will still be updated when stage-1 follow-ups land.
