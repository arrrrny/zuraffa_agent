# Data residency

Last reviewed: 2026-10-31 against zuraffa_agent 7.3.2 (issue #139).
Companion to [PRIVACY.md](../PRIVACY.md), which covers *what* data flows
and *who* is responsible; this document covers *where* it is processed
and how to keep it inside a chosen jurisdiction.

## The one-line model

zuraffa_agent processes data **on the machine that runs your application**
and sends it to exactly two kinds of destinations — the LLM endpoint(s)
you configure and the MCP servers you configure. There is no first-party
destination: no vendor host is hardcoded in `lib/`, every endpoint is an
operator-supplied `baseUrl`.

## Where data lives and is processed

| Data class | Processed on | Rests on | Residency control |
| --- | --- | --- | --- |
| Prompts, message history, tool results, media (base64), memory projections | Your host machine (transit) + the configured LLM vendor | Vendor infrastructure for the abuse-monitoring window (see [PRIVACY.md](../PRIVACY.md)); your local stores afterward | The `baseUrl` you configure — pick the vendor or an in-region/self-hosted gateway |
| MCP tool calls (name + arguments) | Your host machine + the configured MCP server | The MCP server's own infrastructure (yours or a third party's) | Choose MCP servers whose jurisdiction you accept |
| Session trees, memory records, turn/tool/usage records, backups, audit log | Your host machine only | Local disk under the agent home (`sessions/`, `memory/`, `artifacts/`) or any path you pass | Fully yours — per-platform agent home (Application Support on Apple platforms, `filesDir` on Android) or an explicit path |
| API keys | Your host machine (request headers only) | Never persisted by the engine; host-owned secure store if you register one | Fully yours |

Platform note for the federated packages (`packages/zuraffa_agent_*`):
the agent home resolves through `AgentPlatform.getAgentHome()` —
Application Support on iOS/macOS, the app's `filesDir` on Android — so
at-rest data stays in the OS-assigned app sandbox on that device.

## Vendor processing regions

Shipped clients and what their operators document (as of the last review
date — verify before relying, these change):

- **Anthropic** (`AnthropicClient`, `{baseUrl}/messages`): the Commercial
  Terms govern processing and route EEA/UK/Swiss customers under Irish
  law; Anthropic's DPA carries the transfer mechanisms for EU→US
  processing. No region pinning exists at the wire level in this engine.
  <https://www.anthropic.com/legal/commercial-terms>
- **OpenAI / OpenAI-compatible** (`OpenAiCompatibleClient`,
  `{baseUrl}/chat/completions`): OpenAI's API data privacy page documents
  no training on API data by default and up to 30 days of retention for
  abuse monitoring. Regional endpoint options, where offered, are chosen
  via the `baseUrl` you supply.
  <https://openai.com/api-data-privacy/>
- **Google Gemini** (`GeminiClient`,
  `{baseUrl}/models/{model}:generateContent`): the Gemini API Terms state
  that paid-tier logged data "may be stored transiently or cached in any
  country in which Google or its agents maintain facilities" — treat
  Google as multi-region unless Google documents otherwise for your tier.
  <https://ai.google.dev/gemini-api/terms>

The engine performs **no geo-routing of its own**: it speaks to whatever
host the `baseUrl` names, and multi-region vendors may process anywhere
their current terms allow.

## Keeping data in a chosen jurisdiction

1. **Self-hosted / in-region gateway (strongest control).** Point
   `baseUrl` at an OpenAI-compatible gateway you run — vLLM, a proxy, or
   an in-region cloud endpoint. The transcript never leaves your
   perimeter; this is also the threat-model guidance for sensitive
   missions (SECURITY.md T4: "Choose providers and transports according
   to the data sensitivity of your missions").
2. **Vendor DPAs and transfer mechanisms.** Where you use a US-processed
   vendor API for EU/UK users, the lawful path is the vendor's Data
   Processing Addendum with its SCCs / UK addendum. Sign it (or route
   through a reseller who has), record it in your GDPR Article 30
   records, and reflect the transfer in your privacy policy.
3. **Tier selection matters (Gemini).** The unpaid Gemini API tier grants
   Google the right to use submitted content to improve its products; the
   paid tier does not. If data leaving your jurisdiction is unacceptable,
   the unpaid tier is not an option.
4. **Local data is fully yours.** Session, memory, artifact and audit
   stores live where you place them — on-device sandboxes for the
   federated platform packages, server-local paths for headless hosts.
   Cross-border exposure of *stored* data only happens if you copy it
   (backups to cloud storage are your decision and your documentation
   duty).

## Verification duty

Vendor terms and regions change; this page records a point-in-time
review. Update it with any PR that changes the egress surface (new
vendor client, new transport) and re-verify the three links above at
least when the package's minor version bumps. The fastest audit path
remains the purity-gate allowlist (`.github/workflows/pipeline.yml`) —
the only files in `lib/` allowed to open sockets or files.
