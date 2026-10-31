# Security Policy

Security policy, threat model, and vulnerability reporting for
`zuraffa_agent` — the agent engine of the Zuraffa ecosystem (missions,
sessions, tool and MCP orchestration, eval harness, observability).

## Supported versions

| Version | Supported |
|---------|-----------|
| 7.3.x   | yes       |
| < 7.3   | no        |

## Reporting a vulnerability

**Please report through
[GitHub Security Advisories](https://github.com/arrrrny/zuraffa_agent/security/advisories/new)
(private disclosure).** This is the only monitored channel — we deliberately
do not publish a reporting email, so nothing stale or unmonitored can sit in
this file. Ordinary bugs go through the
[issue tracker](https://github.com/arrrrny/zuraffa_agent/issues).

When reporting, include:

- the affected version or commit;
- a minimal reproduction (mission spec, tool declaration, or transport
  config that triggers the issue);
- the threat-model category below it falls under, if you can tell;
- your assessment of impact (what an attacker could reach).

We aim to acknowledge reports within a few business days and will keep you
informed while a fix lands. We practice coordinated disclosure: please give
us a reasonable window (default 90 days) before public disclosure, and we
will credit you in the advisory unless you prefer otherwise. Please do not
open public issues for anything you believe is exploitable.

## Scope

**In scope:** the agent engine and its dispatch path (`MissionRunner`,
`ToolDispatcher` and its decorators, tool registry and `AgentTool`
classification), the MCP clients and transports (`lib/src/mcp/`), session
storage and backup, the LLM provider clients and their transports
(`lib/src/llm/`), artifact handling, and the security surfaces documented
here.

**Out of scope:** the applications you build on top of the engine (their
tool declarations, prompts, and deployment), the LLM vendors' own
infrastructure, and denial-of-service against a deployment's network
stack.

## Threat model

Assets an attacker might reach through the engine: host credentials in the
process environment, host files and network reachable from tools, the
mission transcript (relayed to the model vendor on every turn), and the
integrity of tool execution itself.

Trust boundaries: tool output is **untrusted** (it may be attacker-written
content fetched from the web, a file, or an MCP server); the transcript is
**semi-trusted** (it drives the next model call); MCP servers are
**third parties**; tool execution is **trusted only as far as the
declaration is honest**. The four standing threats:

### T1 — Prompt injection via tool output

Untrusted content returned by a tool (web fetch, file read, MCP result)
joins the transcript as a tool-role message and is relayed to the model on
the next turn. An attacker who controls that content can try to steer the
model into invoking dangerous tools or leaking data.

Mitigations (implemented):

- **Risk-tier gate at dispatch (spec 034, wired in #130).** Tools are
  declared `safe`, `confirm`, or `admin` (`AgentTool.riskTier`). The
  `ApprovalGateToolDispatcher` refuses any `confirm`/`admin` dispatch that
  has no wired `ApprovalCallback`, and consults the human decision before
  the tool runs. Injected instructions therefore cannot reach high-risk
  tools without a human approval event — the gate fails closed, and an
  unknown tier can never silently parse to `safe`
  (`RiskTier.fromString` throws `ArgumentError`).
- **Typed params validation before execution.** A tool's `paramsSchema`
  (JSON Schema) is validated at dispatch; mismatched arguments produce
  typed errors and never reach the tool implementation.
- **Oversized-result policy.** Tool bodies beyond the active threshold are
  rewritten to a summary plus artifact reference, bounding how much
  attacker-controlled text can enter one turn.
- **Loop and repetition guards.** Signature-based repetition tracking
  (spec 002 A9) and the loop safety rails (spec 046) end missions that
  repeat the same call pattern, which is the observable signature of many
  injection loops.

Residual risk: the engine does not semantically classify tool output as
"instruction-like"; a well-crafted injection targeting a *safe* tool can
still run. Layered mitigations (S-2, tool-output redaction — issue #12)
continue to narrow this surface; the approval gate bounds the blast radius.

### T2 — Secret exfiltration

Tools run inside the agent process and can read credential material
(environment, config files). A compromised tool — or an injected
instruction driving a legitimate one — can copy secrets into output that
leaves the host.

Mitigations (implemented):

- **Egress sanitization at the transcript boundary (spec 109, issue
  #118).** `RegexToolResultSanitizer` scrubs credential material out of
  every tool result *before* it joins the transcript — the transcript is
  exactly what the next request relays to the model vendor. Default rules
  cover AWS access key ids, GitHub tokens, JWTs, PEM private-key headers,
  Slack tokens, and Stripe live keys; `SanitizerConfig` adds custom
  patterns and markers. Sanitization is pure and deterministic (same input
  → same output), so it is testable as a unit.
- **Risk-tier gate for egress actions.** Tools that send data off-host
  (mail, network writes) should be declared `confirm` or `admin` and are
  then subject to human approval per dispatch.
- **Typed dispatch errors, never silent fallbacks.** A refused or failed
  dispatch produces a typed failure result — the transcript can relay that
  a tool was refused, but the tool never ran.

Residual risk: in-process tools share the process's secrets by design.
Isolating tool execution is the plugin-sandboxing workstream (M-2, issue
#31); until it lands, operators should run agents with the minimum
credentials the mission needs.

### T3 — MCP server impersonation

MCP tools are bridged into the same single namespace as in-process tools
(`ToolRegistry`). An attacker who controls or impersonates an MCP server
controls the tool descriptions that enter tool-selection prompts and the
results those tools return.

Mitigations (implemented):

- **Explicit, operator-configured transports only.** MCP connections are
  the stdio/SSE transports the operator configures — the engine performs
  no auto-discovery of servers.
- **Registration-time collision rejection.** The registry namespaces
  in-process, generated, and remote-MCP tools into one namespace and
  rejects id collisions at registration, so a server cannot shadow an
  existing tool id.
- **Risk classification applies to MCP tools too.** Bridged tools carry a
  declared `AgentTool.riskTier` and go through the same dispatch gate as
  native tools.
- **Reconnect hygiene.** The tool listing cache is invalidated when a
  transport reconnects, so the tool set acted upon always reflects the
  currently connected server rather than a stale snapshot.
- **Per-server circuit breaking (spec 108).** `McpCallGuard` fails fast
  with typed `circuit-open`/`timeout` call errors instead of hammering a
  misbehaving server — availability hygiene that also bounds what a
  hostile server can make the engine do per unit of time.

Residual risk: there is no cryptographic identity pinning of an MCP
server; the operator's transport configuration is the trust root. Configure
transports only against servers you trust.

### T4 — Model vendor data exposure

Every turn relays the transcript — system, user, and sanitized tool
content — to the configured LLM provider. Whatever enters the transcript
is data the vendor processes.

Mitigations (implemented):

- **Sanitization happens upstream of the vendor boundary.** Credential
  redaction (T2) runs on tool results before they join the transcript, so
  the relayed content is the sanitized content.
- **Large bodies stay in artifacts.** The oversized-result policy stores
  full tool bodies as artifacts and puts only the bounded summary into the
  prompt.
- **Swappable providers and transports.** All provider clients speak over
  a swappable `LlmTransport`; pointing a deployment at a self-hosted
  OpenAI-compatible gateway (vLLM et al.) keeps transcript data inside the
  operator's perimeter.
- **Session compaction** bounds how much retained history is re-sent.

Residual risk: by design, prompt content is visible to the chosen model
vendor. Choose providers and transports according to the data
sensitivity of your missions.

## Risk tiers and the approval gate (spec 034)

| Tier      | Meaning | Dispatch behavior |
|-----------|---------|-------------------|
| `safe`    | read-only / idempotent | dispatches without confirmation |
| `confirm` | destructive or egress-capable (fs writes, sending email) | requires an `ApprovalCallback`; refuses without one |
| `admin`   | operator-only actions | same as `confirm`, plus the admin-grant policy |

`RiskTier.requiresConfirmation` marks the high-risk tiers
(`confirm`, `admin`). Wire the gate around your dispatcher:

```dart
final dispatcher = ApprovalGateToolDispatcher(
  inner: innerDispatcher,
  riskTiers: {'fs.write': RiskTier.confirm, 'cluster.admin': RiskTier.admin},
  approvalCallback: (request) async => askHuman(request),
);
```

Without a callback wired, high-risk dispatch is refused fail-closed; the
library's `defaultApprovalCallback` always denies, so a gate that must
deny by default needs no custom code.

## Related hardening work

- **S-2 — tool-output redaction (issue #12)**: referenced by the threat
  model under T1/T2.
- **M-2 — plugin sandboxing (issue #31)**: the planned isolation of tool
  execution referenced under T2/T3.
