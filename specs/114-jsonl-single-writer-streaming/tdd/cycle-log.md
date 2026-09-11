# Cycle Log

Append only. Newest last. Every entry's `red` block is the evidence that the test existed and failed before the implementation.

## Cycle: A1 (red)

- behavior: A1
- kind: red
- classification: assertionFailure
- subject-hash: c6346609050ad8a75f4867aa974b47f26a9ef59aaed5dd2afa0ddb59c0696cf2
- criterion: AC-1
- test: test/tdd/114-jsonl-single-writer-streaming/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a1_test.dart --plain-name "every entry"`
- exit: 1
- at: 2026-09-11T22:00:53.902698Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a1_test.dart                                                                                       
00:01 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a1_test.dart                                                                                       
00:02 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a1_test.dart                                                                                       
00:02 +0: A1 (AC-1) A1 — every entry                                                                                                                                                                   
00:02 +0 -1: A1 (AC-1) A1 — every entry [E]                                                                                                                                                            
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a1 not implemented>
  
  package:matcher                                               expect
  test/tdd/114-jsonl-single-writer-streaming/a1_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a1_test.dart -p vm --plain-name 'A1 (AC-1) A1 — every entry'

00:02 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: ac4951223d12ac4acc4248b9e21631262d84e4500611a9d3600121fd0e445dbf

## Cycle: A2 (red)

- behavior: A2
- kind: red
- classification: assertionFailure
- subject-hash: e19acec434d5061ba0ef2721696b826ba1835dbeb1b238d6b0262ee66673d41d
- criterion: AC-2
- test: test/tdd/114-jsonl-single-writer-streaming/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a2_test.dart --plain-name "acquisition fails fast"`
- exit: 1
- at: 2026-09-11T22:00:57.800796Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a2_test.dart                                                                                       
00:00 +0: A2 (AC-2) A2 — acquisition fails fast                                                                                                                                                        
00:00 +0 -1: A2 (AC-2) A2 — acquisition fails fast [E]                                                                                                                                                 
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a2 not implemented>
  
  package:matcher                                               expect
  test/tdd/114-jsonl-single-writer-streaming/a2_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a2_test.dart -p vm --plain-name 'A2 (AC-2) A2 — acquisition fails fast'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 3c26a89512abea9c8917f4ebbf645c0b93fb85f46399441b75896fe28c45137c

## Cycle: A3 (red)

- behavior: A3
- kind: red
- classification: assertionFailure
- subject-hash: fe7567cb8145debfd81d50d5115f4289df271382cc3ab7a73feb8267e9420f11
- criterion: AC-3
- test: test/tdd/114-jsonl-single-writer-streaming/a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a3_test.dart --plain-name "iteration stops without requiring"`
- exit: 1
- at: 2026-09-11T22:01:01.639433Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a3_test.dart                                                                                       
00:00 +0: A3 (AC-3) A3 — iteration stops without requiring                                                                                                                                             
00:00 +0 -1: A3 (AC-3) A3 — iteration stops without requiring [E]                                                                                                                                      
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a3 not implemented>
  
  package:matcher                                               expect
  test/tdd/114-jsonl-single-writer-streaming/a3_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a3_test.dart -p vm --plain-name 'A3 (AC-3) A3 — iteration stops without requiring'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 73006c015d4f6b14ba3a182075c0213f2002979fb61822a63613c1b5c39b7a95

## Cycle: A4 (red)

- behavior: A4
- kind: red
- classification: assertionFailure
- subject-hash: 7ebe466270c1987bab34a9c6ff126e98c5c2a90275a34cb07dea3a6572195228
- criterion: AC-4
- test: test/tdd/114-jsonl-single-writer-streaming/a4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a4_test.dart --plain-name "the same entry set is yielded as"`
- exit: 1
- at: 2026-09-11T22:01:05.438874Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a4_test.dart                                                                                       
00:00 +0: A4 (AC-4) A4 — the same entry set is yielded as                                                                                                                                              
00:00 +0 -1: A4 (AC-4) A4 — the same entry set is yielded as [E]                                                                                                                                       
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_a4 not implemented>
  
  package:matcher                                               expect
  test/tdd/114-jsonl-single-writer-streaming/a4_test.dart 30:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a4_test.dart -p vm --plain-name 'A4 (AC-4) A4 — the same entry set is yielded as'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 20cb823e58f1b6026f9d6602f6372b06c7bc4f12f828179ebda76b93bf87ddd9

