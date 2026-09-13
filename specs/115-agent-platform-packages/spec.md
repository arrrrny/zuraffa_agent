**Template Version**: `zuraffa-1.0`

# Feature Specification: Android/iOS/macOS platform packages — host seams for the agent engine

**Branch**: `115-agent-platform-packages` | **Date**: 2026-09-11

**Status**: Draft

**Input**: session directive — "implement android, macos, ios platform
packages as well". Pattern: the ecosystem's federated layout (see
zuraffa_permissions: platform interface + one package per platform,
Android/iOS/macOS only).

## Summary

The engine is pure Dart; hosts (Flutter apps on Android, iOS, macOS)
need two platform seams: (1) the canonical agent home directory (where
sessions/memory/artifacts live) and (2) a secure key-value store for
provider API keys (Keychain on Apple platforms, Android Keystore on
Android). This spec ships the pure-Dart contract + logic in
`zuraffa_agent` (this package, spec-064 dart:io-free) and a federated
trio of Flutter packages under `packages/` that implement the contract
over a `dev.zuraffa/agent_platform` method channel:

- `packages/zuraffa_agent_platform_interface` — the MethodChannel
  implementation (`ZuraffaAgentMethodChannelPlatform`) implementing the
  engine's `AgentPlatform` interface + a certified channel fake for
  tests.
- `packages/zuraffa_agent_android` — Kotlin plugin: `filesDir` home +
  Android Keystore (AES/GCM) secure store.
- `packages/zuraffa_agent_ios` / `packages/zuraffa_agent_macos` — Swift
  plugins: Application Support home + Keychain secure store; each
  endorses the platform on registration.

**Out of scope**: Windows/Linux/web platforms, biometric-gated access,
sync/backup of the secure store, and desktop signing/entitlement
automation (macOS App Sandbox entitlement documented only).

## Files

- `lib/src/platform/agent_platform.dart` — NEW (pure Dart): the
  `AgentPlatform` interface + `PlatformAgentPlatform` static instance.
- `lib/src/platform/agent_home_resolver.dart` — NEW (pure Dart): composes
  home + `sessions`/`memory`/`artifacts` subdirectories, validates and
  normalizes.
- `lib/src/platform/secure_store.dart` — NEW (pure Dart): key validation
  + `SecureStoreException` mapping.
- `packages/zuraffa_agent_platform_interface/` — NEW Flutter package:
  MethodChannel implementation + `AgentPlatformFake` (test fake).
- `packages/zuraffa_agent_android/` — NEW: Kotlin plugin
  (`dev.zuraffa.zuraffa_agent_android`).
- `packages/zuraffa_agent_ios/`, `packages/zuraffa_agent_macos/` — NEW:
  Swift plugins (`ZuraffaAgentPlugin`).
- `test/tdd/115-agent-platform-packages/` — gen'd behavior tests
  (engine-side, pure Dart).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — A host resolves the agent home per platform (Priority: P1)

A Flutter app asks the engine where to put sessions; the engine returns
per-platform directories composed from the platform-provided home.

**Why this priority**: every persisted artifact depends on the home
resolution being right.

**Independent Test**: feed a fake platform home through the resolver;
assert the three subdirectory paths and validation errors.

**Acceptance Scenarios**:

1. **Given** a platform that reports home `/support`, **When** the
   **Type**: acceptance
   resolver composes the agent layout, **Then** sessions/memory/artifacts
   resolve to `/support/sessions`, `/support/memory`,
   `/support/artifacts` (separator-normalized).
2. **Given** a platform that reports an empty home, **When** the resolver
   **Type**: acceptance
   composes, **Then** it throws `StateError` naming the failure — never a
   silent relative path.

### User Story 2 — API keys live in host secure storage (Priority: P1)

A host stores the provider API key through the `AgentPlatform` secure
store; the value round-trips and can be deleted, with engine-side key
validation refusing bad keys before any channel call.

**Why this priority**: secrets in plaintext files would defeat the
platform seam's purpose.

**Independent Test**: with a fake secure store, write/read/delete a key;
attempt an empty key and assert `ArgumentError` without a channel call.

**Acceptance Scenarios**:

3. **Given** a fake secure store, **When** a key is written then read,
   **Type**: acceptance
   **Then** the same value returns; after delete, the read returns null.
4. **Given** an empty or whitespace key, **When** a secure operation is
   **Type**: acceptance
   attempted, **Then** an `ArgumentError` names the key requirement and
   the channel is never invoked.

