# zuraffa_agent example — minimal agent

Runs a full mission end-to-end with a scripted in-process LLM client:
**no network, no API key**.

```bash
dart run example/minimal_agent.dart
```

Expected output (abridged):

```
[event] MissionStarted
[event] TurnStarted
[event] TurnCompleted
[event] MissionCompleted
---
mission   : demo-1
status    : completed
turns     : 1
summary   : You asked: What is the zuraffa_agent? ...
```

What this demonstrates:

- `MissionRunner` + `EngineLoopExecutor` — the mission loop.
- `EngineEventBus` — typed event subscription over the sealed union.
- `ToolDispatcher` — the tool seam (hosted empty here).
- The scripted `EchoLlmClient` — the LLM provider seam without network.
