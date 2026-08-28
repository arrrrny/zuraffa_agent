// Spec 005 — acceptance behavior A4: a persisted sub-agent instance id resumes
// its session tree from the stored leaf.
//
// The "engine restart" is modelled the way the durable datasources already do
// it (see test/data/datasources/turn_record/turn_record_remote_datasource_test
// .dart): write through one store bound to a JSONL path, then construct a
// SECOND store over the same path — a fresh process would see exactly that —
// and resume by id. Resuming must hand back the stored session-tree leaf
// (parentSessionId) and the accumulated run state, not a default.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/datasources/sub_agent_instance/sub_agent_instance_store.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_instance/sub_agent_instance.dart';

void main() {
  test('A4: a persisted instance id resumes its session tree from the stored leaf',
      () async {
    final dir = await Directory.systemTemp.createTemp('zfa-subagent-a4');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/instances.jsonl';

    const instance = SubAgentInstance(
      id: 'inst-42',
      subAgentSpecId: 'explore',
      parentSessionId: 'session-root/branch-a/leaf-7',
      totalRuns: 3,
      lastRunOutcome: 'success',
    );

    await SubAgentInstanceStore(path: path).save(instance);

    // Fresh store over the same durable file == engine restart.
    final resumed = await SubAgentInstanceStore(path: path).resume('inst-42');

    expect(resumed, isNotNull);
    expect(resumed!.parentSessionId, 'session-root/branch-a/leaf-7');
    expect(resumed.subAgentSpecId, 'explore');
    expect(resumed.totalRuns, 3);
    expect(resumed.lastRunOutcome, 'success');
    expect(resumed, instance);
  });

  test('A4: resuming an unknown instance id yields null', () async {
    final dir = await Directory.systemTemp.createTemp('zfa-subagent-a4-miss');
    addTearDown(() => dir.delete(recursive: true));
    expect(
      await SubAgentInstanceStore(path: '${dir.path}/instances.jsonl')
          .resume('nope'),
      isNull,
    );
  });
}
