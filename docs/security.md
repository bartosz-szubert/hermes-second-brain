# Security

How the system is protected, how each control was **verified**, and which gaps were found by testing rather than assumed away. Architecture context: [architecture](architecture.md).

## Threat model in brief

The system holds a private journal, study notes and personal plans, and it reads untrusted content from the web every day. The controls below defend against five things:

1. **Exposed control surfaces** — management panels reachable from the internet.
2. **An agent that can do too much** — a model that is tricked (prompt injection) or simply wrong, with a shell, write access or broad tools.
3. **Leaked or unused credentials** — keys in files, screenshots, history, or keys nobody remembers.
4. **Data loss** — a broken server, a bad update, or an attacker deleting backups.
5. **Private data leaking between areas** — the journal readable from a general-purpose conversation.

## Controls by layer

| Layer | Control | How it was verified |
|---|---|---|
| **Network** | Agent panels bound to localhost; reverse-proxy routes to them disabled; only n8n is public (webhooks), with 2FA and a pinned version | Every published Docker port reviewed; panels reachable only through an SSH tunnel |
| **Server access** | Key-only SSH (ed25519, passphrase); password login disabled, root restricted to keys via a drop-in file read first; fail2ban | Key login tested in a second window before closing the first; a password attempt rejected (`Permission denied (publickey)`); fail2ban log shows a real attacker banned repeatedly, including after a service restart |
| **Agent permissions** | Minimal toolset **per channel** (command line, Telegram, scheduled jobs): no terminal, code execution, browser, external accounts or image generation; scheduled jobs also cannot create further jobs | After each change, a new session and a request to use a removed tool; for scheduled jobs, the brief's own self-check |
| **Agent self-modification** | Approval gates for skill writes, for agent-created skills and for memory writes — all three off by default and absent from the shipped config template | Their existence confirmed in the installed code before enabling; the agent later staged four skills on its own and the gate held all four |
| **Knowledge base** | The agent has no write access to the vault repository: a read-only copy, and a host-side script that commits only batches the author approved and only inside the wiki folder | A write test inside the container failed with `Read-only file system`; a batch touching a file outside the wiki folder was rejected on the live system |
| **Profiles** | Journal and health in their own profiles; a rule in every profile forbids reading the others | A test request to read another profile's files was refused, with no tool calls in the session |
| **Untrusted content** | Web pages, posts and other agents' output are data, never instructions; the agent never joins agent-to-agent networks | A ground rule of the project; the toolset leaves nothing to execute even if an instruction slips through |
| **Credentials** | Keys only in root-only files on the server and in a password manager; never in notes, chat or screenshots; fine-grained, expiring tokens; the GitHub token and the backup key live on the host, never in the agent | A secrets inventory built by printing **names only, never values** (see below) |
| **Accounts** | 2FA on GitHub, the model provider, the pay-as-you-go router, backup storage and n8n; model training on the author's data switched off where the provider allows it | Recovery codes stored only in the password manager |
| **Data at rest and backups** | Nightly restic backup to Backblaze B2 in the EU, encrypted before it leaves the server; the server's storage key has **no delete capability**; files hidden by pruning are kept 30 days | A restored file compared by checksum; a delete attempt with the server's key refused by the storage API (401) — tested on a decoy file, not on real backups |
| **Updates** | OS security patches installed daily, with an automatic night-time reboot when a patch needs one; n8n, Traefik and Hermes on a monthly patch day, release notes read first, versions pinned | After the first update round: kernel and containers checked after the reboot, only ports 22/80/443 public, the effective SSH settings unchanged, n8n reachable from outside and the Traefik dashboard still not exposed |
| **Supply chain** | Every external skill read in full before installation (the built-in scanner is a second line, not a substitute); bundled skills disabled by default and re-enabled one by one; pinned, reviewed copies only | 53 bundled skills found enabled everywhere; several needed a terminal or wrote straight into the vault and stayed off |
| **Publication** | Public and private material in separate repositories from day one; commit identity uses GitHub's private address; files reviewed and scanned before every commit to this repository | Identifiers (host names, container names, IPs, chat and topic ids, locations) searched for in every file before it was added |

## Gaps found by testing

The most useful security work in this project was the tests that proved an assumption wrong.

| Gap | How it was found | Fix |
|---|---|---|
| **Telegram still had a shell.** The toolset review had changed only the command-line channel; Telegram kept the full default set | The agent ran a shell command during an unrelated test | Same tools disabled for Telegram; verified in a new session |
| **Scheduled jobs had their own, full toolset**, including a terminal | The morning brief's own self-check reported terminal access | Risky tools disabled for scheduled jobs in all three profiles |
| **Reads between profiles were open.** Hermes can restrict writes, not reads | Testing whether the default profile could see journal files | Rule in every profile, tested; full isolation options in the backlog |
| **A cloud-init file silently overrode the SSH setting** | Checking the effective configuration, not just the edited file | Dedicated drop-in file read first |
| **An unused but live API key** and a documented "reserve" that did not exist | The secrets inventory | Key deleted; documentation corrected |
| **A dead token left in an old backup copy** | The secrets inventory; status checked by asking the service, without printing the token | Folder with dead secrets removed |

## Secrets inventory

Built in November 2026 with commands that printed only variable and field names: environment files, JSON and YAML configuration, the agent's login file, Docker volumes and the PC's Git credential setup. The private result lists every secret by name, location and purpose, with a verdict on whether it should be split per agent. A checklist for publication came out of it: not only secrets, but host and container names, IP addresses, domains, e-mail addresses, chat and topic ids and private content must never reach a public file.

## Open items

- **Full read isolation between profiles** — options compared; a second agent instance was rejected as too heavy; decision pending.
- **Full restore rehearsal** — restore the whole system on a fresh server from backup, not just a single file.
- **Hermes update** to a pinned current version, with every per-channel toolset, approval gate and profile rule re-checked afterwards (n8n and Traefik are already pinned).
- **n8n editor reachable only through the tunnel** while webhooks stay public.
- **Script-based self-check** with a read-only status folder mounted into the agent.
- **Cost alerts and per-agent spending caps** for any future pay-as-you-go model use.