## Cycle: U1 (red)

- behavior: U1
- kind: red
- classification: assertionFailure
- subject-hash: e239369a8200585f7958b8d5ee9eeef35ed1b02f64979c3adbc4debf063d6c8a
- criterion: FR-001, JsonlSessionStorage.guard
- test: test/tdd/114-jsonl-single-writer-streaming/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u1_test.dart --plain-name "Every `JsonlSessionStorage` mutation (`appendEntry`,"`
- exit: 1
- at: 2026-09-11T22:01:09.418151Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u1_test.dart                                                                                       
00:00 +0: U1 (FR-001, JsonlSessionStorage.guard) U1 — Every `JsonlSessionStorage` mutation (`appendEntry`,                                                                                             
00:00 +0 -1: U1 (FR-001, JsonlSessionStorage.guard) U1 — Every `JsonlSessionStorage` mutation (`appendEntry`, [E]                                                                                      
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: provide a representative argument for subject_u1 (declared param 0: mutation)>
  
  package:matcher                                               expect
  test/tdd/114-jsonl-single-writer-streaming/u1_test.dart 36:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u1_test.dart -p vm --plain-name 'U1 (FR-001, JsonlSessionStorage.guard) U1 — Every `JsonlSessionStorage` mutation (`appendEntry`,'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 3555f5bad40da248d61e29cb579353914c354707b92e325177b36db3c7eb9d1b

## Cycle: U4 (red)

- behavior: U4
- kind: red
- classification: assertionFailure
- subject-hash: 9d25cdef48106f31ce7b0dff8641e96f7040aa435882ee91ab3de671109fe837
- criterion: FR-004, SessionStorage.entries
- test: test/tdd/114-jsonl-single-writer-streaming/u4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u4_test.dart --plain-name "Hive persistence MUST document its single-writer"`
- exit: 1
- at: 2026-09-11T22:06:58.803064Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u4_test.dart                                                                                       
00:00 +0: U4 (FR-004, SessionStorage.entries) U4 — Hive persistence MUST document its single-writer                                                                                                    
00:00 +0 -1: U4 (FR-004, SessionStorage.entries) U4 — Hive persistence MUST document its single-writer [E]                                                                                             
  Expected: return normally
    Actual: <Closure: () => void>
     Which: threw UnimplementedError:<UnimplementedError: subject_u4 stub>
  
  package:matcher                                               expect
  test/tdd/114-jsonl-single-writer-streaming/u4_test.dart 28:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u4_test.dart -p vm --plain-name 'U4 (FR-004, SessionStorage.entries) U4 — Hive persistence MUST document its single-writer'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: 8f520ffa53bf369b22a76a2f13fdd8e1ee0cfc3548d30b962ed9454231f208b5

## Cycle: U2 (red)

- behavior: U2
- kind: red
- classification: assertionFailure
- subject-hash: 6d161eec34a7428b21494631fbf38f0267a609ee4d5e31de509e8505e1fec739
- criterion: FR-002, SessionLock.acquire
- test: test/tdd/114-jsonl-single-writer-streaming/u2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u2_test.dart --plain-name "`JsonlSessionStorage.init` MUST acquire an advisory"`
- exit: 1
- at: 2026-09-11T22:08:42.424404Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u2_test.dart                                                                                       
00:00 +0: U2 (FR-002, SessionLock.acquire) U2 — `JsonlSessionStorage.init` MUST acquire an advisory                                                                                                    
00:00 +0 -1: U2 (FR-002, SessionLock.acquire) U2 — `JsonlSessionStorage.init` MUST acquire an advisory [E]                                                                                             
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u2 stub>
  
  package:matcher                                               expect
  test/tdd/114-jsonl-single-writer-streaming/u2_test.dart 32:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u2_test.dart -p vm --plain-name 'U2 (FR-002, SessionLock.acquire) U2 — `JsonlSessionStorage.init` MUST acquire an advisory'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: a6dca5a309395197a0c49c1b6065549ff60c7ba08000b13a8b0017e722907f34

## Cycle: U3 (red)

- behavior: U3
- kind: red
- classification: assertionFailure
- subject-hash: f270925d57dd7eb138bfc889e94c9e9ead351242c1a1377588ebb850a3286ba9
- criterion: FR-003, SessionStorage.entries
- test: test/tdd/114-jsonl-single-writer-streaming/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u3_test.dart --plain-name "`SessionStorage.entries()` MUST return a lazy"`
- exit: 1
- at: 2026-09-11T22:08:44.160760Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u3_test.dart                                                                                       
00:00 +0: U3 (FR-003, SessionStorage.entries) U3 — `SessionStorage.entries()` MUST return a lazy                                                                                                       
00:00 +0 -1: U3 (FR-003, SessionStorage.entries) U3 — `SessionStorage.entries()` MUST return a lazy [E]                                                                                                
  Expected: not <Instance of 'UnimplementedError'>
    Actual: UnimplementedError:<UnimplementedError: subject_u3 stub>
  
  package:matcher                                               expect
  test/tdd/114-jsonl-single-writer-streaming/u3_test.dart 32:7  main.<fn>.<fn>
  

