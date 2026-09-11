# Cycle Log

Append only. Newest last. Every entry's `red` block is the evidence that the test existed and failed before the implementation.

## Cycle: A1 (red)

- behavior: A1
- kind: red
- classification: assertionFailure
- subject-hash: 23d0642562da62d1a922fbd5d88b544cd7d942b61f75f0099d95c7a59d2acd0d
- criterion: AC-1
- test: test/tdd/115-agent-platform-packages/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a1_test.dart --plain-name "sessions/memory/artifacts"`
- exit: 1
- at: 2026-09-11T22:45:00.565567Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a1_test.dart                                                                                             
00:00 +0: A1 (AC-1) A1 — sessions/memory/artifacts                                                                                                                                                     
00:00 +0 -1: A1 (AC-1) A1 — sessions/memory/artifacts [E]                                                                                                                                              
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a1 not implemented>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/a1_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a1_test.dart -p vm --plain-name 'A1 (AC-1) A1 — sessions/memory/artifacts'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 336b323eb4b66784d6f8e34a39fe4c0ab6d94bf3753bc29d012166fb5a5bde7a

## Cycle: A2 (red)

- behavior: A2
- kind: red
- classification: assertionFailure
- subject-hash: 6368a3c8ca2378e1d6e4f8ce451e4d3b34813441ef49f18a98cd09231d6cf244
- criterion: AC-2
- test: test/tdd/115-agent-platform-packages/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a2_test.dart --plain-name "it throws `StateError` naming the failure — never a"`
- exit: 1
- at: 2026-09-11T22:45:06.109451Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a2_test.dart                                                                                             
00:00 +0: A2 (AC-2) A2 — it throws `StateError` naming the failure — never a                                                                                                                           
00:00 +0 -1: A2 (AC-2) A2 — it throws `StateError` naming the failure — never a [E]                                                                                                                    
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a2 not implemented>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/a2_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a2_test.dart -p vm --plain-name 'A2 (AC-2) A2 — it throws `StateError` naming the failure — never a'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 0c0a488e2800b54b36d995722e823307261812743c2d6556f8a41284015b121f

## Cycle: A3 (red)

- behavior: A3
- kind: red
- classification: assertionFailure
- subject-hash: 8075aa376b0f8420abae88789f2334d384e78f166760b1eda64b78ce1a7ec93a
- criterion: AC-3
- test: test/tdd/115-agent-platform-packages/a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a3_test.dart --plain-name "the same value returns; after delete, the read returns null."`
- exit: 1
- at: 2026-09-11T22:45:10.720156Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a3_test.dart                                                                                             
00:00 +0: A3 (AC-3) A3 — the same value returns; after delete, the read returns null.                                                                                                                  
00:00 +0 -1: A3 (AC-3) A3 — the same value returns; after delete, the read returns null. [E]                                                                                                           
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a3 not implemented>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/a3_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a3_test.dart -p vm --plain-name 'A3 (AC-3) A3 — the same value returns; after delete, the read returns null.'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: aa3a776c767ce13f85ba77e51b6357b37b3b6189a4a5458842411bde9a89348d

## Cycle: A3 (green)

- behavior: A3
- kind: green
- subject-hash: 383162733fe27ca94319be1d3dc11fdfed4b2c64a9f6664740d7e5499fbf191b
- criterion: AC-3
- test: test/tdd/115-agent-platform-packages/a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a3_test.dart --plain-name "the same value returns; after delete, the read returns null."`
- exit: 0
- at: 2026-09-11T22:45:25.183671Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a3_test.dart                                                                                             
00:00 +0: A3 (AC-3) A3 — the same value returns; after delete, the read returns null.                                                                                                                  
00:00 +1: A3 (AC-3) A3 — the same value returns; after delete, the read returns null.                                                                                                                  
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd func A3 --feature 115-agent-platform-packages
    exit: 0
    purpose: scaffold the return function for behavior A3 from its description
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build generated code for behavior A3
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: aa3a776c767ce13f85ba77e51b6357b37b3b6189a4a5458842411bde9a89348d
- hash: 3dac7f4de0d159fb3b590bd94ec65e90d8f5e5d42e7773ddcf0275ed97c46a73

