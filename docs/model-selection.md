# Model selection and cost

## Summary

| | |
|---|---|
| **Decision** | ChatGPT Plus through the official "Sign in with ChatGPT" path: `gpt-5.6-sol` for conversations and judgement-heavy jobs, the lighter `gpt-5.6-luna` for the morning brief and delegated sub-tasks |
| **Why** | Fixed, predictable cost (~80 PLN a month) inside a 100 PLN budget; an officially supported sign-in; quality confirmed on the author's own tasks, not on benchmarks |
| **Evidence** | Real-task tests on a clean install; usage read from the agent's session database (~0.9 M input / 66 k output tokens in six days of heavy testing, no plan-limit error) |
| **Accepted trade-off** | When the plan limit is reached, requests fail — there is no automatic fallback |
| **Review** | After the first month of daily use (backlog item, due late November 2026) |

## How the project got here

| Step | What happened | What it taught |
|---|---|---|
| 1 | The hosting template's default: a **free** model variant through a third-party API | It caused the journal incident — see [POSTMORTEM.md](../POSTMORTEM.md) |
| 2 | Switched to a paid endpoint through a router | Fixed technically, but the account had no credits (HTTP 402), so the agent went silent |
| 3 | The second agent tried free tiers behind an LLM gateway | Free tiers do not fit agents: one capped tokens per minute far below real agent prompts (27–68 k tokens → HTTP 413), another returned "high demand" errors (HTTP 503) |
| 4 | **Options compared on cost, support and data use** (below), then tested on real tasks | — |

## Options compared

Criteria, fixed before comparing: **(1) total monthly cost within 100 PLN, (2) an officially supported way to connect the agent, (3) how the provider treats the data, (4) reliability for an always-on agent, (5) quality on the author's own tasks** — the last one only for options that passed the first four.

| Option | ~Monthly cost | For | Against | Verdict |
|---|---|---|---|---|
| ChatGPT Free (sign-in) | 0 | Free | Very small limits; unclear whether third-party sign-in works on Free; consumer data defaults | Rejected |
| ChatGPT Go + pay-as-you-go | ~30 + ~70 PLN | Cheaper subscription | No confirmation Go works in third-party apps; smaller limits | Rejected (unverified) |
| **ChatGPT Plus** | ~80 PLN | Officially supported sign-in; good quality; predictable cost | Uses most of the budget; no fallback at the limit | **Chosen** |
| Pay-as-you-go router only | ≤100 PLN with a hard cap | Full cost transparency; model per task; API data not used for training by default | Variable cost; needs tuning and monitoring | Planned as a capped reserve — see below |
| Claude via subscription sign-in | — | — | Supported by the agent only on a much more expensive plan | Out of budget |
| Gemini via a student offer | 0 for 12 months | Useful for studying | The agent connects to Gemini only by API key, and the free API tier is too small for agents | Used personally, not for the agent |

**Pay-as-you-go facts checked in the router's official documentation:** a fee on every credit purchase (5.5%, minimum 0.80 USD) plus tax; unused credits may expire after a year; per-key spending caps exist (requests fail with HTTP 402 at the cap); prompts are not stored unless logging is enabled; free models are limited to a few dozen requests a day — too little for an agent.

## Real-task tests

Run on the clean install, with the model that actually answered checked in the session database — an earlier assumption that the light model had run the tests turned out wrong (only one delegated sub-task had).

| Test | `gpt-5.6-sol` (main) | `gpt-5.6-luna` (light) |
|---|---|---|
| Photo of a handwritten Polish study note | One word marked unreadable, the rest correct | Three words marked unreadable (but read one the main model could not); no guessing |
| Journal entry → structured note + one reflective question | Good language and structure; relevant question | Good language and structure; shallower question |
| Dozens of commands from Telegram during configuration | No plan-limit errors | — |

## Usage and cost

- **Measured, not estimated:** about 0.9 M input and 66 k output tokens in six days of heavy testing across all profiles, read from the session database. A daily self-check alone used about 17 k tokens.
- **Same usage through the API** at the official prices of the time: about 15–22 USD a month on the main model, 1–2 USD on the light one — so the subscription is not a bargain at today's volume, but it buys predictability and headroom for growth.
- **Why not the strongest tier:** the plan's rolling five-hour window allows only a handful to a few dozen messages on the top tier, about a hundred on the middle one and hundreds to thousands on the light one. An always-on agent with long prompts belongs on the middle and light tiers.

## What changed after the decision

- **Per-job model choice:** the morning brief runs on the light model; the critical-news check and the journal summaries are pinned to the main model, because they need judgement.
- **The capped reserve was never set up.** The router account was hardened (2FA, privacy settings, a capped key), but the agent was never configured to use it. The secrets inventory in November found the only key unused and it was deleted. A reserve with a cap **per agent** stays in the backlog, together with cost alerts.
- **Other recurring costs** are tracked outside the model budget: the server, a possible paid API for read-only social-media monitoring (to be evaluated in a spike), and the student offer's renewal price (a calendar reminder is set two weeks before it ends).

## Review plan (first month of daily use)

| Measure | Source | Decision rule |
|---|---|---|
| Plan-limit errors | Agent logs | Any recurring error → move more jobs to the light model or add a capped reserve |
| Tokens per job (brief, critical news, journal, tutor) | Session database | A job that dominates usage is the first candidate for the light model |
| Quality problems traced to the model | Postmortem-style notes, journal and brief reviews | A repeated problem on the light model → move that job back to the main model |
| Cost per month vs. the same usage through the API | Session database × official prices | If the API would cost well below the subscription for three months, reconsider pay-as-you-go with a cap |

## In hindsight

- **Measure before choosing, not after.** The first model came with the hosting template and was never chosen at all; the incident it caused was the trigger for doing this properly.
- **Treat a planned safeguard as unfinished until it is tested.** The "capped reserve" stayed in the documentation for a month without ever being used — the secrets inventory caught it.

The decision and its rejected alternatives are also recorded in the [decision log](decisions.md).