To run this test again: dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u3_test.dart -p vm --plain-name 'U3 (FR-003, SessionStorage.entries) U3 — `SessionStorage.entries()` MUST return a lazy'

00:00 +0 -1: Some tests failed.                                                                                                                                                                        

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

- schema: 1
- prev-hash: genesis
- hash: e18e69d83ec5c131989a40ae803a77bc20f113d8fe2a299d29a4aaf007cca836

## Cycle: U2 (green)

- behavior: U2
- kind: green
- subject-hash: 605843f9b5e2574515513284271ea64487ff7a52d957648f961e356b269d7680
- criterion: FR-002, SessionLock.acquire
- test: test/tdd/114-jsonl-single-writer-streaming/u2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u2_test.dart --plain-name "`JsonlSessionStorage.init` MUST acquire an advisory"`
- exit: 0
- at: 2026-09-11T22:08:55.585122Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u2_test.dart                                                                                       
00:00 +0: U2 (FR-002, SessionLock.acquire) U2 — `JsonlSessionStorage.init` MUST acquire an advisory                                                                                                    
00:00 +1: U2 (FR-002, SessionLock.acquire) U2 — `JsonlSessionStorage.init` MUST acquire an advisory                                                                                                    
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: a6dca5a309395197a0c49c1b6065549ff60c7ba08000b13a8b0017e722907f34
- hash: ea85f1472b245480abdb899eb50036445f5ae2f1305a41177db19aaa5a29459b

## Cycle: U3 (green)

- behavior: U3
- kind: green
- subject-hash: 3f01b7052bd4573617113156b6137abafaf4d05bfd3912108a27a0f8267cda28
- criterion: FR-003, SessionStorage.entries
- test: test/tdd/114-jsonl-single-writer-streaming/u3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u3_test.dart --plain-name "`SessionStorage.entries()` MUST return a lazy"`
- exit: 0
- at: 2026-09-11T22:08:57.007866Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u3_test.dart                                                                                       
00:00 +0: U3 (FR-003, SessionStorage.entries) U3 — `SessionStorage.entries()` MUST return a lazy                                                                                                       
00:00 +1: U3 (FR-003, SessionStorage.entries) U3 — `SessionStorage.entries()` MUST return a lazy                                                                                                       
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: e18e69d83ec5c131989a40ae803a77bc20f113d8fe2a299d29a4aaf007cca836
- hash: fa3815109efa65286c0ec0f6923a0cdfa9676fbc48383d3b4ebdcf11b44964ec

## Cycle: U4 (green)