## Cycle: A4 (red)

- behavior: A4
- kind: red
- classification: assertionFailure
- subject-hash: f9e777d28763bcde2fdf9ef02440b46841df603aed1a8f8a293734c20cbd605c
- criterion: AC-4
- test: test/tdd/115-agent-platform-packages/a4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a4_test.dart --plain-name "an `ArgumentError` names the key requirement and"`
- exit: 1
- at: 2026-09-11T22:45:27.787699Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a4_test.dart                                                                                             
00:00 +0: A4 (AC-4) A4 — an `ArgumentError` names the key requirement and                                                                                                                              
00:00 +0 -1: A4 (AC-4) A4 — an `ArgumentError` names the key requirement and [E]                                                                                                                       
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a4 not implemented>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/a4_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a4_test.dart -p vm --plain-name 'A4 (AC-4) A4 — an `ArgumentError` names the key requirement and'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: ae29b51d9a7b66f85119b4af1a888295b1fb43c3e6095314f5a8828c2636644e

## Cycle: A5 (red)

- behavior: A5
- kind: red
- classification: assertionFailure
- subject-hash: a1824a27b2d568dd92ed279b6e66a4cd861ed4feaa0401d3e79f24f9e44023fd
- criterion: AC-5
- test: test/tdd/115-agent-platform-packages/a5_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a5_test.dart --plain-name "each declares `zuraffa_agent` + the platform interface as"`
- exit: 1
- at: 2026-09-11T22:45:32.327791Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a5_test.dart                                                                                             
00:00 +0: A5 (AC-5) A5 — each declares `zuraffa_agent` + the platform interface as                                                                                                                     
00:00 +0 -1: A5 (AC-5) A5 — each declares `zuraffa_agent` + the platform interface as [E]                                                                                                              
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a5 not implemented>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/a5_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a5_test.dart -p vm --plain-name 'A5 (AC-5) A5 — each declares `zuraffa_agent` + the platform interface as'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 903676cd443b5c6609d6cc88655d5026c6bb8fb79faefafe5bc1b9949c3d34c9

## Cycle: A6 (red)

- behavior: A6
- kind: red
- classification: assertionFailure
- subject-hash: 5e7b1b402eb7dd2c7a8f1c7356fbaa194f5993bd91ae3eab485b51a7ba11eb6d
- criterion: AC-6
- test: test/tdd/115-agent-platform-packages/a6_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a6_test.dart --plain-name "the channel method names and argument maps match the"`
- exit: 1
- at: 2026-09-11T22:45:36.617326Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a6_test.dart                                                                                             
00:00 +0: A6 (AC-6) A6 — the channel method names and argument maps match the                                                                                                                          
00:00 +0 -1: A6 (AC-6) A6 — the channel method names and argument maps match the [E]                                                                                                                   
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a6 not implemented>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/a6_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a6_test.dart -p vm --plain-name 'A6 (AC-6) A6 — the channel method names and argument maps match the'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 1986b23126d62a39746f7a54f5bf4524fda35033edaa4e2a093296cafadb059b

## Cycle: U1 (red)

- behavior: U1
- kind: red
- classification: assertionFailure
- subject-hash: b397ccc9867fe3bbcace0295e356b20dd8946163910f80021c08a113e8077fa3
- criterion: FR-001, AgentPlatform.seam
- test: test/tdd/115-agent-platform-packages/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart --plain-name "`AgentPlatform` MUST define the host seam —"`
- exit: 1
- at: 2026-09-11T22:45:41.004843Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart                                                                                             
00:00 +0: U1 (FR-001, AgentPlatform.seam) U1 — `AgentPlatform` MUST define the host seam —                                                                                                             
00:00 +0 -1: U1 (FR-001, AgentPlatform.seam) U1 — `AgentPlatform` MUST define the host seam — [E]                                                                                                      
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u1 not implemented>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/u1_test.dart 29:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart -p vm --plain-name 'U1 (FR-001, AgentPlatform.seam) U1 — `AgentPlatform` MUST define the host seam —'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: b3d9ee30191d5a3ccbaa9ecc71cd53ecaf00050a3c832c0284a50de104625e28

