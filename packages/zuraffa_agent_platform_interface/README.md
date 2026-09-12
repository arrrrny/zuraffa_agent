# zuraffa_agent_platform_interface

Method-channel implementation of the `zuraffa_agent` `AgentPlatform`
seam (spec 115): bridges the federated platform packages
(`zuraffa_agent_android`, `zuraffa_agent_ios`, `zuraffa_agent_macos`)
to the shared channel contract.

Host apps normally depend on the app-facing `zuraffa_agent` package
and register the federated adapter for their platform — this package
is the shared implementation those adapters ship through.