- behavior: U4
- kind: green
- subject-hash: c23d3259305dfe023163212d35d1fc2978acc13f30bacbe0662d9c0e13c0ad64
- criterion: FR-004, SessionStorage.entries
- test: test/tdd/114-jsonl-single-writer-streaming/u4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u4_test.dart --plain-name "Hive persistence MUST document its single-writer"`
- exit: 0
- at: 2026-09-11T22:08:58.430182Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u4_test.dart                                                                                       
00:00 +0: U4 (FR-004, SessionStorage.entries) U4 — Hive persistence MUST document its single-writer                                                                                                    
00:00 +1: U4 (FR-004, SessionStorage.entries) U4 — Hive persistence MUST document its single-writer                                                                                                    
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 8f520ffa53bf369b22a76a2f13fdd8e1ee0cfc3548d30b962ed9454231f208b5
- hash: 4cee0b8b01f18ae51bed0b0da792c416bd409c86f97dd4fc56d2515c1d0ca022

## Cycle: A1 (green)

- behavior: A1
- kind: green
- subject-hash: 757384ca82639fcf33a21a88f7d2905fbca6115a12758b6d41187b94d4b0c5ad
- criterion: AC-1
- test: test/tdd/114-jsonl-single-writer-streaming/a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a1_test.dart --plain-name "every entry"`
- exit: 0
- at: 2026-09-11T22:11:06.856059Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a1_test.dart                                                                                       
00:00 +0: A1 (AC-1) A1 — every entry                                                                                                                                                                   
00:00 +1: A1 (AC-1) A1 — every entry                                                                                                                                                                   
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: ac4951223d12ac4acc4248b9e21631262d84e4500611a9d3600121fd0e445dbf
- hash: 6c7a549f4dfd44f26650a23a839f307e19a4d2e4d2b113421152bb3543e41848

## Cycle: A2 (green)

- behavior: A2
- kind: green
- subject-hash: 904e7b85ec10a0fc8e8b6bdb903ad33a0b9b3c31fc1c08337aa68abdcbd9f123
- criterion: AC-2
- test: test/tdd/114-jsonl-single-writer-streaming/a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a2_test.dart --plain-name "acquisition fails fast"`
- exit: 0
- at: 2026-09-11T22:11:08.300112Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a2_test.dart                                                                                       
00:00 +0: A2 (AC-2) A2 — acquisition fails fast                                                                                                                                                        
00:00 +1: A2 (AC-2) A2 — acquisition fails fast                                                                                                                                                        
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 3c26a89512abea9c8917f4ebbf645c0b93fb85f46399441b75896fe28c45137c
- hash: 9328caa91533069cd3f043a85b7edf94f3b4dce10cd8c7a993177cb47a6eb430

## Cycle: A3 (green)

- behavior: A3
- kind: green
- subject-hash: 16b75602529777a19c1318fd5813a199164439f811632811233bbf7ef089f5ef
- criterion: AC-3
- test: test/tdd/114-jsonl-single-writer-streaming/a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a3_test.dart --plain-name "iteration stops without requiring"`
- exit: 0
- at: 2026-09-11T22:11:09.766278Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a3_test.dart                                                                                       
00:00 +0: A3 (AC-3) A3 — iteration stops without requiring                                                                                                                                             
00:00 +1: A3 (AC-3) A3 — iteration stops without requiring                                                                                                                                             
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 73006c015d4f6b14ba3a182075c0213f2002979fb61822a63613c1b5c39b7a95
- hash: d4cfd86d89fe5438d45f165e9678f6dee64d3b387adaee0ca9bd316302364401

## Cycle: A4 (green)