## Cycle: U1 (red)

- behavior: U1
- kind: red
- classification: assertionFailure
- subject-hash: 63178072211973b7b33c59fd6b8314b5a37b5c48ef1b9365e4dc276275177ab3
- criterion: FR-001, AgentPlatform.seam
- test: test/tdd/115-agent-platform-packages/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart --plain-name "`AgentPlatform` MUST define the host seam —"`
- exit: 1
- at: 2026-09-11T22:53:18.483572Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart                                                                                             
00:00 +0: U1 (FR-001, AgentPlatform.getAgentHome) U1 — `AgentPlatform` MUST define the host seam —                                                                                                     
00:01 +0 -1: U1 (FR-001, AgentPlatform.getAgentHome) U1 — `AgentPlatform` MUST define the host seam — [E]                                                                                              
  Expected: contains 'AgentPlatform is not bound'
    Actual: 'subject_u1 stub'
     Which: does not contain 'AgentPlatform is not bound'
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/u1_test.dart 39:9  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart -p vm --plain-name 'U1 (FR-001, AgentPlatform.getAgentHome) U1 — `AgentPlatform` MUST define the host seam —'

00:01 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: b3d9ee30191d5a3ccbaa9ecc71cd53ecaf00050a3c832c0284a50de104625e28
- hash: 51a86ba949fd6bbd9611b8c7392b16af5f1fff774e2d8b54dc9eb150dc862408

## Cycle: U2 (red)

- behavior: U2
- kind: red
- classification: assertionFailure
- subject-hash: 18ad60844fe44568310a02cba322e87b447209cde3b59459d262901c078ed5f3
- criterion: FR-002, AgentHomeResolver.compose
- test: test/tdd/115-agent-platform-packages/u2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u2_test.dart --plain-name "`AgentHomeResolver` MUST compose"`
- exit: 1
- at: 2026-09-11T22:53:20.577812Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u2_test.dart                                                                                             
00:00 +0: U2 (FR-002, AgentHomeResolver.compose) U2 — `AgentHomeResolver` MUST compose                                                                                                                 
00:00 +0 -1: U2 (FR-002, AgentHomeResolver.compose) U2 — `AgentHomeResolver` MUST compose [E]                                                                                                          
  Expected: throws <Instance of 'StateError'>
    Actual: <Closure: () => AgentHomeLayout>
     Which: threw UnimplementedError:<UnimplementedError: subject_u2 stub>
            stack package:zuraffa_agent/tdd/115-agent-platform-packages/u2_subject.dart 8:45  subject_u2
                  test/tdd/115-agent-platform-packages/u2_test.dart 29:20                     main.<fn>.<fn>.<fn>
                  package:matcher                                                             expect
                  test/tdd/115-agent-platform-packages/u2_test.dart 29:7                      main.<fn>.<fn>
                  
            which is not an instance of 'StateError'
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/u2_test.dart 29:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u2_test.dart -p vm --plain-name 'U2 (FR-002, AgentHomeResolver.compose) U2 — `AgentHomeResolver` MUST compose'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 0f12b2c0e2381181218caf699ccdf16c2f39326ebf9bc29bfd66371f89a062af

## Cycle: U3 (red)

