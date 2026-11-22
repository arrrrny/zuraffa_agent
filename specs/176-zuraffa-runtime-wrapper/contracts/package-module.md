# Contract: PackageModule registration seam

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

`PackageModule` integration is an optional runtime-registration seam, not an
alternative module or agent system (FR-007, plan §7.1).

## Shape (logical)

```dart
/// Optional. Hosts that publish PackageModule tools register them here;
/// hosts that do not simply omit this call.
abstract class ZuraffaAgentModule {
  void register(PackageModuleRegistry registry);
}
```

## Behavior

- Registration only wires the wrapper's runtime + governance + ports into the
  host's module registry; it never creates a second agent loop, message
  format, or session store (FR-007).
- The wrapper's own DI (`setupDependencies(GetIt)`-style, following
  `zuraffa_permissions`) is the primary composition path; `ZuraffaAgentModule`
  is additive and optional.
- No global agent state is introduced (plan §7.1: "Do not copy global agent
  state or add another module system merely because it exists").

## Failure modes

- A host that registers overlapping tools is governed by `GovernancePolicy`;
  the seam does not silently drop either side (edge case in spec).