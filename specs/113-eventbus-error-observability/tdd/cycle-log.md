# Cycle Log

Append only. Newest last. Every entry's `red` block is the evidence that the test existed and failed before the implementation.

## Cycle: A1 (red)

- behavior: A1
- kind: red
- classification: assertionFailure
- subject-hash: 5c816192acca825bdef9ba315bedbaff0f607dbf1571b09ba43d6ed7cec3ad29
- criterion: AC-1
- test: test/tdd/113-eventbus-error-observability/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a1_test.dart --plain-name "the later subscriber still receives the event and a SEVERE"`
- exit: 1
- at: 2026-09-11T21:19:01.125638Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a1_test.dart                                                                                        
00:01 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a1_test.dart                                                                                        
00:02 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a1_test.dart                                                                                        
00:02 +0: A1 (AC-1) A1 — the later subscriber still receives the event and a SEVERE                                                                                                                    
00:02 +0 -1: A1 (AC-1) A1 — the later subscriber still receives the event and a SEVERE [E]                                                                                                             
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a1 not implemented>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/a1_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a1_test.dart -p vm --plain-name 'A1 (AC-1) A1 — the later subscriber still receives the event and a SEVERE'

00:02 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: ba8cd8312b5a72ee8952d3ac0b5afef427f11bac5aaeddd35df1bc774bea6e9f

## Cycle: A2 (red)

- behavior: A2
- kind: red
- classification: assertionFailure
- subject-hash: dc23c1084ec6df6c5b31c48c05ec7504f060fafb5fdcf85754985b0e0c6f6ced
- criterion: AC-2
- test: test/tdd/113-eventbus-error-observability/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a2_test.dart --plain-name "the hook is invoked with the"`
- exit: 1
- at: 2026-09-11T21:19:04.491471Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a2_test.dart                                                                                        
00:00 +0: A2 (AC-2) A2 — the hook is invoked with the                                                                                                                                                  
00:00 +0 -1: A2 (AC-2) A2 — the hook is invoked with the [E]                                                                                                                                           
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a2 not implemented>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/a2_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a2_test.dart -p vm --plain-name 'A2 (AC-2) A2 — the hook is invoked with the'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: b766ed447b0acbbc99ca0bbf03629b293743b3df2d964a0edc39c080bf74e25e

## Cycle: A3 (red)