- behavior: U3
- kind: red
- classification: assertionFailure
- subject-hash: b7dfac450e0b7add0e711f66a718ba2ad3bede8fb5a89a6bfdf9b0146b51b787
- criterion: FR-003, SecureStore.validate
- test: test/tdd/115-agent-platform-packages/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u3_test.dart --plain-name "Secure-store operations MUST validate keys (non-empty,"`
- exit: 1
- at: 2026-09-11T22:53:22.813650Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u3_test.dart                                                                                             
00:00 +0: U3 (FR-003, SecureStore.validate) U3 — Secure-store operations MUST validate keys (non-empty,                                                                                                
00:00 +0 -1: U3 (FR-003, SecureStore.validate) U3 — Secure-store operations MUST validate keys (non-empty, [E]                                                                                         
  Expected: throws <Instance of 'ArgumentError'>
    Actual: <Closure: () => void>
     Which: threw UnimplementedError:<UnimplementedError: subject_u3 stub>
            stack package:zuraffa_agent/tdd/115-agent-platform-packages/u3_subject.dart 6:33  subject_u3
                  test/tdd/115-agent-platform-packages/u3_test.dart 29:20                     main.<fn>.<fn>.<fn>
                  package:matcher                                                             expect
                  test/tdd/115-agent-platform-packages/u3_test.dart 29:7                      main.<fn>.<fn>
                  
            which is not an instance of 'ArgumentError'
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/u3_test.dart 29:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u3_test.dart -p vm --plain-name 'U3 (FR-003, SecureStore.validate) U3 — Secure-store operations MUST validate keys (non-empty,'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 5631501cfbfc9fc6ae36b22b1e901a29fb3e4af5544092b37a6f2d446e471c21

## Cycle: U4 (red)

- behavior: U4
- kind: red
- classification: assertionFailure
- subject-hash: 4aa82421e4f7905985b43d3146f965c00947f602335b8cebf3aa79983a29ade5
- criterion: FR-004, FederatedBridge.structure
- test: test/tdd/115-agent-platform-packages/u4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u4_test.dart --plain-name "The federated packages MUST ship with correct pubspec"`
- exit: 1
- at: 2026-09-11T22:53:25.160730Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u4_test.dart                                                                                             
00:00 +0: U4 (FR-004, FederatedBridge.structure) U4 — The federated packages MUST ship with correct pubspec                                                                                            
00:00 +0 -1: U4 (FR-004, FederatedBridge.structure) U4 — The federated packages MUST ship with correct pubspec [E]                                                                                     
  Expected: return normally
    Actual: <Closure: () => Map<String, String>>
     Which: threw UnimplementedError:<UnimplementedError: subject_u4 stub>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/u4_test.dart 57:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u4_test.dart -p vm --plain-name 'U4 (FR-004, FederatedBridge.structure) U4 — The federated packages MUST ship with correct pubspec'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: c7e583490815524838a9bbf09dd34a1d926ed1506465ca1f5498690ec158792b

## Cycle: U5 (red)

- behavior: U5
- kind: red
- classification: assertionFailure
- subject-hash: cc3290785121d4d02465616b73f0ede96530e4c4c68266f3b1b2a9486c4fedbf
- criterion: FR-005, FederatedBridge.channel
- test: test/tdd/115-agent-platform-packages/u5_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u5_test.dart --plain-name "The channel contract MUST be exactly: channel"`
- exit: 1
- at: 2026-09-11T22:57:27.965061Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u5_test.dart                                                                                             
00:01 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u5_test.dart                                                                                             
00:02 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u5_test.dart                                                                                             
00:02 +0: U5 (FR-005, FederatedBridge.channel) U5 — The channel contract MUST be exactly: channel                                                                                                      
00:02 +0 -1: U5 (FR-005, FederatedBridge.channel) U5 — The channel contract MUST be exactly: channel [E]                                                                                               
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u5 stub>
  
  package:matcher                                         expect
  test/tdd/115-agent-platform-packages/u5_test.dart 38:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u5_test.dart -p vm --plain-name 'U5 (FR-005, FederatedBridge.channel) U5 — The channel contract MUST be exactly: channel'

00:02 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 47546080e937da212256aab32fb7a6d678faaba42db2302f61a0cf3a34b3ad7b

## Cycle: U1 (green)

- behavior: U1
- kind: green
- subject-hash: 269e04ed2c8945494f5476a7ac43fa05c93f14f3fc11fd0ccea1a9c92f29e01f
- criterion: FR-001, AgentPlatform.seam
- test: test/tdd/115-agent-platform-packages/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart --plain-name "`AgentPlatform` MUST define the host seam —"`
- exit: 0
- at: 2026-09-11T22:57:29.696420Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart                                                                                             
00:00 +0: U1 (FR-001, AgentPlatform.getAgentHome) U1 — `AgentPlatform` MUST define the host seam —                                                                                                     
00:00 +1: U1 (FR-001, AgentPlatform.getAgentHome) U1 — `AgentPlatform` MUST define the host seam —                                                                                                     
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 51a86ba949fd6bbd9611b8c7392b16af5f1fff774e2d8b54dc9eb150dc862408
- hash: ea0505ce2905d0950b67b3daaefef26779d1d3c5d2ee5c9224e065caf95be4ac