### User Story 3 — The federated packages bridge to real hosts (Priority: P2)

The four packages exist with correct pubspecs/plugin declarations;
`registerWith` on each platform package endorses the MethodChannel
implementation; the channel decodes all four methods with the agreed
names and argument shapes (verified through a certified channel fake).

**Why this priority**: the bridge must be structurally right and its
Dart side proven even though native sides need on-device runs.

**Independent Test**: assert package/pubspec structure; run the
interface package's channel fake test under `flutter test` and record
the transcript.

**Acceptance Scenarios**:

5. **Given** the repo tree, **When** the four packages are inspected,
   **Type**: acceptance
   **Then** each declares `zuraffa_agent` + the platform interface as
   dependencies, the three platform packages declare their plugin
   classes for their single platform, and no platform declares another
   platform's folder.
6. **Given** a certified channel fake replaying host responses, **When**
   **Type**: acceptance
   `getAgentHome`, `secureRead`, `secureWrite`, and `secureDelete` run,
   **Then** the channel method names and argument maps match the
   documented contract exactly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `AgentPlatform` MUST define the host seam —
  `getAgentHome()`, `secureRead(key)`, `secureWrite(key, value)`,
  `secureDelete(key)` — as a pure-Dart interface with a mutable static
  `instance` (default: a stub that throws `UnimplementedError` naming
  the missing host binding).
  traces: AgentPlatform.getAgentHome
- **FR-002**: `AgentHomeResolver` MUST compose
  `<home>/sessions|memory|artifacts` with normalized separators and MUST
  refuse an empty/whitespace home with a `StateError`.
  traces: AgentHomeResolver.compose
- **FR-003**: Secure-store operations MUST validate keys (non-empty,
  trimmed, no NUL) with `ArgumentError` BEFORE any platform call, and
  MUST map platform rejections to `SecureStoreException` naming the key
  and operation.
  traces: SecureStore.validate
- **FR-004**: The federated packages MUST ship with correct pubspec
  metadata and plugin declarations (android package
  `dev.zuraffa.zuraffa_agent_android`; ios/macos podspec
  `ZuraffaAgentPlugin`), each depending on `zuraffa_agent` and the
  platform interface package, and each endorsed so registration
  replaces `AgentPlatform.instance`.
  traces: FederatedBridge.structure
- **FR-005**: The channel contract MUST be exactly: channel
  `dev.zuraffa/agent_platform`; methods `getAgentHome`,
  `secureRead`, `secureWrite`, `secureDelete`; arguments
  `{key}` / `{key, value}`; null returns are legal for reads and mean
  "absent".
  traces: FederatedBridge.channel

### Non-Functional Requirements

- NFR-001: The engine package stays pure Dart — no Flutter dependency
  crosses into `lib/` (spec 064 discipline); the Flutter dependency
  lives only under `packages/`.

## Layer Contracts

**Domain**:

- `AgentPlatform`: `getAgentHome() -> Future<String?>`, `secureRead(key) -> Future<String?>`, `secureWrite(key, value) -> Future<void>`, `secureDelete(key) -> Future<void>`
- `AgentHomeResolver`: `compose(home) -> AgentHomeLayout`
- `SecureStore`: `validate(key) -> void`
- `FederatedBridge`: `structure(packages) -> StructureReport`, `channel(method, args) -> Outcome`

### Key Entities

| Entity | Fields | Purpose |
|--------|--------|---------|
| `AgentHomeLayout` | `sessions: String`, `memory: String`, `artifacts: String` | The three canonical agent directories |
| `SecureStoreException` | `key: String`, `operation: String`, `cause: Object` | A platform rejection mapped to a named engine type |

### External Dependencies & Contracts

| Dependency | Kind | Contract | Priority |
|--------|--------|--------|--------|
| package:flutter/services | SDK (packages/ only) | `MethodChannel` bridge | P1 |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: US1 fixtures pass — resolver composition + empty-home
  refusal (FR-002).
- **SC-002**: US2 fixtures pass — secure round-trip + pre-validation
  (FR-001, FR-003).
- **SC-003**: US3 passes — package structure checks green; channel
  fake transcript recorded via `flutter test` in the interface package
  (FR-004, FR-005).
- **SC-004**: `dart analyze` zero; root `dart test` green; purity gate
  unchanged (no Flutter imports in engine `lib/`).
