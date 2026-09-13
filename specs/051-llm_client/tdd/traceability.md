# Traceability: 051-llm_client

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:fdfd03fdf59db93569ff75236153640d5e1197d4953c32768b3003d8b022e8b4
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** LlmClient equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** LlmClient inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** LlmClientProvider is a LlmClientService **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** LlmClientProvider.current returns the active LlmClient (no longer stubbed) **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** LlmClientProvider.count returns the number of usable clients **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** forwards ProviderConfig.timeoutMs to the transport completion timeout **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`). | A6 | automated |