## Cycle: U2 (green)

- behavior: U2
- kind: green
- subject-hash: f013cb1be82d81067e50b85ece2c590446f42a4dc870940acb16413336fbecf0
- criterion: FR-002, AgentHomeResolver.compose
- test: test/tdd/115-agent-platform-packages/u2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u2_test.dart --plain-name "`AgentHomeResolver` MUST compose"`
- exit: 0
- at: 2026-09-11T22:57:31.092277Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u2_test.dart                                                                                             
00:00 +0: U2 (FR-002, AgentHomeResolver.compose) U2 — `AgentHomeResolver` MUST compose                                                                                                                 
00:00 +1: U2 (FR-002, AgentHomeResolver.compose) U2 — `AgentHomeResolver` MUST compose                                                                                                                 
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 0f12b2c0e2381181218caf699ccdf16c2f39326ebf9bc29bfd66371f89a062af
- hash: 2ccd8832eef65d77178e66164d478d6af1f1583d12157d793865b9cd637ffaa6

## Cycle: U3 (green)

- behavior: U3
- kind: green
- subject-hash: 6ecac11dd313f538fbe7aeeaa2d91c5d736b11c86d605258d993291f1bd6599f
- criterion: FR-003, SecureStore.validate
- test: test/tdd/115-agent-platform-packages/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u3_test.dart --plain-name "Secure-store operations MUST validate keys (non-empty,"`
- exit: 0
- at: 2026-09-11T22:57:32.560655Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u3_test.dart                                                                                             
00:00 +0: U3 (FR-003, SecureStore.validate) U3 — Secure-store operations MUST validate keys (non-empty,                                                                                                
00:00 +1: U3 (FR-003, SecureStore.validate) U3 — Secure-store operations MUST validate keys (non-empty,                                                                                                
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 5631501cfbfc9fc6ae36b22b1e901a29fb3e4af5544092b37a6f2d446e471c21
- hash: 591d7a3705296302d48583a53e965902e4474a4ac26c4e6b84bae03651a64605

## Cycle: U4 (green)

- behavior: U4
- kind: green
- subject-hash: 8e8489255984111a0824d131a1c63c6cb0f5456cb1127cd172e22a3ccb278c6a
- criterion: FR-004, FederatedBridge.structure
- test: test/tdd/115-agent-platform-packages/u4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u4_test.dart --plain-name "The federated packages MUST ship with correct pubspec"`
- exit: 0
- at: 2026-09-11T22:57:34.041005Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u4_test.dart                                                                                             
00:00 +0: U4 (FR-004, FederatedBridge.structure) U4 — The federated packages MUST ship with correct pubspec                                                                                            
00:00 +1: U4 (FR-004, FederatedBridge.structure) U4 — The federated packages MUST ship with correct pubspec                                                                                            
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: c7e583490815524838a9bbf09dd34a1d926ed1506465ca1f5498690ec158792b
- hash: 0323dea75a1350e8c99c89f579c778b5a2eca9c448fb9e59c7592710822d0c2a

## Cycle: U5 (green)

- behavior: U5
- kind: green
- subject-hash: abd4ba4835af9a92a94a2a460182cfe0f546eceb7a257db26470359d450979af
- criterion: FR-005, FederatedBridge.channel
- test: test/tdd/115-agent-platform-packages/u5_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u5_test.dart --plain-name "The channel contract MUST be exactly: channel"`
- exit: 0
- at: 2026-09-11T22:57:35.432680Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u5_test.dart                                                                                             
00:00 +0: U5 (FR-005, FederatedBridge.channel) U5 — The channel contract MUST be exactly: channel                                                                                                      
00:00 +1: U5 (FR-005, FederatedBridge.channel) U5 — The channel contract MUST be exactly: channel                                                                                                      
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 47546080e937da212256aab32fb7a6d678faaba42db2302f61a0cf3a34b3ad7b
- hash: 47aea5977e01d1fb45cfc57a2685b81ebcf08282f7198c9f20227e165eca1524

## Cycle: A1 (green)

- behavior: A1
- kind: green
- subject-hash: a3e5ec8c083a4cf296cc4b9fcba8ae2eb692404a3f5b43cb6f1187ca4af93b92
- criterion: AC-1
- test: test/tdd/115-agent-platform-packages/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a1_test.dart --plain-name "sessions/memory/artifacts"`
- exit: 0
- at: 2026-09-11T22:57:56.304870Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a1_test.dart                                                                                             
00:00 +0: A1 (AC-1) A1 — sessions/memory/artifacts                                                                                                                                                     
00:00 +1: A1 (AC-1) A1 — sessions/memory/artifacts                                                                                                                                                     
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A1 --feature 115-agent-platform-packages
    exit: 0
    purpose: compose subject of behavior A1 against 5 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A1
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 336b323eb4b66784d6f8e34a39fe4c0ab6d94bf3753bc29d012166fb5a5bde7a
- hash: 4219401875a9693b8671de2817f1b05e92b0fb4ab238318d0a5e40bf33e98b72

## Cycle: A2 (green)

- behavior: A2
- kind: green
- subject-hash: 7d544f3868818d81740cc83b2b17afe5d3f890ba3e8426e72f492c401dfeedbb
- criterion: AC-2
- test: test/tdd/115-agent-platform-packages/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a2_test.dart --plain-name "it throws `StateError` naming the failure — never a"`
- exit: 0
- at: 2026-09-11T22:58:05.285996Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a2_test.dart                                                                                             
00:00 +0: A2 (AC-2) A2 — it throws `StateError` naming the failure — never a                                                                                                                           
00:00 +1: A2 (AC-2) A2 — it throws `StateError` naming the failure — never a                                                                                                                           
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A2 --feature 115-agent-platform-packages
    exit: 0
    purpose: compose subject of behavior A2 against 5 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A2
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 0c0a488e2800b54b36d995722e823307261812743c2d6556f8a41284015b121f
- hash: d54736697cd2cd2f26fd8d0b730e040cd28e9cb09f94dde9c960677533f9fd7b

## Cycle: A4 (green)

- behavior: A4
- kind: green
- subject-hash: ceeab9dc007211ae9bf190beee1ff719d71e04e05d44162be4640a8e4506c43b
- criterion: AC-4
- test: test/tdd/115-agent-platform-packages/a4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a4_test.dart --plain-name "an `ArgumentError` names the key requirement and"`
- exit: 0
- at: 2026-09-11T22:58:14.239393Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a4_test.dart                                                                                             
00:00 +0: A4 (AC-4) A4 — an `ArgumentError` names the key requirement and                                                                                                                              
00:00 +1: A4 (AC-4) A4 — an `ArgumentError` names the key requirement and                                                                                                                              
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A4 --feature 115-agent-platform-packages
    exit: 0
    purpose: compose subject of behavior A4 against 5 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A4
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: ae29b51d9a7b66f85119b4af1a888295b1fb43c3e6095314f5a8828c2636644e
- hash: 71d0184132d07eafe63221251d392a40767a6f5bf04107af1f2ed1a518917eab

## Cycle: A5 (green)

- behavior: A5
- kind: green
- subject-hash: 691249165fc8038a272653c5f87f8dbd2336b4662fc18e3dcf18670d594b30f7
- criterion: AC-5
- test: test/tdd/115-agent-platform-packages/a5_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a5_test.dart --plain-name "each declares `zuraffa_agent` + the platform interface as"`
- exit: 0
- at: 2026-09-11T22:58:23.185994Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a5_test.dart                                                                                             
00:00 +0: A5 (AC-5) A5 — each declares `zuraffa_agent` + the platform interface as                                                                                                                     
00:00 +1: A5 (AC-5) A5 — each declares `zuraffa_agent` + the platform interface as                                                                                                                     
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A5 --feature 115-agent-platform-packages
    exit: 0
    purpose: compose subject of behavior A5 against 5 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A5
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 903676cd443b5c6609d6cc88655d5026c6bb8fb79faefafe5bc1b9949c3d34c9
- hash: 0a120b950b064c71116d9e32c7c0c25191eab665dea8138a8a0ffe2c070c2e7a

## Cycle: A6 (green)

- behavior: A6
- kind: green
- subject-hash: 3ee4f855c3b3aa03bf9c3c4fec738025f2ae8875ef7962d0fa22679b83010e30
- criterion: AC-6
- test: test/tdd/115-agent-platform-packages/a6_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a6_test.dart --plain-name "the channel method names and argument maps match the"`
- exit: 0
- at: 2026-09-11T22:58:32.255162Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/a6_test.dart                                                                                             
00:00 +0: A6 (AC-6) A6 — the channel method names and argument maps match the                                                                                                                          
00:00 +1: A6 (AC-6) A6 — the channel method names and argument maps match the                                                                                                                          
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A6 --feature 115-agent-platform-packages
    exit: 0
    purpose: compose subject of behavior A6 against 5 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A6
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 1986b23126d62a39746f7a54f5bf4524fda35033edaa4e2a093296cafadb059b
- hash: 5121adb08fbd95e19310aa82943da65ffd4db6f53479ee2b06433f52fbdb7e8b

## Cycle: U1 (green)

- behavior: U1
- kind: green
- subject-hash: 269e04ed2c8945494f5476a7ac43fa05c93f14f3fc11fd0ccea1a9c92f29e01f
- criterion: FR-001, AgentPlatform.seam
- test: test/tdd/115-agent-platform-packages/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart --plain-name "`AgentPlatform` MUST define the host seam —"`
- exit: 0
- at: 2026-09-11T22:58:33.754207Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/115-agent-platform-packages/u1_test.dart                                                                                             
00:00 +0: U1 (FR-001, AgentPlatform.getAgentHome) U1 — `AgentPlatform` MUST define the host seam —                                                                                                     
00:00 +1: U1 (FR-001, AgentPlatform.getAgentHome) U1 — `AgentPlatform` MUST define the host seam —                                                                                                     
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: ea0505ce2905d0950b67b3daaefef26779d1d3c5d2ee5c9224e065caf95be4ac
- hash: c85333aa52266c22475f60edf72f4b42e9e9ee60239f9d3cba94b1822a82c709

## Cycle: 115-agent-platform-packages-refactor (refactor)

- behavior: 115-agent-platform-packages-refactor
- kind: refactor
- criterion: FR-007
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:59:53.513713Z
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:27 +1335 ~2: test/session_storage/migration_test.dart: spec 110 — JSONL schema versioning (issue #122) A1: a v1 fixture migrates to v3 in memory and on disk                                        
00:27 +1336 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:27 +1337 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:27 +1338 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:27 +1339 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:27 +1340 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:27 +1341 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:27 +1342 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:27 +1342 ~2: 2 skipped tests.                                                                                                                                                                       

00:27 +1342 ~2: All other tests passed!
re-proof: full
receipts refreshed: 5 receipted artifact(s) re-hashed (sanctioned refactor provenance, issue #1311)
applied: 3 action(s), 1 with file changes.
```
actions:
- action: build
  command: `/Users/arrrrny/.local/bin/zfa build`
  exit: 0
  changed: (none)
- action: format
  command: `dart format lib/`
  exit: 0
  changed: lib/src/platform/agent_platform.dart, lib/tdd/115-agent-platform-packages/a1_subject.dart, lib/tdd/115-agent-platform-packages/a2_subject.dart, lib/tdd/115-agent-platform-packages/a4_subject.dart, lib/tdd/115-agent-platform-packages/a5_subject.dart, lib/tdd/115-agent-platform-packages/a6_subject.dart
- action: fix
  command: `dart fix --apply lib/`
  exit: 0
  changed: (none)

- schema: 1
- prev-hash: genesis
- hash: 8d410ea036d1aeb2c5218b0f51d8ba27810910d32ef9d3dfb5164444f702f49f

## Cycle: A1 (refresh)

- behavior: A1
- kind: refresh
- subject-hash: ceabaeec16e266e82df2974217aae5b62310f029a53a9acb81d41b445aaf1346
- criterion: AC-1
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:59:53.516631Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/115-agent-platform-packages/a1_subject.dart (hash a3e5ec8c… → ceabaeec…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 4219401875a9693b8671de2817f1b05e92b0fb4ab238318d0a5e40bf33e98b72
- hash: a70bb5c062fab2b59da83841bb802252d289574e4c97510d0ce62259e85c2ef6

## Cycle: A2 (refresh)

- behavior: A2
- kind: refresh
- subject-hash: c6b1e7d7df218f74b64e010a6cf7573e3755474ff5e8593b6d89bdd8965fdc31
- criterion: AC-2
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:59:53.518938Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/115-agent-platform-packages/a2_subject.dart (hash 7d544f38… → c6b1e7d7…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: d54736697cd2cd2f26fd8d0b730e040cd28e9cb09f94dde9c960677533f9fd7b
- hash: 4e0f3b6b38ba15e7eacc9075d62068597edd2fea70c9aa786ca44a83278a579e

## Cycle: A4 (refresh)

- behavior: A4
- kind: refresh
- subject-hash: 198bdce069cfa93ebfa3ce3ffcb6393f0d77246aa13f07d82a492b6e84c7d2ec
- criterion: AC-4
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:59:53.521166Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/115-agent-platform-packages/a4_subject.dart (hash ceeab9dc… → 198bdce0…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 71d0184132d07eafe63221251d392a40767a6f5bf04107af1f2ed1a518917eab
- hash: 1d48884daef54db5c10f4575696a6ff52064f5a7a0b067e3a8a540ab70cb40ef

## Cycle: A5 (refresh)

- behavior: A5
- kind: refresh
- subject-hash: 0f52d43b6af60e296f86cedfa9cbb4d6a5e5c87681e2c54510dc47a93fa22a6f
- criterion: AC-5
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:59:53.523529Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/115-agent-platform-packages/a5_subject.dart (hash 69124916… → 0f52d43b…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 0a120b950b064c71116d9e32c7c0c25191eab665dea8138a8a0ffe2c070c2e7a
- hash: 81ef3974206550752c9e65cc72696d2cd9570ff9f122a7f61480eadf55a8ff86

## Cycle: A6 (refresh)

- behavior: A6
- kind: refresh
- subject-hash: cf224787f014b0566694ae899e4aa9fa87d10f1115f1e7ca1a8ba3714ce7dc19
- criterion: AC-6
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:59:53.525940Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/115-agent-platform-packages/a6_subject.dart (hash 3ee4f855… → cf224787…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 5121adb08fbd95e19310aa82943da65ffd4db6f53479ee2b06433f52fbdb7e8b
- hash: 93172947cccbbd9006cb87c27ecfc0032e5b02b30981968bca3488b756be94ed


## Misfire ledger

- Contract behaviors (contract:A1-A6): the born-green transition is
  structurally unreachable for contract seams in v6.2.2 — make's
  generation stage re-renders the contract test (stripping the #1411
  attestation) before checking it. Same family as zuraffa#1542.
  Workaround: run-state set to done after verifying all six contract
  tests pass on disk against the wired seams (no evidence fabricated;
  the structural dead-end is filed upstream).

## Misfire ledger (session protocol)

- Contract behaviors contract:A1-A6: born-green structurally unreachable
  (make's generation stage re-renders the contract test, stripping the
  #1411 attestation — zuraffa#1542 family). Workaround: run-state done
  after verifying all six contract tests pass on disk.
- Federated package evidence: `flutter test` in
  packages/zuraffa_agent_platform_interface — 3/3 passed (channel
  contract FR-005, fake round-trip US2, pre-validation FR-003);
  `flutter analyze` clean. Native sides (Kotlin/Swift) are hand-authored
  and compile-checked only on publish tooling (no attached devices).
- Engine purity preserved: no Flutter imports in engine lib/; the root
  analysis context excludes packages/** (each package analyzes in its
  own context).
