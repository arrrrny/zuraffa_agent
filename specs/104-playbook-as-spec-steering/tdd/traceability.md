# Traceability: 104-playbook-as-spec-steering

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:5ba82dc8adaac67804a9421b32240e458c06472e05a290549f5b6f43dc2a07dd
statements: 20
automated: 20
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 70 | 1. **Given** a valid playbook document, **When** loaded, **Then** the engine | A1 | automated |
| AC-2 | 73 | 2. **Given** a malformed playbook document (missing `id`, blank steering | A2 | automated |
| AC-3 | 99 | 3. **Given** a loaded playbook with steering entries `[s1, s2]`, **When** a | A3 | automated |
| AC-4 | 102 | 4. **Given** a playbook with an empty steering section, **When** a mission | A4 | automated |
| AC-5 | 126 | 5. **Given** a playbook gate of mode `allowlist` with `allowed: [search, | A5 | automated |
| AC-6 | 129 | 6. **Given** a playbook gate of mode `blocklist` with `blocked: [shell]`, | A6 | automated |
| AC-7 | 133 | 7. **Given** a playbook with gate mode `off` (or no tool-gating section), | A7 | automated |
| AC-8 | 157 | 8. **Given** a loaded playbook with `response.language: de`, **When** the | A8 | automated |
| AC-9 | 161 | 9. **Given** a loaded playbook with `response.maxChars: 120`, **When** the | A9 | automated |
| AC-10 | 187 | 10. **Given** the Germany playbook, **When** a mission runs, **Then** its | A10 | automated |
| AC-11 | 190 | 11. **Given** the Japan playbook (same engine code), **When** a mission runs, | A11 | automated |
| AC-12 | 193 | 12. **Given** a third, previously unseen playbook document, **When** loaded | A12 | automated |
| FR-001 | 220 | - **FR-001**: The playbook-as-spec schema MUST comprise identity fields | U1 | automated |
| FR-002 | 228 | - **FR-002**: The engine MUST load a playbook document (YAML source or the | U2 | automated |
| FR-003 | 241 | - **FR-003**: The engine MUST apply a loaded playbook's steering section as | U3 | automated |
| FR-004 | 247 | - **FR-004**: The engine MUST apply a loaded playbook's tool-gating section | U4 | automated |
| FR-005 | 252 | - **FR-005**: The engine MUST apply a loaded playbook's response section: a | U5 | automated |
| FR-006 | 258 | - **FR-006**: Adding a new playbook MUST require no code change — only a | U6 | automated |
| FR-007 | 262 | - **FR-007**: The playbook application MUST compose with the existing | U7 | automated |
| FR-008 | 267 | - **FR-008**: The system MUST satisfy this requirement: (gates): `dart analyze --fatal-infos` exit 0 on the changed | U8 | automated |

