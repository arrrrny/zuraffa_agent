# Traceability: 052-provider_config

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:68c43aed52c9cea11e844893b8ad8a6a81f255f237d0615f466f789dde54b234
statements: 5
automated: 5
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfig equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfig inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfigProvider is a ProviderConfigService **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfigProvider.current returns the active provider config **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfigProvider.count returns the configured provider count **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`). | A5 | automated |