- behavior: A4
- kind: green
- subject-hash: d0f4475cb1ced1b7d06a88ec14a2d2025945b0557ae3b0ec322c440bd84be9fe
- criterion: AC-4
- test: test/tdd/114-jsonl-single-writer-streaming/a4_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a4_test.dart --plain-name "the same entry set is yielded as"`
- exit: 0
- at: 2026-09-11T22:11:11.198044Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/a4_test.dart                                                                                       
00:00 +0: A4 (AC-4) A4 — the same entry set is yielded as                                                                                                                                              
00:00 +1: A4 (AC-4) A4 — the same entry set is yielded as                                                                                                                                              
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 20cb823e58f1b6026f9d6602f6372b06c7bc4f12f828179ebda76b93bf87ddd9
- hash: 34287a64aed4d22b715ffa916aff9b7dae7e95ee0d5ddfc46a29d8f5def7959c

## Cycle: U1 (green)

- behavior: U1
- kind: green
- subject-hash: f6db938822a7a08059b66568ac3a3b28e0bd17593d00edbcbf9f7d4634d77350
- criterion: FR-001, JsonlSessionStorage.guard
- test: test/tdd/114-jsonl-single-writer-streaming/u1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u1_test.dart --plain-name "Every `JsonlSessionStorage` mutation (`appendEntry`,"`
- exit: 0
- at: 2026-09-11T22:11:12.632140Z
- output:
```
00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/u1_test.dart                                                                                       
00:00 +0: U1 (FR-001, JsonlSessionStorage.guard) U1 — Every `JsonlSessionStorage` mutation (`appendEntry`,                                                                                             
00:00 +1: U1 (FR-001, JsonlSessionStorage.guard) U1 — Every `JsonlSessionStorage` mutation (`appendEntry`,                                                                                             
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: 3555f5bad40da248d61e29cb579353914c354707b92e325177b36db3c7eb9d1b
- hash: 062d342e64627867a3b6416a11163f04f518351a3c3f10cce02a908ce073586c

## Cycle: contract:A1 (green)

- behavior: contract:A1
- kind: green
- evidence: issue #1411 born-green hand transition — no prior red evidence exists (the hand step preceded the first certification); green certified from the passing target test with the vacuous-guard marker absent and the contract:A1:hand attestation header present
- subject-hash: 1aa8c6058132357ec0c3a3a8a84521ea9f097e9c76fd866fde5d2fd25841a6e1
- criterion: SessionLock.acquire
- test: test/tdd/114-jsonl-single-writer-streaming/contract_a1_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/contract_a1_test.dart --plain-name "SessionLock.acquire() -> Future<void> (usecase contract)"`
- exit: 0
- at: 2026-09-11T22:17:07.944830Z
- output:
```
issue #1411 born-green hand transition — the designed hand step was completed before the first red certification (hand-first ordering); the passing transcript below is the green evidence bound to the current subject shape.

00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/contract_a1_test.dart                                                                              
00:01 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/contract_a1_test.dart                                                                              
00:02 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/contract_a1_test.dart                                                                              
00:02 +0: contract:A1 (SessionLock.acquire) contract:A1 — SessionLock.acquire() -> Future<void> (usecase contract)                                                                                     
00:02 +1: contract:A1 (SessionLock.acquire) contract:A1 — SessionLock.acquire() -> Future<void> (usecase contract)                                                                                     
00:02 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: genesis
- hash: 4b273179df83540f054753b8a531e094464e6d9b4a3def696dca8b13593b63cd

## Cycle: contract:A2 (green)

- behavior: contract:A2
- kind: green
- evidence: issue #1411 born-green hand transition — no prior red evidence exists (the hand step preceded the first certification); green certified from the passing target test with the vacuous-guard marker absent and the contract:A2:hand attestation header present
- subject-hash: 6be75736750d2061c40bac421bb53e8b2f4725d6b9fecf07d8a5e5bb348cefb7
- criterion: SessionLock.release
- test: test/tdd/114-jsonl-single-writer-streaming/contract_a2_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/contract_a2_test.dart --plain-name "SessionLock.release() -> Future<void> (usecase contract)"`
- exit: 0
- at: 2026-09-11T22:17:09.462626Z
- output:
```
issue #1411 born-green hand transition — the designed hand step was completed before the first red certification (hand-first ordering); the passing transcript below is the green evidence bound to the current subject shape.

00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/contract_a2_test.dart                                                                              
00:00 +0: contract:A2 (SessionLock.release) contract:A2 — SessionLock.release() -> Future<void> (usecase contract)                                                                                     
00:00 +1: contract:A2 (SessionLock.release) contract:A2 — SessionLock.release() -> Future<void> (usecase contract)                                                                                     
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: genesis
- hash: 366e62728b896c48a80c8a6bf4ed7c1f4abb1a018ad07ae397a63f2ae1e79804

## Cycle: contract:A3 (green)

- behavior: contract:A3
- kind: green
- evidence: issue #1411 born-green hand transition — no prior red evidence exists (the hand step preceded the first certification); green certified from the passing target test with the vacuous-guard marker absent and the contract:A3:hand attestation header present
- subject-hash: 1ff3357689d001071434a8ed159a94f94801aa28e0c1b85b531422b8c9b388a2
- criterion: JsonlSessionStorage.guard
- test: test/tdd/114-jsonl-single-writer-streaming/contract_a3_test.dart
- command: `dart test /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/contract_a3_test.dart --plain-name "JsonlSessionStorage.guard(mutation) -> Future<void> (usecase contract)"`
- exit: 0
- at: 2026-09-11T22:17:11.069154Z
- output:
```
issue #1411 born-green hand transition — the designed hand step was completed before the first red certification (hand-first ordering); the passing transcript below is the green evidence bound to the current subject shape.

