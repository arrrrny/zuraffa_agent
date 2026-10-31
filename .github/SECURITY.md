# Security Policy

**Please report vulnerabilities through
[GitHub Security Advisories](https://github.com/arrrrny/zuraffa_agent/security/advisories/new)
(private disclosure)** — this is the only monitored channel. Do not open
public issues for anything you believe is exploitable.

Include: the affected version or commit, a minimal reproduction, and your
assessment of impact. We aim to acknowledge within a few business days and
practice coordinated disclosure (default 90 days before public
disclosure, with credit in the advisory unless you prefer otherwise).

Supported versions: **7.3.x**. Older lines are not supported.

The full threat model — prompt injection via tool output, secret
exfiltration, MCP server impersonation, model vendor data exposure — with
per-threat mitigations and the risk-tier approval gate lives in
[SECURITY.md](../SECURITY.md) at the repository root.
