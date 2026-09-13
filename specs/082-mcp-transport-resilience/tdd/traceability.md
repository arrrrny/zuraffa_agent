# Traceability: 082-mcp-transport-resilience

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:d9bf95501fbd679a76a260bb41f7ee38549c7b419698edc7237ba49810542a03
statements: 28
automated: 28
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 123 | - **FR-001**: The system MUST satisfy this requirement: `McpWire` remains a stateless transport seam — `open` / `close` | U1 | automated |
| FR-002 | 127 | - **FR-002**: The system MUST satisfy this requirement: Reconnect backoff is exponential with a hard cap, and with | U2 | automated |
| FR-003 | 130 | - **FR-003**: The system MUST satisfy this requirement: A reconnect storm is bounded: one failure episode schedules at | U3 | automated |
| FR-004 | 136 | - **FR-004**: The system MUST satisfy this requirement: `McpClient` exposes `Stream<void> onReconnected`. SSE and | U4 | automated |
| FR-005 | 141 | - **FR-005**: The system MUST satisfy this requirement: `ToolListingCache` subscribes to | U5 | automated |
| FR-006 | 144 | - **FR-006**: The system MUST satisfy this requirement: Cache freshness is `age < maxAge` — an entry aged exactly | U6 | automated |
| FR-007 | 146 | - **FR-007**: The system MUST satisfy this requirement: Tool calls resolve through `McpToolAdapter` under the | U7 | automated |
| FR-008 | 151 | - **FR-008**: The system MUST satisfy this requirement: Gates — `dart analyze` reports no new issues relative to the | U8 | automated |
| AC-1 | 189 | 1. **Given** the feature implementation under its clean-architecture seams **When** T1: SSE drop mid-call → recovery → onReconnected fires exactly once **Then** the pinned regression test passes (`test/mcp/mcp_082_resilience_test.dart`). | A1 | automated |
| AC-2 | 190 | 2. **Given** the feature implementation under its clean-architecture seams **When** T2: stdio drop mid-call → recovery → onReconnected fires once **Then** the pinned regression test passes (`test/mcp/mcp_082_resilience_test.dart`). | A2 | automated |
| AC-3 | 191 | 3. **Given** the feature implementation under its clean-architecture seams **When** T3: onReconnected invalidates a TTL-fresh cache entry **Then** the pinned regression test passes (`test/mcp/mcp_082_resilience_test.dart`). | A3 | automated |
| AC-4 | 192 | 4. **Given** the feature implementation under its clean-architecture seams **When** T4: end-to-end — drop + recovery → the cache re-lists (SC-002) **Then** the pinned regression test passes (`test/mcp/mcp_082_resilience_test.dart`). | A4 | automated |
| AC-5 | 193 | 5. **Given** the feature implementation under its clean-architecture seams **When** T8: InProcMcpClient.onReconnected never emits **Then** the pinned regression test passes (`test/mcp/mcp_082_resilience_test.dart`). | A5 | automated |
| AC-6 | 194 | 6. **Given** the feature implementation under its clean-architecture seams **When** T5: jittered backoff never exceeds the cap (FR-002) **Then** the pinned regression test passes (`test/mcp/mcp_082_resilience_test.dart`). | A6 | automated |
| AC-7 | 195 | 7. **Given** the feature implementation under its clean-architecture seams **When** T6: storm terminality — bounded delays, failed state, frozen **Then** the pinned regression test passes (`test/mcp/mcp_082_resilience_test.dart`). | A7 | automated |
| AC-8 | 196 | 8. **Given** the feature implementation under its clean-architecture seams **When** T7: TTL boundary — an entry aged exactly maxAge is stale (FR-006) **Then** the pinned regression test passes (`test/mcp/mcp_082_resilience_test.dart`). | A8 | automated |
| AC-9 | 197 | 9. **Given** the feature implementation under its clean-architecture seams **When** sync() lists tools via the cache and registers each into the registry **Then** the pinned regression test passes (`test/mcp/mcp_tool_adapter_test.dart`). | A9 | automated |
| AC-10 | 198 | 10. **Given** the feature implementation under its clean-architecture seams **When** names use the mcp:<serverId>:<toolName> convention **Then** the pinned regression test passes (`test/mcp/mcp_tool_adapter_test.dart`). | A10 | automated |
| AC-11 | 199 | 11. **Given** the feature implementation under its clean-architecture seams **When** a subsequent sync() with new tools registers new and unregisters gone **Then** the pinned regression test passes (`test/mcp/mcp_tool_adapter_test.dart`). | A11 | automated |
| AC-12 | 200 | 12. **Given** the feature implementation under its clean-architecture seams **When** startAutoSync() reacts to onToolsChanged: invalidates cache and re-syncs **Then** the pinned regression test passes (`test/mcp/mcp_tool_adapter_test.dart`). | A12 | automated |
| AC-13 | 201 | 13. **Given** the feature implementation under its clean-architecture seams **When** dispose() stops the auto-sync **Then** the pinned regression test passes (`test/mcp/mcp_tool_adapter_test.dart`). | A13 | automated |
| AC-14 | 202 | 14. **Given** the feature implementation under its clean-architecture seams **When** sync() after dispose throws StateError **Then** the pinned regression test passes (`test/mcp/mcp_tool_adapter_test.dart`). | A14 | automated |
| AC-15 | 203 | 15. **Given** the feature implementation under its clean-architecture seams **When** first call hits the underlying client **Then** the pinned regression test passes (`test/mcp/tool_listing_cache_test.dart`). | A15 | automated |
| AC-16 | 204 | 16. **Given** the feature implementation under its clean-architecture seams **When** second call within TTL returns the cached value (no second listTools) **Then** the pinned regression test passes (`test/mcp/tool_listing_cache_test.dart`). | A16 | automated |
| AC-17 | 205 | 17. **Given** the feature implementation under its clean-architecture seams **When** after TTL expiry, the next call re-lists **Then** the pinned regression test passes (`test/mcp/tool_listing_cache_test.dart`). | A17 | automated |
| AC-18 | 206 | 18. **Given** the feature implementation under its clean-architecture seams **When** explicit invalidate() forces the next call to re-list **Then** the pinned regression test passes (`test/mcp/tool_listing_cache_test.dart`). | A18 | automated |
| AC-19 | 207 | 19. **Given** the feature implementation under its clean-architecture seams **When** onToolsChanged from the client invalidates the cache **Then** the pinned regression test passes (`test/mcp/tool_listing_cache_test.dart`). | A19 | automated |
| AC-20 | 208 | 20. **Given** the feature implementation under its clean-architecture seams **When** dispose() cancels the onToolsChanged subscription **Then** the pinned regression test passes (`test/mcp/tool_listing_cache_test.dart`). | A20 | automated |

