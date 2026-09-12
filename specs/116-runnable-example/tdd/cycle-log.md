# Cycle Log

Append only. Newest last. Every entry's `red` block is the evidence that the test existed and failed before the implementation.

## Cycle: A1 (red)

- behavior: A1
- kind: red
- classification: assertionFailure
- subject-hash: f1d6725c1a535c66dfbea2310ad2f7c257f307b79503a0b2f2e778e052203ccb
- criterion: AC-1
- test: test/tdd/116-runnable-example/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a1_test.dart --plain-name "it exits 0 and prints"`
- exit: 1
- at: 2026-09-11T23:19:10.740614Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a1_test.dart                                                                                                    
00:00 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:00 +0 -1: A1 (AC-1) A1 — it exits 0 and prints [E]                                                                                                                                                  
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a1 not implemented>
  
  package:matcher                                  expect
  test/tdd/116-runnable-example/a1_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a1_test.dart -p vm --plain-name 'A1 (AC-1) A1 — it exits 0 and prints'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 4274190d3494999023edba8ea2824335b6bb822e12dc5f9ecd0877a236bc6bbb

## Cycle: A2 (red)

- behavior: A2
- kind: red
- classification: assertionFailure
- subject-hash: 64a87359847bbd789eb804cb330e95b23ac3e2b5517dbbc1d14ce7ab3cf99a00
- criterion: AC-2
- test: test/tdd/116-runnable-example/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a2_test.dart --plain-name "it"`
- exit: 1
- at: 2026-09-11T23:19:13.847893Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a2_test.dart                                                                                                    
00:00 +0: A2 (AC-2) A2 — it                                                                                                                                                                            
00:00 +0 -1: A2 (AC-2) A2 — it [E]                                                                                                                                                                     
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a2 not implemented>
  
  package:matcher                                  expect
  test/tdd/116-runnable-example/a2_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a2_test.dart -p vm --plain-name 'A2 (AC-2) A2 — it'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 59e5574d411f18ec2d3d136be496bf46e0c22eedb769e958253ac8009bd8b495

## Cycle: U1 (red)

- behavior: U1
- kind: red
- classification: assertionFailure
- subject-hash: 98e0e761cab8828aa2c5772abbb9d0aa65e9773d10b9341837b92665d8870341
- criterion: FR-001, MinimalAgent.run
- test: test/tdd/116-runnable-example/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u1_test.dart --plain-name "The example MUST run a full mission through `MissionRunner`"`
- exit: 1
- at: 2026-09-11T23:19:16.951183Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u1_test.dart                                                                                                    
00:00 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:00 +0 -1: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner` [E]                                                                                        
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u1 not implemented: run() -> Future<MissionResult>>
  
  package:matcher                                  expect
  test/tdd/116-runnable-example/u1_test.dart 35:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u1_test.dart -p vm --plain-name 'U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: a9c27f7a0285330594a2b363bb7c2c665c018aec919b5b378120d96bbbd7a4e6

## Cycle: U1 (red)

- behavior: U1
- kind: red
- classification: assertionFailure
- subject-hash: f86abc5393bfec2fb61f9dbc57ca9fc5bd0ad837afc19fde5a616891c2d8e2d2
- criterion: FR-001, MinimalAgent.run
- test: test/tdd/116-runnable-example/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u1_test.dart --plain-name "The example MUST run a full mission through `MissionRunner`"`
- exit: 1
- at: 2026-09-11T23:22:35.070248Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u1_test.dart                                                                                                    
00:00 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:00 +0 -1: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner` [E]                                                                                        
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u1 stub>
  
  package:matcher                                  expect
  test/tdd/116-runnable-example/u1_test.dart 33:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u1_test.dart -p vm --plain-name 'U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: a9c27f7a0285330594a2b363bb7c2c665c018aec919b5b378120d96bbbd7a4e6
- hash: c19c80cf550739e04e1387d7daf1b3a7458c3004cc3236870f0faf50bcfc0019

