## 7.3.2 - 2026-10-31

Mono-version fleet alignment to 7.3.2: outbound send port lands in zuraffa_intents (shareText/shareFiles behind ShareIntentService); the whole family ships at one version.

## 0.1.1

- Widen the `zuraffa_agent` constraint to `^0.6.0` and
  `zuraffa_agent_platform_interface` to `^0.1.1` so the package resolves
  alongside the 0.6.0 core release. No API changes.

## 0.1.0

- Initial release: the federated iOS implementation of the
  `zuraffa_agent` `AgentPlatform` seam (method-channel port, spec 115).
