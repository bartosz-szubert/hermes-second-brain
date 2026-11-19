# Lessons learned

63 lessons from building and running the system, grouped by theme. Each one came from something that actually happened in this project.

## If you read only seven

Each of these changed how the project is run — the right-hand column is the practice it produced.

| Lesson | What happened | What changed |
|---|---|---|
| **An agent's report about its own actions is a claim, not a fact** | The agent said a failed scheduled task had run and quoted a reply it never gave | A Definition of Done criterion: claims are checked in logs or the session database — [project management](project-management.md#how-the-definition-of-done-grew) |
| **Test the control, not the promise** | The agent described the write rules correctly; the proof was a failed write, a rejected bad batch and an unchanged history | Every security control in [security](security.md) lists *how it was verified* |
| **Settings can be per channel — and scheduled jobs are a channel too** | A toolset review left Telegram, and later the scheduled jobs, with a shell | A deployment checklist for every agent or job, and a table of [gaps found by testing](security.md#gaps-found-by-testing) |
| **History is not a substitute for approval** | Git could revert a bad wiki change, but only after someone noticed and did the work | Approval before every write, enforced outside the agent — [knowledge base](knowledge-base.md#write-mechanism--a-decision-worth-showing) |
| **A sprint goal tied to a habit can fail with every task done** | Seven of eight items done; the goal failed on daily use of one agent | Items must end in a result that is *done*; the habit re-planned as a measurable action — [the sprint that failed](project-management.md#the-sprint-that-failed--and-what-changed) |
| **Write a postmortem from data, and say what the data does not show** | Two remembered events were not in the database | Every timeline entry in the [postmortem](../POSTMORTEM.md) is marked as confirmed or not |
| **A secrets inventory finds more than secrets** | Listing names only surfaced an unused live key, a dead token in a backup and a documented reserve that never existed | A pre-publication checklist that covers identifiers, not only secrets — [security](security.md#secrets-inventory) |

**How lessons are used:** a lesson that repeats or that would have prevented a problem becomes a practice — a Definition of Done criterion, a checklist item or a rule in the agent's persona — and the next retrospective checks whether it worked.

## Security and access

- **Docker templates are not hardened by default.** Check every published port and every reverse-proxy route.
- **Test before you lock yourself out.** Keep the current SSH session open and test key login in a new window before disabling passwords; keep an emergency entrance.
- **`sshd` uses the first value it reads, and drop-in files are read alphabetically.** A provider/cloud-init file set password login on and was read before another file that set it off, so the effective setting differed from what the main file suggested. Always check the *effective* configuration (`sshd -T`), not just the files, and put your own overrides in a file that sorts first.
- **Scan before the first commit.** Anything committed stays in git history even after deletion, so notes were checked for keys and tokens before the first push (a keyword search that lists file names only, so nothing leaks into chat or logs). Matches turned out to be ordinary words in video transcripts and a general-guidelines note.
- **Use the private "noreply" e-mail for commits** and enable the option that blocks pushes exposing the real address.
- **A secrets inventory finds more than secrets.** Listing names only (never values) surfaced an unused but live API key, a dead token kept in a backup, and a documented reserve that did not exist. Check a token's status by asking the service, not by looking at it.
- **Test destructive permissions on a decoy.** The no-delete key was tested by uploading a dedicated file and trying to delete that, not by risking real backup data.
- **Settings can be per channel.** A tool review applied to the command-line platform left the chat platform on its full defaults; check every platform the agent is reached through (`--platform`), and test the effect from that channel (here: ask the agent to run a shell command). Changes took effect only after a restart and a new session. The same happened again with **scheduled jobs**, which had their own full toolset — exposed by the agent's own daily report.
- **Review capabilities one at a time.** Going through every toolset individually (what it does, what it risks, whether it is needed now) produced a smaller, better-justified toolset than accepting either the default or a blanket "disable everything"; one item (delegation) turned from "off" to "on with a cheaper model" only because a question surfaced a setting.
- **Keep secrets off the screen and out of history:** read tokens through a hidden prompt and pipe them straight into the file on the server; verify with a count of matching lines, never by printing the value.
- **SSH tunnels live and die with the SSH session.** A reset connection silently takes the panel tunnels down; reconnect and keep the window open. `scp` over a key with a passphrase asks for the passphrase without a clear prompt — a request for a *password* instead means key auth failed.

## Agents in practice

- **Free model tiers are fine for chat, not for agents.** Agent prompts (system prompt + tool definitions + history) are tens of thousands of tokens; per-minute token caps and capacity errors break them.
- **A first real use finds the gap in the rules.** The agent wrote a book note in the chat and saved it nowhere because the rules only covered wiki pages; three small schema revisions followed (folders, book template, month-only date). Write rules around what the agent will produce, not only around what it will know, and check a new template against the author's existing conventions before the first use.
- **An agent's report about its own actions is a claim, not a fact.** The agent said a scheduled task had run when the scheduler had discarded its result, and it quoted a reply it never gave. Check such reports against the logs or the database.
- **Clone a hardened profile instead of starting blank.** Security settings live in the configuration; a new blank profile silently returns to the defaults.
- **Read a skill against your own setup, not just for safety.** None of the shortlisted skills was dangerous, but four of five assumed a terminal or a direct write path the agent deliberately does not have. Defaults are tuned for a fully privileged agent; a hardened one needs its own list. Treat skills like code you run: read before installing, keep the agent's write access behind an approval gate.
- **Define the agent before its isolation.** Profiles were split by data sensitivity before anyone had defined what those agents would do; isolation has a cost (no shared context), so it should follow the agent's requirements, not precede them.
- **An approval gate turns the agent's initiative into a review queue.** The agent drafted four skills unasked; because every skill write needs approval, they became material to judge — two rejected, two reused — instead of silent changes to its behaviour.
- **Check what the agent can actually see before writing rules around it.** A rule "in topic X always do Y" failed because topic names never reach the model; one direct question found the cause faster than more rewording.
- **Some settings are deliberately out of the agent's reach.** The agent can create scheduled jobs but cannot pin their model — only the owner can, from the command line. Knowing which levers belong to whom avoids fighting the design.
- **Read every proposed memory write in full.** The approval list in chat truncates long entries, and the agent adds conclusions of its own (for example sensitive plans it inferred from the conversation). The full text is in the pending files on the server; reject what you would not want sent to the model provider in every future prompt, then ask for a neutral version. An approval gate protects only if the reviewer sees the whole entry. Also: asking the agent to re-propose an entry that was rejected may come back as a "replace" of text that was never saved, so ask for a fresh "add" instead.
- **An agent that ignores instructions in files is working as intended.** Putting a job's instructions in a file looked tidy, but the agent rightly treated the file as data; trusted instructions belong in a skill or the job prompt.
- **A long-lived chat session can carry a stale date.** The agent dated a conversation by the session start, a day earlier; the reminder built on that log misfired. Check dates in the data, not only in the reply.
- **"Separate profiles" is not "separate files".** Profile isolation covered memory and sessions, not the shared data folder; test the boundary you rely on.

## Design

- **History is not a substitute for approval.** Being able to revert a bad change does not remove the work of finding and reverting it; the gate before the write is the real control. Also, decide which parts of a knowledge base the agent owns and which it may only read before giving it write access.
- **Separate build cost from use cost.** Two options that are almost the same to build can differ a lot in daily use (one approval vs. two per change); a switch between them postpones the choice until there is evidence.
- **Name what each protection layer stops before adding the next one.** In one design session the write mechanism grew from a rule to a script, then pull requests and a two-step approval, and the estimate from 3 to 8 points. Listing each layer next to the concrete risk it removes (writes to the author's notes vs. an unapproved wiki page that git can revert) showed that the later layers protect much less than the first.
- **Check what a token and a plan can actually enforce.** A fine-grained GitHub token cannot be limited to a folder; branch protection (no force push) for private repositories needs a paid plan; GitHub does not notify you about pull requests opened under your own account. Each of these changed the design.
- **Re-read a finished rules document as a reviewer.** A second pass over the schema note found inconsistent change-type names, an unnumbered list that a reply referred to by number, a rule that contradicted the flat layout, and missing basics (read the rules first, language, git pull before writing).

## Verify, don't assume

- **Debug at the data layer.** The decisive evidence for the journal incident was in the database (`content` vs `reasoning_content`), not in logs.
- **Not finding a setting in the docs does not prove it does not exist.** I first concluded that a service had no 2FA after searching documentation and screenshots; it was simply in a place that neither covered. Check the product itself before deciding.
- **Verify provider claims in the official docs before spending money.** Reading the fee, expiry and privacy rules first changed the plan (small top-ups, hard cap, privacy toggles reviewed before the first payment).
- **Read the log, not just the status counters.** fail2ban's `status` counters restart from zero when the service restarts; the log still showed every attempt and ban.
- **Check a pattern at its source, and say when you could not.** The description of the LLM Wiki pattern came from a derivative write-up, so its quotes were flagged as unverified; the approval step turned out to be the project's own addition, not part of the pattern (confirmed against the original gist).
- **Measure usage from the system, not from memory.** The session database showed which model really handled each conversation and how many tokens it used; memory (the author's and the agent's) had it wrong.
- **"ok" on a scheduled job only means the session ended.** Whether the agent did the work shows in the number of tool calls in the sessions database, not in the job status.
- **Read what the skill says it logs before calling an empty log a bug.** The critical-news log is empty on ordinary days by design.
- **A local test layout can be friendlier than the server.** The backup script passed locally and failed on the server because a parent folder was root-only there; reproduce the failing condition in a test before fixing, not just the happy path.
- **Write a postmortem from data, and say what the data does not show.** Two events remembered from the incident were not in the database; marking them as unconfirmed made the document more credible, not less.
- **Test the control, not the promise.** The agent described the write rules correctly, but the proof was a failed write ("Read-only file system"), a hand-made bad batch rejected by the script, and an unchanged commit history.
- **Features that are new or only in a pull request are verified in the installed version**, not assumed from a thread or a video (per-topic profile routing in Hermes is the current example).
- **Verify before writing it down.** Claims from videos/marketing (e.g. "app X now supports Y") are checked against official docs before they enter the backlog or decision log.

## Operations and configuration

- **Copy first, verify, then retire the original** when relocating data: compare file counts and size, open the copy in the application, only then change the old location.
- **Do not hand-copy long encoded text.** Retyping a long base64 block introduced an error; for files, transfer the file itself and compare checksums.
- **A config file written by a tool may contain only changed values.** After `config set`, the config shrank to the non-default entries, so line numbers from the original file no longer applied; search by key instead.
- **A config template is not the full list of settings.** The shipped config file did not mention the skill-approval keys, but the installed code and defaults did; searching the code settled it (and the settings turned out to be off by default).
- **Interactive menus do not always survive `docker exec` over SSH.** The model-selection wizard hung with no output; use the non-interactive subcommands (`config set/get`) instead, and run config commands as the container's own user so file ownership stays intact.
- **Check what runs in the background before wiping.** A scheduled self-check job had been failing every day (model limit), leaving a request dump each time; the wipe removed it, and the job must be rebuilt deliberately.
- **Small VPS, big npm installs → add swap** before installing global Node packages.
- **Containers on different Docker networks** cannot reach each other via `localhost`; join the network and use the service address.
- **Synced folders and git do not mix well;** sync conflicts show up as duplicate or empty files.
- **Never copy a live SQLite database as a plain file.** Use SQLite's backup API (as the nightly backup does), or stop the writer and copy the database together with its `-wal` and `-shm` files — otherwise recent writes are lost or the copy is inconsistent.
- **The app's time zone is not the system's.** The scheduler used the configured zone while the agent's tools read a UTC clock; set the zone for the container itself.
- **YAML has opinions about some words.** `off`, `no` and `yes` unquoted become booleans; a setting written as `off` would have been read as false and silently replaced by the default. Quote such values and verify by reading the parsed config, not the file.

## Planning and delivery

- **Draw the dependency arrow from the output.** A task whose result another task needs to *test* must come first, even if it looks like a sub-part of the later one (the wiki rules had to precede the agent's write access).
- **Estimate as a team, at the right moment.** The AI assistant had been proposing story points on its own (and re-estimated one item three times mid-sprint). In Scrum the developers estimate together during refinement or sprint planning; new backlog items may stay unestimated until then. Since then: Planning Poker style — the author gives his estimate first, the assistant second with its reasoning, so the author's view is not anchored. Mid-sprint re-estimation became a retrospective topic.
- **Don't bend the Definition of Done to close an item.** Close it on what was met and move the rest, visibly and linked, to the items it belongs to.
- **Jira records the commitment when the sprint starts.** Starting a sprint before estimating its items leaves the velocity report with a commitment of zero; estimate first, then start.
- **Read the backlog before planning.** Existing items held earlier decisions that contradicted the new specs (e.g. "never nudge" versus a daily reminder); a full export and a refinement pass before planning surfaced them while they were still cheap to resolve.
- **A sprint goal tied to a habit can fail with every task done.** Seven items were finished, yet the goal failed on daily use of one agent; habits need a measurable action and a visible daily signal.
- **Don't cram scope into a sprint:** new valuable items go in as stretch, with a dependency on the item that unblocks them.
- **Read the Definition of Done before closing a ticket.** Two Sprint 2 items were closed too early and had to be re-opened.
- **Long AI chat sessions lose detail when they are compacted** — keep the plan in Jira and the narrative in the repository's work log, not in the conversation.