## Cycle: U2 (red)

- behavior: U2
- kind: red
- classification: assertionFailure
- subject-hash: c383d59b66d82dd60658cc8dc490e39a0a83d6f9d22f97378b8445250ba95b4a
- criterion: FR-002, MinimalAgent.transcript
- test: test/tdd/116-runnable-example/u2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u2_test.dart --plain-name "The example MUST print the mission lifecycle (start,"`
- exit: 1
- at: 2026-09-11T23:22:56.572559Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u2_test.dart                                                                                                    
00:00 +0: U2 (FR-002, MinimalAgent.transcript) U2 — The example MUST print the mission lifecycle (start,                                                                                               
00:00 +0 -1: U2 (FR-002, MinimalAgent.transcript) U2 — The example MUST print the mission lifecycle (start, [E]                                                                                        
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u2 stub>
  
  package:matcher                                  expect
  test/tdd/116-runnable-example/u2_test.dart 34:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u2_test.dart -p vm --plain-name 'U2 (FR-002, MinimalAgent.transcript) U2 — The example MUST print the mission lifecycle (start,'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 0a54032a7794ff7c5958f32b4ed178b620c03628ee410c1c02b9509cef3ca251

## Cycle: U3 (red)

- behavior: U3
- kind: red
- classification: assertionFailure
- subject-hash: b4dd80ab9c7ea394c32536ada581f13673cf1080a76761472efc316c68975593
- criterion: FR-003, MinimalAgent.subprocess
- test: test/tdd/116-runnable-example/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u3_test.dart --plain-name "A test MUST execute the example as a subprocess and assert"`
- exit: 1
- at: 2026-09-11T23:22:58.158586Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u3_test.dart                                                                                                    
00:00 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:00 +0 -1: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert [E]                                                                                  
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u3 stub>
  
  package:matcher                                  expect
  test/tdd/116-runnable-example/u3_test.dart 34:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u3_test.dart -p vm --plain-name 'U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 695447102e25556781f829bc3d731bdf5e4b4d60b60bfa6aea4b37c501257b49

## Cycle: U1 (green)

