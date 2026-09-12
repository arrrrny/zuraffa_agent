# zuraffa_agent_macos

macOS implementation of the `zuraffa_agent` `AgentPlatform` seam:
Application Support home + Keychain secure store.

Call `registerZuraffaAgentmacOS()` before running agents. macOS hosts
need the App Sandbox Keychain-sharing (or keychain-access) entitlement.