- behavior: A3
- kind: red
- classification: assertionFailure
- subject-hash: 5be184a25f3c80b2fe412fdcc6ac74f4454220396740aa12339a3b42063877a2
- criterion: AC-3
- test: test/tdd/113-eventbus-error-observability/a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a3_test.dart --plain-name "exactly one"`
- exit: 1
- at: 2026-09-11T21:19:08.041269Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a3_test.dart                                                                                        
00:00 +0: A3 (AC-3) A3 — exactly one                                                                                                                                                                   
00:00 +0 -1: A3 (AC-3) A3 — exactly one [E]                                                                                                                                                            
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a3 not implemented>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/a3_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a3_test.dart -p vm --plain-name 'A3 (AC-3) A3 — exactly one'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 562b84603df894605cab953ae1d603ff3cab4d1fe7c16350a35cfa6e150c45a2

## Cycle: A4 (red)

- behavior: A4
- kind: red
- classification: assertionFailure
- subject-hash: a5c62711b6fcde203693754c7f10db10060c859d4a619c764bcfd64ff500ce5c
- criterion: AC-4
- test: test/tdd/113-eventbus-error-observability/a4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a4_test.dart --plain-name "no NEW `EngineEventSubscriberError` is published (the"`
- exit: 1
- at: 2026-09-11T21:19:11.482024Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a4_test.dart                                                                                        
00:00 +0: A4 (AC-4) A4 — no NEW `EngineEventSubscriberError` is published (the                                                                                                                         
00:00 +0 -1: A4 (AC-4) A4 — no NEW `EngineEventSubscriberError` is published (the [E]                                                                                                                  
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a4 not implemented>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/a4_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a4_test.dart -p vm --plain-name 'A4 (AC-4) A4 — no NEW `EngineEventSubscriberError` is published (the'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: cb5d3615750032a4bb84488488cc3482967ae44a8c3bec2c5c716d24a79431b7

## Cycle: A5 (red)

- behavior: A5
- kind: red
- classification: assertionFailure
- subject-hash: 893f81c1031f06648a149fb5a64edf4699bd9686f73135c715d950058b2cda49
- criterion: AC-5
- test: test/tdd/113-eventbus-error-observability/a5_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart --plain-name "`publish` still returns normally, later"`
- exit: 1
- at: 2026-09-11T21:19:14.932519Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart                                                                                        
00:00 +0: A5 (AC-5) A5 — `publish` still returns normally, later                                                                                                                                       
00:00 +0 -1: A5 (AC-5) A5 — `publish` still returns normally, later [E]                                                                                                                                
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a5 not implemented>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/a5_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart -p vm --plain-name 'A5 (AC-5) A5 — `publish` still returns normally, later'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 4c8bd60f946d55b97d1a2ba6069a5a89adbc4a5ac6d873fc66954b0ea874688b

## Cycle: A5 (green)

- behavior: A5
- kind: green
- subject-hash: 59ecbc19f2b8a6adc474e9687a97047d4badc1e345682a1a558c698e84363797
- criterion: AC-5
- test: test/tdd/113-eventbus-error-observability/a5_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart --plain-name "`publish` still returns normally, later"`
- exit: 0
- at: 2026-09-11T21:19:34.370324Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart                                                                                        
00:00 +0: A5 (AC-5) A5 — `publish` still returns normally, later                                                                                                                                       
00:00 +1: A5 (AC-5) A5 — `publish` still returns normally, later                                                                                                                                       
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd func A5 --feature 113-eventbus-error-observability
    exit: 0
    purpose: scaffold the return function for behavior A5 from its description
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build generated code for behavior A5
- suite: baseline=8 guard=0 new=(none)

- schema: 1
- prev-hash: 4c8bd60f946d55b97d1a2ba6069a5a89adbc4a5ac6d873fc66954b0ea874688b
- hash: 98dfc94a84af53ac15fb1c66b56518d12ec40912ab95a29c8e2988862ecbcf40

## Cycle: U1 (error)

- behavior: U1
- kind: error
- outcome: compile-error
- criterion: FR-001, EngineEventBus.logSubscriberError
- test: test/
- command: `/Users/arrrrny/.local/bin/zfa tdd verify-red U1 --feature 113-eventbus-error-observability --project /Users/arrrrny/Developer/zuraffa_agent`
- exit: 1
- at: 2026-09-11T21:19:36.501941Z
- output:
```
zfa tdd verify-red: behavior U1
   feature: 113-eventbus-error-observability
   test: test/tdd/113-eventbus-error-observability/u1_test.dart
   command: dart test {file} --plain-name "{name}"
   runner exit: 1
   classification: compile-error
verify-red: behavior=U1 classification=compile-error certified=false feature=113-eventbus-error-observability

zfa tdd verify-red: classification compile-error — fix the compile error in the test or its subject, then re-run `zfa tdd verify-red <behavior-id>`
   no evidence written
```

- schema: 1
- prev-hash: genesis
- hash: 75c92c457c016ba6a4b9b685cfcd992429a5c5fad09d7649f3f2e2570680a369

## Cycle: U1 (red)

- behavior: U1
- kind: red
- classification: assertionFailure
- subject-hash: 05f447b972602379c24427459b65c366e50ae3ff6c9fc72a9045d840ff4a36d5
- criterion: FR-001, EngineEventBus.logSubscriberError
- test: test/tdd/113-eventbus-error-observability/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u1_test.dart --plain-name "With no consumer hook installed, the bus MUST route"`
- exit: 1
- at: 2026-09-11T21:20:36.091753Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u1_test.dart                                                                                        
00:00 +0: U1 (FR-001, EngineEventBus.logSubscriberError) U1 — With no consumer hook installed, the bus MUST route                                                                                      
00:00 +0 -1: U1 (FR-001, EngineEventBus.logSubscriberError) U1 — With no consumer hook installed, the bus MUST route [E]                                                                               
  Expected: return normally
    Actual: <Closure: () => void>
     Which: threw UnimplementedError:<UnimplementedError: subject_u1 stub>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/u1_test.dart 35:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u1_test.dart -p vm --plain-name 'U1 (FR-001, EngineEventBus.logSubscriberError) U1 — With no consumer hook installed, the bus MUST route'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: 75c92c457c016ba6a4b9b685cfcd992429a5c5fad09d7649f3f2e2570680a369
- hash: f53bfb700128cdca5ead78923eb1ed2a7557d6581dd8d436dbbce978e8864258

## Cycle: U1 (green)

- behavior: U1
- kind: green
- subject-hash: faf5da25c4d4eb3639c468253e0a33a158c7e2c015678c708e375a28ffac8205
- criterion: FR-001, EngineEventBus.logSubscriberError
- test: test/tdd/113-eventbus-error-observability/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u1_test.dart --plain-name "With no consumer hook installed, the bus MUST route"`
- exit: 0
- at: 2026-09-11T21:20:38.298106Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u1_test.dart                                                                                        
00:00 +0: U1 (FR-001, EngineEventBus.logSubscriberError) U1 — With no consumer hook installed, the bus MUST route                                                                                      
00:00 +1: U1 (FR-001, EngineEventBus.logSubscriberError) U1 — With no consumer hook installed, the bus MUST route                                                                                      
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: f53bfb700128cdca5ead78923eb1ed2a7557d6581dd8d436dbbce978e8864258
- hash: a44a5022fae70f5ae985c0659d722aefefa9f4264e4d4f9f4f7a6f5e7e7863d6

## Cycle: A1 (green)

- behavior: A1
- kind: green
- subject-hash: edda1855ed2e17a0969a021c4f2b8768af0dc94a98c71fc5b5a9b11e5e216ad3
- criterion: AC-1
- test: test/tdd/113-eventbus-error-observability/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a1_test.dart --plain-name "the later subscriber still receives the event and a SEVERE"`
- exit: 0
- at: 2026-09-11T21:20:57.612066Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a1_test.dart                                                                                        
00:00 +0: A1 (AC-1) A1 — the later subscriber still receives the event and a SEVERE                                                                                                                    
00:00 +1: A1 (AC-1) A1 — the later subscriber still receives the event and a SEVERE                                                                                                                    
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A1 --feature 113-eventbus-error-observability
    exit: 0
    purpose: compose subject of behavior A1 against 1 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A1
- suite: baseline=8 guard=0 new=(none)

- schema: 1
- prev-hash: ba8cd8312b5a72ee8952d3ac0b5afef427f11bac5aaeddd35df1bc774bea6e9f
- hash: c7f55d3c16d1c55b0b07fe27cb5f4dd5160c85edd3baa2acbad938c3a108bc59

## Cycle: A2 (green)

- behavior: A2
- kind: green
- subject-hash: 593c0b6b2aa3278151ac6b53775984077bad02aee1f9a81dfe767067bec20c68
- criterion: AC-2
- test: test/tdd/113-eventbus-error-observability/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a2_test.dart --plain-name "the hook is invoked with the"`
- exit: 0
- at: 2026-09-11T21:21:07.730184Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a2_test.dart                                                                                        
00:00 +0: A2 (AC-2) A2 — the hook is invoked with the                                                                                                                                                  
00:00 +1: A2 (AC-2) A2 — the hook is invoked with the                                                                                                                                                  
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A2 --feature 113-eventbus-error-observability
    exit: 0
    purpose: compose subject of behavior A2 against 1 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A2
- suite: baseline=8 guard=0 new=(none)

- schema: 1
- prev-hash: b766ed447b0acbbc99ca0bbf03629b293743b3df2d964a0edc39c080bf74e25e
- hash: 9a5ad619084c6bc78dfda425ba11893df7120865927ac4da9a1127168228e2b5

## Cycle: A3 (green)

- behavior: A3
- kind: green
- subject-hash: d031172592cadc65b3af85d9deb9fb7132818974724327caa9b75c6ade612681
- criterion: AC-3
- test: test/tdd/113-eventbus-error-observability/a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a3_test.dart --plain-name "exactly one"`
- exit: 0
- at: 2026-09-11T21:21:18.241822Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a3_test.dart                                                                                        
00:00 +0: A3 (AC-3) A3 — exactly one                                                                                                                                                                   
00:00 +1: A3 (AC-3) A3 — exactly one                                                                                                                                                                   
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A3 --feature 113-eventbus-error-observability
    exit: 0
    purpose: compose subject of behavior A3 against 1 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A3
- suite: baseline=8 guard=0 new=(none)

- schema: 1
- prev-hash: 562b84603df894605cab953ae1d603ff3cab4d1fe7c16350a35cfa6e150c45a2
- hash: 3c15ff146af6ca0493c79d4cb3f7b0dfa31c8c5f74e32d87dcf122254ea070a2

## Cycle: A4 (green)

- behavior: A4
- kind: green
- subject-hash: 45276a055c95ded122ebe48572e612168d24ed2d1c62927fe6544ec29e090abd
- criterion: AC-4
- test: test/tdd/113-eventbus-error-observability/a4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a4_test.dart --plain-name "no NEW `EngineEventSubscriberError` is published (the"`
- exit: 0
- at: 2026-09-11T21:21:27.606518Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a4_test.dart                                                                                        
00:00 +0: A4 (AC-4) A4 — no NEW `EngineEventSubscriberError` is published (the                                                                                                                         
00:00 +1: A4 (AC-4) A4 — no NEW `EngineEventSubscriberError` is published (the                                                                                                                         
00:00 +1: All tests passed!
```
- generation:
  - step: /Users/arrrrny/.local/bin/zfa tdd compose A4 --feature 113-eventbus-error-observability
    exit: 0
    purpose: compose subject of behavior A4 against 1 green unit subject(s)
  - step: /Users/arrrrny/.local/bin/zfa build
    exit: 0
    purpose: build composed code for behavior A4
- suite: baseline=8 guard=0 new=(none)

- schema: 1
- prev-hash: cb5d3615750032a4bb84488488cc3482967ae44a8c3bec2c5c716d24a79431b7
- hash: 71960ffabec804100618dc0d7ae174dc9e388aa07217b26446c0ad179ed26765

## Cycle: 113-eventbus-error-observability-refactor (refactor)

- behavior: 113-eventbus-error-observability-refactor
- kind: refactor
- criterion: FR-007
- test: test/
- command: `dart test "test/tdd/113-eventbus-error-observability/a1_test.dart" "test/tdd/113-eventbus-error-observability/a2_test.dart" "test/tdd/113-eventbus-error-observability/a3_test.dart" "test/tdd/113-eventbus-error-observability/a4_test.dart"`
- exit: 0
- at: 2026-09-11T21:22:24.781985Z
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:02 +0: test/tdd/113-eventbus-error-observability/a1_test.dart: A1 (AC-1) A1 — the later subscriber still receives the event and a SEVERE                                                            
00:02 +1: test/tdd/113-eventbus-error-observability/a2_test.dart: A2 (AC-2) A2 — the hook is invoked with the                                                                                          
00:02 +2: test/tdd/113-eventbus-error-observability/a2_test.dart: A2 (AC-2) A2 — the hook is invoked with the                                                                                          
00:02 +2: loading test/tdd/113-eventbus-error-observability/a3_test.dart                                                                                                                               
00:02 +2: test/tdd/113-eventbus-error-observability/a3_test.dart: A3 (AC-3) A3 — exactly one                                                                                                           
00:02 +3: test/tdd/113-eventbus-error-observability/a3_test.dart: A3 (AC-3) A3 — exactly one                                                                                                           
00:02 +3: loading test/tdd/113-eventbus-error-observability/a4_test.dart                                                                                                                               
00:02 +3: test/tdd/113-eventbus-error-observability/a4_test.dart: A4 (AC-4) A4 — no NEW `EngineEventSubscriberError` is published (the                                                                 
00:02 +4: test/tdd/113-eventbus-error-observability/a4_test.dart: A4 (AC-4) A4 — no NEW `EngineEventSubscriberError` is published (the                                                                 
00:02 +4: All tests passed!
re-proof: scoped (4 covering test(s) for 4 changed file(s); spec 069 T001 — the full gate runs at feature completion + nightly)
receipts refreshed: 4 receipted artifact(s) re-hashed (sanctioned refactor provenance, issue #1311)
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
  changed: lib/tdd/113-eventbus-error-observability/a1_subject.dart, lib/tdd/113-eventbus-error-observability/a2_subject.dart, lib/tdd/113-eventbus-error-observability/a3_subject.dart, lib/tdd/113-eventbus-error-observability/a4_subject.dart
- action: fix
  command: `dart fix --apply lib/`
  exit: 0
  changed: (none)

- schema: 1
- prev-hash: genesis
- hash: 5068e7edab0f0af542d590ab3d2686812fad3680f8591a7b0496d6abac325550

## Cycle: A1 (refresh)

- behavior: A1
- kind: refresh
- subject-hash: e6531e8d11ddfe355a1a67349edb18255504f74da154565fa781269e51b9c114
- criterion: AC-1
- test: test/
- command: `dart test "test/tdd/113-eventbus-error-observability/a1_test.dart" "test/tdd/113-eventbus-error-observability/a2_test.dart" "test/tdd/113-eventbus-error-observability/a3_test.dart" "test/tdd/113-eventbus-error-observability/a4_test.dart"`
- exit: 0
- at: 2026-09-11T21:22:24.783709Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a1_subject.dart (hash edda1855… → e6531e8d…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: c7f55d3c16d1c55b0b07fe27cb5f4dd5160c85edd3baa2acbad938c3a108bc59
- hash: a4cec7ed05f8dfd19f67f9e15e841ebf14a63a8c028fdbdfc3c00226904ae1a3

## Cycle: A2 (refresh)

- behavior: A2
- kind: refresh
- subject-hash: 5ceb2cf848ac841083efb936b7195e58bbf58876bc47d1c2d12f7d0840859ed6
- criterion: AC-2
- test: test/
- command: `dart test "test/tdd/113-eventbus-error-observability/a1_test.dart" "test/tdd/113-eventbus-error-observability/a2_test.dart" "test/tdd/113-eventbus-error-observability/a3_test.dart" "test/tdd/113-eventbus-error-observability/a4_test.dart"`
- exit: 0
- at: 2026-09-11T21:22:24.785097Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a2_subject.dart (hash 593c0b6b… → 5ceb2cf8…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 9a5ad619084c6bc78dfda425ba11893df7120865927ac4da9a1127168228e2b5
- hash: 77799fe3bcf27efa051ed8c032ffea7979b8a49ccdfc3905cf8a88901ed708b0

## Cycle: A3 (refresh)

- behavior: A3
- kind: refresh
- subject-hash: 9f83e505031940a32e9e9d4092c7e7020e0954fa5acaaf32bf68b8a8632f6eee
- criterion: AC-3
- test: test/
- command: `dart test "test/tdd/113-eventbus-error-observability/a1_test.dart" "test/tdd/113-eventbus-error-observability/a2_test.dart" "test/tdd/113-eventbus-error-observability/a3_test.dart" "test/tdd/113-eventbus-error-observability/a4_test.dart"`
- exit: 0
- at: 2026-09-11T21:22:24.787191Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a3_subject.dart (hash d0311725… → 9f83e505…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 3c15ff146af6ca0493c79d4cb3f7b0dfa31c8c5f74e32d87dcf122254ea070a2
- hash: 067ca6256e9794121507e3b44f97b06d6b27ebea05cd83976c0ed111a3b0bd25

## Cycle: A4 (refresh)

- behavior: A4
- kind: refresh
- subject-hash: 280495be559de52bd81217da149bef6da927cb60b53dc10efd2a8b3e047fd651
- criterion: AC-4
- test: test/
- command: `dart test "test/tdd/113-eventbus-error-observability/a1_test.dart" "test/tdd/113-eventbus-error-observability/a2_test.dart" "test/tdd/113-eventbus-error-observability/a3_test.dart" "test/tdd/113-eventbus-error-observability/a4_test.dart"`
- exit: 0
- at: 2026-09-11T21:22:24.788751Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a4_subject.dart (hash 45276a05… → 280495be…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 71960ffabec804100618dc0d7ae174dc9e388aa07217b26446c0ad179ed26765
- hash: 79b5776f742d34824adbd8fd28cf79ce0aaddc612739e08226695818fde883d0

## Cycle: 113-eventbus-error-observability-refactor (refactor)

- behavior: 113-eventbus-error-observability-refactor
- kind: refactor
- criterion: FR-008
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T21:23:51.898360Z
- no-op: true
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:29 +1308 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1309 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1310 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1311 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1312 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1313 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1314 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1315 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1315 ~2: 2 skipped tests.                                                                                                                                                                       

00:29 +1315 ~2: All other tests passed!
re-proof: full
applied: 0 actions.
```

- schema: 1
- prev-hash: 5068e7edab0f0af542d590ab3d2686812fad3680f8591a7b0496d6abac325550
- hash: a02dec82d8cf4e0897e7105fd5f73766e2003032f81edac9cf14b4be64d54481

## Cycle: U2 (error)

- behavior: U2
- kind: error
- outcome: compile-error
- criterion: FR-002, EngineEventBus.logSubscriberError
- test: test/
- command: `/Users/arrrrny/.local/bin/zfa tdd verify-red U2 --feature 113-eventbus-error-observability --project /Users/arrrrny/Developer/zuraffa_agent`
- exit: 1
- at: 2026-09-11T21:23:55.761954Z
- output:
```
zfa tdd verify-red: behavior U2
   feature: 113-eventbus-error-observability
   test: test/tdd/113-eventbus-error-observability/u2_test.dart
   command: dart test {file} --plain-name "{name}"
   runner exit: 1
   classification: compile-error
verify-red: behavior=U2 classification=compile-error certified=false feature=113-eventbus-error-observability

zfa tdd verify-red: classification compile-error — fix the compile error in the test or its subject, then re-run `zfa tdd verify-red <behavior-id>`
   no evidence written
```

- schema: 1
- prev-hash: genesis
- hash: 3af4199a7121628dfbb169ca29cbe9ed84c6f63769507f76cc0b679468ef48f3

## Cycle: U2 (red)

- behavior: U2
- kind: red
- classification: assertionFailure
- subject-hash: e85cd902930cd9dfd01ff19e2208048996c8f2c3e697d00bc11575caf3473da4
- criterion: FR-002, EngineEventBus.logSubscriberError
- test: test/tdd/113-eventbus-error-observability/u2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u2_test.dart --plain-name "A consumer-provided `onSubscriberError` hook MUST fully"`
- exit: 1
- at: 2026-09-11T21:25:12.738931Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u2_test.dart                                                                                        
00:00 +0: U2 (FR-002, EngineEventBus.logSubscriberError) U2 — A consumer-provided `onSubscriberError` hook MUST fully                                                                                  
00:00 +0 -1: U2 (FR-002, EngineEventBus.logSubscriberError) U2 — A consumer-provided `onSubscriberError` hook MUST fully [E]                                                                           
  Expected: return normally
    Actual: <Closure: () => void>
     Which: threw UnimplementedError:<UnimplementedError: subject_u2 stub>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/u2_test.dart 36:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u2_test.dart -p vm --plain-name 'U2 (FR-002, EngineEventBus.logSubscriberError) U2 — A consumer-provided `onSubscriberError` hook MUST fully'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: 3af4199a7121628dfbb169ca29cbe9ed84c6f63769507f76cc0b679468ef48f3
- hash: 1cdb60b43c2f327dfbe99f5e741a53405c19dae558c0bae5104a2cf9a0f9e178

## Cycle: U2 (green)

- behavior: U2
- kind: green
- subject-hash: 4aed7473c84a25f0e52d5d7340174c518b84d81d0278bf3beacb1860ca716cfc
- criterion: FR-002, EngineEventBus.logSubscriberError
- test: test/tdd/113-eventbus-error-observability/u2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u2_test.dart --plain-name "A consumer-provided `onSubscriberError` hook MUST fully"`
- exit: 0
- at: 2026-09-11T21:25:14.234945Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u2_test.dart                                                                                        
00:00 +0: U2 (FR-002, EngineEventBus.logSubscriberError) U2 — A consumer-provided `onSubscriberError` hook MUST fully                                                                                  
00:00 +1: U2 (FR-002, EngineEventBus.logSubscriberError) U2 — A consumer-provided `onSubscriberError` hook MUST fully                                                                                  
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 1cdb60b43c2f327dfbe99f5e741a53405c19dae558c0bae5104a2cf9a0f9e178
- hash: 85896e29265c703c679717596228534f131ab4039613434da0ddde6db1a19d0d

## Cycle: 113-eventbus-error-observability-refactor (refactor)

- behavior: 113-eventbus-error-observability-refactor
- kind: refactor
- criterion: FR-008
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T21:26:52.250933Z
- no-op: true
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:32 +1309 ~2: test/session_storage/migration_test.dart: spec 110 — JSONL schema versioning (issue #122) A1: a v1 fixture migrates to v3 in memory and on disk                                        
00:32 +1310 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:32 +1311 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:32 +1312 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:32 +1313 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:32 +1314 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:32 +1315 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:32 +1316 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:32 +1316 ~2: 2 skipped tests.                                                                                                                                                                       

00:32 +1316 ~2: All other tests passed!
re-proof: full
applied: 0 actions.
```

- schema: 1
- prev-hash: a02dec82d8cf4e0897e7105fd5f73766e2003032f81edac9cf14b4be64d54481
- hash: d6b7932e846bfb015cf3a9bef01e9966cdc9b00f5b333faee0e470f337527a4e

## Cycle: 113-eventbus-error-observability-refactor (refactor)

- behavior: 113-eventbus-error-observability-refactor
- kind: refactor
- criterion: FR-008
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T21:28:18.162709Z
- no-op: true
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:28 +1309 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:28 +1310 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:28 +1311 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:28 +1312 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:28 +1313 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:28 +1314 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:28 +1315 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:28 +1316 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:28 +1316 ~2: 2 skipped tests.                                                                                                                                                                       

00:28 +1316 ~2: All other tests passed!
re-proof: full
applied: 0 actions.
```

- schema: 1
- prev-hash: d6b7932e846bfb015cf3a9bef01e9966cdc9b00f5b333faee0e470f337527a4e
- hash: 284a06e2169fbb861444521a2cc1ab01aed5a0d70d7dba7f3b24d40ff8f23ec7

## Cycle: 113-eventbus-error-observability-refactor (refactor)

- behavior: 113-eventbus-error-observability-refactor
- kind: refactor
- criterion: FR-008
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T21:29:35.056454Z
- no-op: true
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:29 +1309 ~2: test/session_storage/migration_test.dart: spec 110 — JSONL schema versioning (issue #122) A1: a v1 fixture migrates to v3 in memory and on disk                                        
00:29 +1310 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1311 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1312 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1313 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1314 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1315 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1316 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1316 ~2: 2 skipped tests.                                                                                                                                                                       

00:29 +1316 ~2: All other tests passed!
re-proof: full
applied: 0 actions.
```

- schema: 1
- prev-hash: 284a06e2169fbb861444521a2cc1ab01aed5a0d70d7dba7f3b24d40ff8f23ec7
- hash: b9c43ac2ca581c367f005536d7738f35710f12eea8f4e1a30e37bb0db573c027

## Cycle: U3 (red)

- behavior: U3
- kind: red
- classification: assertionFailure
- subject-hash: 91330cc364bcae476e41cb40a4f5b04aa70663d1401b4c90535506624d7f8777
- criterion: FR-003, EngineEventBus.subscriberErrorEvent
- test: test/tdd/113-eventbus-error-observability/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart --plain-name "After the error route runs, the bus MUST publish an"`
- exit: 1
- at: 2026-09-11T21:29:38.851620Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart                                                                                        
00:01 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart                                                                                        
00:02 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart                                                                                        
00:02 +0: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an                                                                                    
00:02 +0 -1: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an [E]                                                                             
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u3 not implemented>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/u3_test.dart 29:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart -p vm --plain-name 'U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an'

00:02 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: ecd753f5d082f92141ea96a6eb904117c34af3b8b04d29ac5ccbc1930a9ac0b8

## Cycle: U3 (green)

- behavior: U3
- kind: green
- subject-hash: 84370233bb55e8a3a80e28acdd8380b9db878e665dbccaa1061aa07be42d5a12
- criterion: FR-003, EngineEventBus.subscriberErrorEvent
- test: test/tdd/113-eventbus-error-observability/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart --plain-name "After the error route runs, the bus MUST publish an"`
- exit: 0
- at: 2026-09-11T21:31:23.445824Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart                                                                                        
00:00 +0: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an                                                                                    
00:00 +1: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an                                                                                    
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: ecd753f5d082f92141ea96a6eb904117c34af3b8b04d29ac5ccbc1930a9ac0b8
- hash: 256db07b6bc4147a27e8582e85168e5e4e19e5aaab3112372cc94bd1c5eacd8f

## Cycle: U3 (red)

- behavior: U3
- kind: red
- classification: assertionFailure
- subject-hash: 585d815d7e57e152e007218e349eab3f121f5167da02c2758e4a5dc9ad5f18c1
- criterion: FR-003, EngineEventBus.subscriberErrorEvent
- test: test/tdd/113-eventbus-error-observability/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart --plain-name "After the error route runs, the bus MUST publish an"`
- exit: 1
- at: 2026-09-11T21:31:41.314738Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart                                                                                        
00:00 +0: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an                                                                                    
00:00 +0 -1: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an [E]                                                                             
  Expected: return normally
    Actual: <Closure: () => EngineEventSubscriberError>
     Which: threw UnimplementedError:<UnimplementedError: subject_u3 stub>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/u3_test.dart 29:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart -p vm --plain-name 'U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: 256db07b6bc4147a27e8582e85168e5e4e19e5aaab3112372cc94bd1c5eacd8f
- hash: 10f6516d4f95036829576f1d1d6aef360d5ef474713399966c98760bb07d9ff4

## Cycle: U3 (green)

- behavior: U3
- kind: green
- subject-hash: 84370233bb55e8a3a80e28acdd8380b9db878e665dbccaa1061aa07be42d5a12
- criterion: FR-003, EngineEventBus.subscriberErrorEvent
- test: test/tdd/113-eventbus-error-observability/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart --plain-name "After the error route runs, the bus MUST publish an"`
- exit: 0
- at: 2026-09-11T21:31:42.894489Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart                                                                                        
00:00 +0: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an                                                                                    
00:00 +1: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an                                                                                    
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 10f6516d4f95036829576f1d1d6aef360d5ef474713399966c98760bb07d9ff4
- hash: c33316b56fcec68769e38f01174d6a55986497545656404ad9a5b7a5dae77065

## Cycle: U3 (green)

- behavior: U3
- kind: green
- subject-hash: 84370233bb55e8a3a80e28acdd8380b9db878e665dbccaa1061aa07be42d5a12
- criterion: FR-003, EngineEventBus.subscriberErrorEvent
- test: test/tdd/113-eventbus-error-observability/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart --plain-name "After the error route runs, the bus MUST publish an"`
- exit: 0
- at: 2026-09-11T21:31:50.341599Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u3_test.dart                                                                                        
00:00 +0: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an                                                                                    
00:00 +1: U3 (FR-003, EngineEventBus.subscriberErrorEvent) U3 — After the error route runs, the bus MUST publish an                                                                                    
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: c33316b56fcec68769e38f01174d6a55986497545656404ad9a5b7a5dae77065
- hash: 816cb93bc2641ace981ae9ec306a7fdf870d65f7582cdef2301546f29c9860b6

## Cycle: 113-eventbus-error-observability-refactor (refactor)

- behavior: 113-eventbus-error-observability-refactor
- kind: refactor
- criterion: FR-008
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T21:33:22.504105Z
- no-op: true
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:29 +1310 ~2: test/session_storage/migration_test.dart: spec 110 — JSONL schema versioning (issue #122) A1: a v1 fixture migrates to v3 in memory and on disk                                        
00:29 +1311 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1312 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1313 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1314 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1315 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1316 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1317 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1317 ~2: 2 skipped tests.                                                                                                                                                                       

00:29 +1317 ~2: All other tests passed!
re-proof: full
applied: 0 actions.
```

- schema: 1
- prev-hash: b9c43ac2ca581c367f005536d7738f35710f12eea8f4e1a30e37bb0db573c027
- hash: 6426d4cb1db5368ec953e6c76d9488f5fc00d06e0287dfbd1f3149c3f8f9fe71

## Cycle: U4 (error)

- behavior: U4
- kind: error
- outcome: compile-error
- criterion: FR-004, EngineEventBus.logSubscriberError
- test: test/
- command: `/Users/arrrrny/.local/bin/zfa tdd verify-red U4 --feature 113-eventbus-error-observability --project /Users/arrrrny/Developer/zuraffa_agent`
- exit: 1
- at: 2026-09-11T21:33:26.299697Z
- output:
```
zfa tdd verify-red: behavior U4
   feature: 113-eventbus-error-observability
   test: test/tdd/113-eventbus-error-observability/u4_test.dart
   command: dart test {file} --plain-name "{name}"
   runner exit: 1
   classification: compile-error
verify-red: behavior=U4 classification=compile-error certified=false feature=113-eventbus-error-observability

zfa tdd verify-red: classification compile-error — fix the compile error in the test or its subject, then re-run `zfa tdd verify-red <behavior-id>`
   no evidence written
```

- schema: 1
- prev-hash: genesis
- hash: a4cbae1801e1d3f4dd14183cadbfd2a461c775bf04f6309fdaff9226d0c2139c

## Cycle: U4 (red)

- behavior: U4
- kind: red
- classification: assertionFailure
- subject-hash: 9c93eb5dfb472318a9574140d8576f48506972712b4d895c9a7e4bcdc5bc332f
- criterion: FR-004, EngineEventBus.logSubscriberError
- test: test/tdd/113-eventbus-error-observability/u4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u4_test.dart --plain-name "A throwing hook or a throwing subscriber of the"`
- exit: 1
- at: 2026-09-11T21:33:55.890519Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u4_test.dart                                                                                        
00:00 +0: U4 (FR-004, EngineEventBus.logSubscriberError) U4 — A throwing hook or a throwing subscriber of the                                                                                          
00:00 +0 -1: U4 (FR-004, EngineEventBus.logSubscriberError) U4 — A throwing hook or a throwing subscriber of the [E]                                                                                   
  Expected: return normally
    Actual: <Closure: () => void>
     Which: threw UnimplementedError:<UnimplementedError: subject_u4 stub>
  
  package:matcher                                              expect
  test/tdd/113-eventbus-error-observability/u4_test.dart 35:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u4_test.dart -p vm --plain-name 'U4 (FR-004, EngineEventBus.logSubscriberError) U4 — A throwing hook or a throwing subscriber of the'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: a4cbae1801e1d3f4dd14183cadbfd2a461c775bf04f6309fdaff9226d0c2139c
- hash: 3f7c34a579bd2dcb65237d906a9d41123861f4dc11b8bc8c6acc3b3f67b70576

## Cycle: U4 (green)

- behavior: U4
- kind: green
- subject-hash: ebdbbc562782f46b5234ec00dfc5abeae651591c510028c02564381dae3c5069
- criterion: FR-004, EngineEventBus.logSubscriberError
- test: test/tdd/113-eventbus-error-observability/u4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u4_test.dart --plain-name "A throwing hook or a throwing subscriber of the"`
- exit: 0
- at: 2026-09-11T21:33:57.377249Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/u4_test.dart                                                                                        
00:00 +0: U4 (FR-004, EngineEventBus.logSubscriberError) U4 — A throwing hook or a throwing subscriber of the                                                                                          
00:00 +1: U4 (FR-004, EngineEventBus.logSubscriberError) U4 — A throwing hook or a throwing subscriber of the                                                                                          
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 3f7c34a579bd2dcb65237d906a9d41123861f4dc11b8bc8c6acc3b3f67b70576
- hash: 2157767cab7d27d3d3b84d8935023852376c1396aed328ffd51ee36bd3c60c1c

## Cycle: contract:A1 (green)

- behavior: contract:A1
- kind: green
- evidence: issue #1411 born-green hand transition — no prior red evidence exists (the hand step preceded the first certification); green certified from the passing target test with the vacuous-guard marker absent and the contract:A1:hand attestation header present
- subject-hash: 280ffec2bcb346f3f18c7dd5966f4f7079c97bb2057dbab7b6926dca8e1943cd
- criterion: EngineEventBus.logSubscriberError
- test: test/tdd/113-eventbus-error-observability/contract_a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/contract_a1_test.dart --plain-name "EngineEventBus.logSubscriberError(error, event) -> void (usecase contract)"`
- exit: 0
- at: 2026-09-11T21:34:26.166586Z
- output:
```
issue #1411 born-green hand transition — the designed hand step was completed before the first red certification (hand-first ordering); the passing transcript below is the green evidence bound to the current subject shape.

00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/contract_a1_test.dart                                                                               
00:00 +0: contract:A1 (EngineEventBus.logSubscriberError) contract:A1 — EngineEventBus.logSubscriberError(error, event) -> void (usecase contract)                                                     
00:00 +1: contract:A1 (EngineEventBus.logSubscriberError) contract:A1 — EngineEventBus.logSubscriberError(error, event) -> void (usecase contract)                                                     
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: genesis
- hash: 49cc478bb94b3aac90288559347b457f5eaabf41bf4a0061c297bad093586b88

## Cycle: contract:A1 (error)

- behavior: contract:A1
- kind: error
- outcome: runner-error
- criterion: EngineEventBus.logSubscriberError
- test: test/
- command: `/Users/arrrrny/.local/bin/zfa tdd refactor contract:A1 --feature 113-eventbus-error-observability --project /Users/arrrrny/Developer/zuraffa_agent --suite-baseline /Users/arrrrny/Developer/zuraffa_agent/specs/113-eventbus-error-observability/tdd/run-baseline.json`
- exit: 1
- at: 2026-09-11T21:35:57.956286Z
- output:
```
zfa tdd refactor: preflight suite
   command: dart test
   preflight exit: 0
   suite baseline: cached (2026-09-11T18:52:45.590096Z) — 8 pre-existing failure(s) excluded from the green verdicts (issue #922)
zfa tdd refactor: applying passes
   pass: build
     command: /Users/arrrrny/.local/bin/zfa build
     exit: 1
     changed: (none)
   pass "build" failed — misfire-stop.
zfa tdd refactor: re-proof suite
   command: dart test
   re-proof exit: 0
refactor: feature=113-eventbus-error-observability outcome=runner-error applied=0
```

- schema: 1
- prev-hash: 49cc478bb94b3aac90288559347b457f5eaabf41bf4a0061c297bad093586b88
- hash: 334b6bd5942ba0c2815e61e9af778830b1d75cc9eaacc15a5d158a7d79042e01

## Cycle: contract:A3 (green)

- behavior: contract:A3
- kind: green
- evidence: issue #1411 born-green hand transition — no prior red evidence exists (the hand step preceded the first certification); green certified from the passing target test with the vacuous-guard marker absent and the contract:A3:hand attestation header present
- subject-hash: 3f2b1d6c2427651cf4d95d826bf9dc3242b3d15ecd8951b52c7fd9ad553e169a
- criterion: EngineEventBus.subscriberErrorEvent
- test: test/tdd/113-eventbus-error-observability/contract_a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/contract_a3_test.dart --plain-name "EngineEventBus.subscriberErrorEvent(error, event) -> EngineEventSubscriberError (usecase contract)"`
- exit: 0
- at: 2026-09-11T21:36:45.131109Z
- output:
```
issue #1411 born-green hand transition — the designed hand step was completed before the first red certification (hand-first ordering); the passing transcript below is the green evidence bound to the current subject shape.

00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/contract_a3_test.dart                                                                               
00:00 +0: contract:A3 (EngineEventBus.subscriberErrorEvent) contract:A3 — EngineEventBus.subscriberErrorEvent(error, event) -> EngineEventSubscriberError (usecase contract)                           
00:00 +1: contract:A3 (EngineEventBus.subscriberErrorEvent) contract:A3 — EngineEventBus.subscriberErrorEvent(error, event) -> EngineEventSubscriberError (usecase contract)                           
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: genesis
- hash: 6acb33d8f71a8feb125d9165f55052dcd5cac5aaf0a8545767855edc4991354b

## Cycle: contract:A1 (error)

- behavior: contract:A1
- kind: error
- outcome: runner-error
- criterion: EngineEventBus.logSubscriberError
- test: test/
- command: `/Users/arrrrny/.local/bin/zfa tdd refactor contract:A1 --feature 113-eventbus-error-observability --project /Users/arrrrny/Developer/zuraffa_agent --suite-baseline /Users/arrrrny/Developer/zuraffa_agent/specs/113-eventbus-error-observability/tdd/run-baseline.json`
- exit: 1
- at: 2026-09-11T21:38:11.045498Z
- output:
```
zfa tdd refactor: preflight suite
   command: dart test
   preflight exit: 0
   suite baseline: cached (2026-09-11T18:52:45.590096Z) — 8 pre-existing failure(s) excluded from the green verdicts (issue #922)
zfa tdd refactor: applying passes
   pass: build
     command: /Users/arrrrny/.local/bin/zfa build
     exit: 1
     changed: (none)
   pass "build" failed — misfire-stop.
zfa tdd refactor: re-proof suite
   command: dart test
   re-proof exit: 0
refactor: feature=113-eventbus-error-observability outcome=runner-error applied=0
```

- schema: 1
- prev-hash: 334b6bd5942ba0c2815e61e9af778830b1d75cc9eaacc15a5d158a7d79042e01
- hash: 5bbfa3c87796589f74d4472578ffe744026c517e428c470aa0dfacefd4a6042f

## Cycle: contract:A1 (error)

- behavior: contract:A1
- kind: error
- outcome: runner-error
- criterion: EngineEventBus.logSubscriberError
- test: test/
- command: `/Users/arrrrny/.local/bin/zfa tdd refactor contract:A1 --feature 113-eventbus-error-observability --project /Users/arrrrny/Developer/zuraffa_agent --suite-baseline /Users/arrrrny/Developer/zuraffa_agent/specs/113-eventbus-error-observability/tdd/run-baseline.json`
- exit: 1
- at: 2026-09-11T21:39:43.952145Z
- output:
```
zfa tdd refactor: preflight suite
   command: dart test
   preflight exit: 0
   suite baseline: cached (2026-09-11T18:52:45.590096Z) — 8 pre-existing failure(s) excluded from the green verdicts (issue #922)
zfa tdd refactor: applying passes
   pass: build
     command: /Users/arrrrny/.local/bin/zfa build
     exit: 1
     changed: (none)
   pass "build" failed — misfire-stop.
zfa tdd refactor: re-proof suite
   command: dart test
   re-proof exit: 0
refactor: feature=113-eventbus-error-observability outcome=runner-error applied=0
```

- schema: 1
- prev-hash: 5bbfa3c87796589f74d4472578ffe744026c517e428c470aa0dfacefd4a6042f
- hash: be844bcde0adedeb752230966434f38751906a08e3be614d7c697a9308735265

## Cycle: A5 (green)

- behavior: A5
- kind: green
- subject-hash: 59ecbc19f2b8a6adc474e9687a97047d4badc1e345682a1a558c698e84363797
- criterion: AC-5
- test: test/tdd/113-eventbus-error-observability/a5_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart --plain-name "`publish` still returns normally, later"`
- exit: 0
- at: 2026-09-11T21:40:18.138865Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart                                                                                        
00:01 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart                                                                                        
00:02 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/113-eventbus-error-observability/a5_test.dart                                                                                        
00:02 +0: A5 (AC-5) A5 — `publish` still returns normally, later                                                                                                                                       
00:03 +0: A5 (AC-5) A5 — `publish` still returns normally, later                                                                                                                                       
00:03 +1: A5 (AC-5) A5 — `publish` still returns normally, later                                                                                                                                       
00:03 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 98dfc94a84af53ac15fb1c66b56518d12ec40912ab95a29c8e2988862ecbcf40
- hash: 444f8f5568353c7bb9c98805c9ae9eaf8b36de5493e46028e614f4ed2b4c168c

## Cycle: 113-eventbus-error-observability-refactor (refactor)

- behavior: 113-eventbus-error-observability-refactor
- kind: refactor
- criterion: FR-008
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T21:46:29.158551Z
- no-op: true
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:29 +1313 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1314 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1315 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1316 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1317 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1318 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1319 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1320 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:29 +1320 ~2: 2 skipped tests.                                                                                                                                                                       

00:29 +1320 ~2: All other tests passed!
re-proof: full
applied: 0 actions.
```

- schema: 1
- prev-hash: 6426d4cb1db5368ec953e6c76d9488f5fc00d06e0287dfbd1f3149c3f8f9fe71
- hash: f9338b0f3d946b9d697ff063f2d80dadc8f96360e88f0d02a72427b9d9d2fbc1