- behavior: U1
- kind: green
- subject-hash: 996e314dc00a3a91ba0c236bf226c329b090093aee25a9db5175095302c89f09
- criterion: FR-001, MinimalAgent.run
- test: test/tdd/116-runnable-example/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u1_test.dart --plain-name "The example MUST run a full mission through `MissionRunner`"`
- exit: 0
- at: 2026-09-11T23:23:15.479399Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u1_test.dart                                                                                                    
00:00 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:01 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:02 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:03 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:04 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:05 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:06 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:07 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:08 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:09 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:10 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:11 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:12 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:13 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:14 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:15 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:16 +0: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:16 +1: U1 (FR-001, MinimalAgent.run) U1 — The example MUST run a full mission through `MissionRunner`                                                                                               
00:16 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: c19c80cf550739e04e1387d7daf1b3a7458c3004cc3236870f0faf50bcfc0019
- hash: d77f7a5cc830b5098cfcce6f7e8676b7795be571cdf9f2996dc49d588248677b

## Cycle: U2 (green)

- behavior: U2
- kind: green
- subject-hash: cd48d52712ecf6a3daec2ef53f46cf4fb074624f8fe8b32ef753b24268cdec93
- criterion: FR-002, MinimalAgent.transcript
- test: test/tdd/116-runnable-example/u2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u2_test.dart --plain-name "The example MUST print the mission lifecycle (start,"`
- exit: 0
- at: 2026-09-11T23:23:16.861703Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u2_test.dart                                                                                                    
00:00 +0: U2 (FR-002, MinimalAgent.transcript) U2 — The example MUST print the mission lifecycle (start,                                                                                               
00:00 +1: U2 (FR-002, MinimalAgent.transcript) U2 — The example MUST print the mission lifecycle (start,                                                                                               
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 0a54032a7794ff7c5958f32b4ed178b620c03628ee410c1c02b9509cef3ca251
- hash: bcb277c4baf799c805d3f13f7d30d3ffba2b26cb4298c75590788cc86340b116

## Cycle: U3 (green)

- behavior: U3
- kind: green
- evidence: issue #1162 re-certification — the subject was hand-implemented after the certified red; this green evidence binds the NEW subject shape with the passing transcript
- subject-hash: b8966d73991a4ecb30d95eee0e91fae6393ce447b969209ea8c64f2cd24bee78
- criterion: FR-003, MinimalAgent.subprocess
- test: test/tdd/116-runnable-example/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u3_test.dart --plain-name "A test MUST execute the example as a subprocess and assert"`
- exit: 0
- at: 2026-09-11T23:38:28.059810Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u3_test.dart                                                                                                    
00:00 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:01 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:02 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:03 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:04 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:05 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:06 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:07 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:08 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:09 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:10 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:11 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:12 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:13 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:14 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:15 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:16 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:17 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:18 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:19 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:20 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:21 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:22 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:23 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:24 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:25 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:26 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:27 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:28 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:29 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:30 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:31 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:32 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:32 +1: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:32 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 695447102e25556781f829bc3d731bdf5e4b4d60b60bfa6aea4b37c501257b49
- hash: cdb94a1057b4385cf712968b368f4098192258c3364c8bf25aaf8be073baad7d

## Cycle: U3 (green)

- behavior: U3
- kind: green
- subject-hash: b8966d73991a4ecb30d95eee0e91fae6393ce447b969209ea8c64f2cd24bee78
- criterion: FR-003, MinimalAgent.subprocess
- test: test/tdd/116-runnable-example/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u3_test.dart --plain-name "A test MUST execute the example as a subprocess and assert"`
- exit: 0
- at: 2026-09-11T23:39:02.655845Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/u3_test.dart                                                                                                    
00:00 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:01 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:02 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:03 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:04 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:05 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:06 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:07 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:08 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:09 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:10 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:11 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:12 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:13 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:14 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:15 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:16 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:17 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:18 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:19 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:20 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:21 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:22 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:23 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:24 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:25 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:26 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:27 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:28 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:29 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:30 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:31 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:32 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:33 +0: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:33 +1: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                                                                         
00:33 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: cdb94a1057b4385cf712968b368f4098192258c3364c8bf25aaf8be073baad7d
- hash: d77da0b3256c37dd9dbc50f04b3608a03e4d6273428fe8d7f1d148164ff15dd0

## Cycle: contract:A1 (green)

- behavior: contract:A1
- kind: green
- evidence: issue #1411 born-green hand transition — no prior red evidence exists (the hand step preceded the first certification); green certified from the passing target test with the vacuous-guard marker absent and the contract:A1:hand attestation header present
- subject-hash: 70ce5846d1c3fc9f404e247edf8112941b274f9081e49daed7745f70a9b7a54a
- criterion: MinimalAgent.run
- test: test/tdd/116-runnable-example/contract_a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/contract_a1_test.dart --plain-name "MinimalAgent.run() -> Future<MissionResult> (usecase contract)"`
- exit: 0
- at: 2026-09-11T23:41:43.070876Z
- output:
```
issue #1411 born-green hand transition — the designed hand step was completed before the first red certification (hand-first ordering); the passing transcript below is the green evidence bound to the current subject shape.

00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/contract_a1_test.dart                                                                                           
00:01 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/contract_a1_test.dart                                                                                           
00:01 +0: contract:A1 (MinimalAgent.run) contract:A1 — MinimalAgent.run() -> Future<MissionResult> (usecase contract)                                                                                  
00:01 +1: contract:A1 (MinimalAgent.run) contract:A1 — MinimalAgent.run() -> Future<MissionResult> (usecase contract)                                                                                  
00:01 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: genesis
- hash: 9beb1e622b7940fc19ce5a6409ff4233fdeed53ea4d223964daf03999cc3e9e5

## Cycle: contract:A2 (green)

- behavior: contract:A2
- kind: green
- evidence: issue #1411 born-green hand transition — no prior red evidence exists (the hand step preceded the first certification); green certified from the passing target test with the vacuous-guard marker absent and the contract:A2:hand attestation header present
- subject-hash: 73d9055080159547e2075a7b098c45c54973ae32f6d9348db6c715a271da2f30
- criterion: MinimalAgent.transcript
- test: test/tdd/116-runnable-example/contract_a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/contract_a2_test.dart --plain-name "MinimalAgent.transcript(events) -> List<String> (usecase contract)"`
- exit: 0
- at: 2026-09-11T23:41:45.503194Z
- output:
```
issue #1411 born-green hand transition — the designed hand step was completed before the first red certification (hand-first ordering); the passing transcript below is the green evidence bound to the current subject shape.

00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/contract_a2_test.dart                                                                                           
00:01 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/contract_a2_test.dart                                                                                           
00:01 +0: contract:A2 (MinimalAgent.transcript) contract:A2 — MinimalAgent.transcript(events) -> List<String> (usecase contract)                                                                       
00:01 +1: contract:A2 (MinimalAgent.transcript) contract:A2 — MinimalAgent.transcript(events) -> List<String> (usecase contract)                                                                       
00:01 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: genesis
- hash: 366a79ed0bf567b5216a586035faa88bc9348a9341be3b025cdbe6fed3b9d4e2

## Cycle: contract:A3 (green)

- behavior: contract:A3
- kind: green
- evidence: issue #1411 born-green hand transition — no prior red evidence exists (the hand step preceded the first certification); green certified from the passing target test with the vacuous-guard marker absent and the contract:A3:hand attestation header present
- subject-hash: 3b1b3cd97f15b1d14d3391b17d4b1f36bfc363a055b7ca75293d340f68e3aff1
- criterion: MinimalAgent.subprocess
- test: test/tdd/116-runnable-example/contract_a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/contract_a3_test.dart --plain-name "MinimalAgent.subprocess() -> ProcessResult (usecase contract)"`
- exit: 0
- at: 2026-09-11T23:41:46.877636Z
- output:
```
issue #1411 born-green hand transition — the designed hand step was completed before the first red certification (hand-first ordering); the passing transcript below is the green evidence bound to the current subject shape.

00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/contract_a3_test.dart                                                                                           
00:00 +0: contract:A3 (MinimalAgent.subprocess) contract:A3 — MinimalAgent.subprocess() -> ProcessResult (usecase contract)                                                                            
00:00 +1: contract:A3 (MinimalAgent.subprocess) contract:A3 — MinimalAgent.subprocess() -> ProcessResult (usecase contract)                                                                            
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: genesis
- hash: 76bfc74725b7db9b42b09b5a3b13a6e31a9fa01fcc5699025a6a11c5949ad549

## Cycle: A1 (red)

- behavior: A1
- kind: red
- classification: assertionFailure
- subject-hash: 6c0603eee4e977cc6f3e4c1fdd2f3b9f1629d823e3a7b2a8c09c5a5b1593e6ec
- criterion: AC-1
- test: test/tdd/116-runnable-example/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a1_test.dart --plain-name "it exits 0 and prints"`
- exit: 1
- at: 2026-09-11T23:43:42.967604Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a1_test.dart                                                                                                    
00:00 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:00 +0 -1: A1 (AC-1) A1 — it exits 0 and prints [E]                                                                                                                                                  
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a1 stub>
  
  package:matcher                                  expect
  test/tdd/116-runnable-example/a1_test.dart 37:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a1_test.dart -p vm --plain-name 'A1 (AC-1) A1 — it exits 0 and prints'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: 4274190d3494999023edba8ea2824335b6bb822e12dc5f9ecd0877a236bc6bbb
- hash: 456ed2be6d52a8c81f78758a2c88612d9937023242e56e238a663525cf3f3237

## Cycle: A2 (red)

- behavior: A2
- kind: red
- classification: assertionFailure
- subject-hash: 16ebccc86361717f83e453ff53f52b356dc5bc4164c1550147fc062be702f4f9
- criterion: AC-2
- test: test/tdd/116-runnable-example/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a2_test.dart --plain-name "it"`
- exit: 1
- at: 2026-09-11T23:43:44.554982Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a2_test.dart                                                                                                    
00:00 +0: A2 (AC-2) A2 — it                                                                                                                                                                            
00:00 +0 -1: A2 (AC-2) A2 — it [E]                                                                                                                                                                     
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a2 stub>
  
  package:matcher                                  expect
  test/tdd/116-runnable-example/a2_test.dart 36:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a2_test.dart -p vm --plain-name 'A2 (AC-2) A2 — it'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: 59e5574d411f18ec2d3d136be496bf46e0c22eedb769e958253ac8009bd8b495
- hash: cb4562cc9d778995c0e0dab3b370360655eec323f6035513dde15c9b02ab752a

## Cycle: A1 (green)

- behavior: A1
- kind: green
- subject-hash: 2143b17de11cbac480ff1495245fcccf15b7fbb0643e48662c35ec7b8cc2896e
- criterion: AC-1
- test: test/tdd/116-runnable-example/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a1_test.dart --plain-name "it exits 0 and prints"`
- exit: 0
- at: 2026-09-11T23:44:01.436627Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a1_test.dart                                                                                                    
00:00 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:01 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:02 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:03 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:04 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:05 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:06 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:07 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:08 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:09 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:10 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:11 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:12 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:13 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:14 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:15 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:16 +0: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:16 +1: A1 (AC-1) A1 — it exits 0 and prints                                                                                                                                                         
00:16 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 456ed2be6d52a8c81f78758a2c88612d9937023242e56e238a663525cf3f3237
- hash: 67a5071007770aa39a7bfacd4ba9214cf9611e27ebbd6c20bb94e57e1d1956a0

## Cycle: A2 (green)

- behavior: A2
- kind: green
- subject-hash: 54815b8e02ae793b604d7b2f32dcec2a3f38142e5c24f78cdd3da49611fb7f1d
- criterion: AC-2
- test: test/tdd/116-runnable-example/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a2_test.dart --plain-name "it"`
- exit: 0
- at: 2026-09-11T23:44:02.832532Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/116-runnable-example/a2_test.dart                                                                                                    
00:00 +0: A2 (AC-2) A2 — it                                                                                                                                                                            
00:00 +1: A2 (AC-2) A2 — it                                                                                                                                                                            
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: cb4562cc9d778995c0e0dab3b370360655eec323f6035513dde15c9b02ab752a
- hash: 6690327c852fed5dd7c3a9c1ed7983ed180dff1b521fbcb6034b879e3cdc5ff5

## Cycle: 116-runnable-example-refactor (refactor)

- behavior: 116-runnable-example-refactor
- kind: refactor
- criterion: FR-007
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T23:56:17.450476Z
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
01:24 +1357 ~2: test/tdd/116-runnable-example/u3_test.dart: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                       
01:25 +1357 ~2: test/tdd/116-runnable-example/u3_test.dart: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                       
01:26 +1357 ~2: test/tdd/116-runnable-example/u3_test.dart: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                       
01:27 +1357 ~2: test/tdd/116-runnable-example/u3_test.dart: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                       
01:28 +1357 ~2: test/tdd/116-runnable-example/u3_test.dart: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                       
01:29 +1357 ~2: test/tdd/116-runnable-example/u3_test.dart: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                       
01:30 +1357 ~2: test/tdd/116-runnable-example/u3_test.dart: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                       
01:30 +1358 ~2: test/tdd/116-runnable-example/u3_test.dart: U3 (FR-003, MinimalAgent.subprocess) U3 — A test MUST execute the example as a subprocess and assert                                       
01:30 +1358 ~2: 2 skipped tests.                                                                                                                                                                       

01:30 +1358 ~2: All other tests passed!
re-proof: full
receipts refreshed: 9 receipted artifact(s) re-hashed (sanctioned refactor provenance, issue #1311)
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
  changed: lib/tdd/115-agent-platform-packages/contract_a2_subject.dart, lib/tdd/115-agent-platform-packages/contract_a3_subject.dart, lib/tdd/115-agent-platform-packages/contract_a4_subject.dart, lib/tdd/115-agent-platform-packages/contract_a5_subject.dart, lib/tdd/115-agent-platform-packages/contract_a6_subject.dart, lib/tdd/116-runnable-example/a1_subject.dart, lib/tdd/116-runnable-example/contract_a1_subject.dart, lib/tdd/116-runnable-example/u1_subject.dart, lib/tdd/116-runnable-example/u3_subject.dart
- action: fix
  command: `dart fix --apply lib/`
  exit: 0
  changed: (none)

- schema: 1
- prev-hash: genesis
- hash: 9c7d6ef1697898686f96c3fe3a56fe6fd4fe7349b602bbe122405ff13e672336

## Cycle: A1 (refresh)

- behavior: A1
- kind: refresh
- subject-hash: 84941dddb272b60a99b029032901e8d28e0c0423f799e371de3320caabfba7a2
- criterion: AC-1
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T23:56:17.453101Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/a1_subject.dart (hash 2143b17d… → 84941ddd…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 67a5071007770aa39a7bfacd4ba9214cf9611e27ebbd6c20bb94e57e1d1956a0
- hash: 41a0037975f3c6d1c1d1c2ffbec6e8d4b4a2a38f19ef028bbc3ed6ca8dfde6cf

## Cycle: U1 (refresh)

- behavior: U1
- kind: refresh
- subject-hash: ecb620a155269381270379855a5bca1a62a954443173e02c2d9f017868fac726
- criterion: FR-001, MinimalAgent.run
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T23:56:17.455190Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/u1_subject.dart (hash 996e314d… → ecb620a1…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: d77f7a5cc830b5098cfcce6f7e8676b7795be571cdf9f2996dc49d588248677b
- hash: 587b979b7c7a1b7b49acbf7c13e6210ae1f05fc220ecc171f2293423392739ef

## Cycle: U3 (refresh)

- behavior: U3
- kind: refresh
- subject-hash: 8e65c1983a51f7386b976dd81214fef944febdabd9076c2e869269353ca9b2ca
- criterion: FR-003, MinimalAgent.subprocess
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T23:56:17.457344Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/u3_subject.dart (hash b8966d73… → 8e65c198…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: d77da0b3256c37dd9dbc50f04b3608a03e4d6273428fe8d7f1d148164ff15dd0
- hash: 0070047a87ddda35c8d359a099e74865ba304cfaca2642f0a7237e103cc963e0

## Cycle: contract:A1 (refresh)

- behavior: contract:A1
- kind: refresh
- subject-hash: 79f6260f7ec50c5431ee72cbd409c064c5c344f2af2ca8dbc94adc2aa5e1ed9c
- criterion: MinimalAgent.run
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T23:56:17.459525Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/contract_a1_subject.dart (hash 70ce5846… → 79f6260f…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 9beb1e622b7940fc19ce5a6409ff4233fdeed53ea4d223964daf03999cc3e9e5
- hash: 7f135e077f4c85c8682a2e3b0a31eda51e43daafe4badd6b3c0b8567fbf55a52


## Misfire ledger

- Born-green required receipt alignment INCLUDING snapshots (align →
  attest → align → make); refine of zuraffa#1542 follow-up.
- Subprocess tests need explicit timeouts (cold `dart run` compiles
  exceed the 30s default); u1/u3/a1 carry 3-minute timeouts.
- Mutation audit: 7 killed / 6 survived — survivors in subprocess
  wrapper glue (env-dependent internals); production code untouched by
  this feature. Verdict: PASS (spec 111 standard).