00:00 +0: loading /Users/arrrrny/Developer/zuraffa_agent/test/tdd/114-jsonl-single-writer-streaming/contract_a3_test.dart                                                                              
00:00 +0: contract:A3 (JsonlSessionStorage.guard) contract:A3 — JsonlSessionStorage.guard(mutation) -> Future<void> (usecase contract)                                                                 
00:00 +1: contract:A3 (JsonlSessionStorage.guard) contract:A3 — JsonlSessionStorage.guard(mutation) -> Future<void> (usecase contract)                                                                 
00:00 +1: All tests passed!
```
- generation:
  (none)
- suite: baseline=0 guard=0 new=(none)

- schema: 1
- prev-hash: genesis
- hash: 225b0aa407d471203c2ca61ac53f2702999cd9d0b5fceba0c36be8080085862f

## Cycle: 114-jsonl-single-writer-streaming-refactor (refactor)

- behavior: 114-jsonl-single-writer-streaming-refactor
- kind: refactor
- criterion: FR-007
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:30:13.067160Z
- output:
```
preflight: green
re-proof: green
re-proof verdict: green (exit 0)
re-proof retries: 0
re-proof output tail (stdout+stderr, truncated):
...(truncated)
00:30 +1324 ~2: test/session_storage/migration_test.dart: spec 110 — JSONL schema versioning (issue #122) A1: a v1 fixture migrates to v3 in memory and on disk                                        
00:30 +1325 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:30 +1326 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:30 +1327 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:30 +1328 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:30 +1329 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:30 +1330 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:30 +1331 ~2: test/session_storage/hive_version_test.dart: U9: a fresh Hive store stamps the meta-box schema version                                                                                 
00:30 +1331 ~2: 2 skipped tests.                                                                                                                                                                       

00:30 +1331 ~2: All other tests passed!
re-proof: full
receipts refreshed: 2 receipted artifact(s) re-hashed (sanctioned refactor provenance, issue #1311)
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
  changed: lib/src/jsonl_session_storage.dart, lib/tdd/114-jsonl-single-writer-streaming/a4_subject.dart, lib/tdd/114-jsonl-single-writer-streaming/u2_subject.dart
- action: fix
  command: `dart fix --apply lib/`
  exit: 0
  changed: (none)

- schema: 1
- prev-hash: genesis
- hash: 606f42639d0c7141fe0696f8f95ea3531c12ad46264c50f7cf7e91b968ee6e1e

## Cycle: A4 (refresh)

- behavior: A4
- kind: refresh
- subject-hash: a7fea1ed9537138019467dbb22833bcd35be835f4ef3dd9cbb447fb5cd5ff514
- criterion: AC-4
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:30:13.069391Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a4_subject.dart (hash d0f4475c… → a7fea1ed…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: 34287a64aed4d22b715ffa916aff9b7dae7e95ee0d5ddfc46a29d8f5def7959c
- hash: 49e5680d903f8a5741026707a604b9ab9714ea56c43c3188579631f334508fe8

## Cycle: U2 (refresh)

- behavior: U2
- kind: refresh
- subject-hash: 47428b522c19bfb548e6f0be515b281f4454c1fb35f1782c2de86207105931ea
- criterion: FR-002, SessionLock.acquire
- test: test/
- command: `dart test`
- exit: 0
- at: 2026-09-11T22:30:13.071250Z
- output:
```
refresh (issue #1430): the pass rewrote /Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u2_subject.dart (hash 605843f9… → 47428b52…); the re-proof above proved the suite green over the new shape — the certified evidence re-binds to it.
```

- schema: 1
- prev-hash: ea85f1472b245480abdb899eb50036445f5ae2f1305a41177db19aaa5a29459b
- hash: 3de90e05ad90d0a58f81bc6c6285d29506dd984d1f243f67839278e86b47cbfe

