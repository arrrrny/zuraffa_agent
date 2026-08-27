// Tests for the Planner/TODO system — Spec 014: Planner/TODO System.
//
// Covers (spec 014 FR / SC mapping):
// - FR-002: PlanState tracks steps with status (pending, in_progress,
//   completed, cancelled) — StepStatus + PlanStep + PlanState groups.
// - SC-001: model writes 3 todos, completes 2 → plan state reflects
//   accurate progress (counts + progressFraction).
// - SC-003: plan state persists across 5 turns (immutable snapshots
//   threaded turn-to-turn, SteeringQueue pattern).
// - FR-003: PlanMode none/auto/must configuration semantics.
// - FR-001: write_todos tool is injectable (AgentTool declaration).
// - SC-002: PlanMode=must forces planning before execution (Planner
//   injects the tool and requires a plan).
// - FR-005: plan changes emit PlanChangedEvent (previous/next/emittedAt).
// - Clean-arch layers: PlannerService/PlannerProvider wiring +
//   PlanStateRepository type bound (PR #48 StopPolicy pattern).
//
// Hand-curated — the model layer ships without @Zorphy (zfa v6.0.0
// cannot emit it; issues #13/#14), same as StopPolicy (PR #47/#48).

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/planner/plan_changed_event.dart';
import 'package:zuraffa_agent/src/domain/entities/planner/plan_mode.dart';
import 'package:zuraffa_agent/src/domain/entities/planner/plan_state.dart';
import 'package:zuraffa_agent/src/domain/entities/planner/plan_step.dart';
import 'package:zuraffa_agent/src/domain/entities/planner/planner.dart';
import 'package:zuraffa_agent/src/domain/entities/planner/step_status.dart';
import 'package:zuraffa_agent/src/domain/entities/planner/write_todos_tool.dart';
import 'package:zuraffa_agent/src/domain/repositories/plan_state_repository.dart';
import 'package:zuraffa_agent/src/domain/services/planner_service.dart';
import 'package:zuraffa_agent/src/data/providers/planner/planner_provider.dart';

void main() {
  PlanStep step(
    String id,
    String description, {
    StepStatus status = StepStatus.pending,
  }) =>
      PlanStep(id: id, description: description, status: status);

  PlanState threeTodos() => PlanState(
        id: 'mission-1',
        steps: [
          step('s1', 'Understand the codebase'),
          step('s2', 'Write the failing test'),
          step('s3', 'Make it green'),
        ],
        currentStepId: 's1',
      );

  group('StepStatus', () {
    test('has pending / inProgress / completed / cancelled', () {
      expect(StepStatus.values.length, 4);
      expect(StepStatus.values, contains(StepStatus.pending));
      expect(StepStatus.values, contains(StepStatus.inProgress));
      expect(StepStatus.values, contains(StepStatus.completed));
      expect(StepStatus.values, contains(StepStatus.cancelled));
    });

    test('terminal statuses are completed and cancelled only', () {
      expect(StepStatus.completed.isTerminal, isTrue);
      expect(StepStatus.cancelled.isTerminal, isTrue);
      expect(StepStatus.pending.isTerminal, isFalse);
      expect(StepStatus.inProgress.isTerminal, isFalse);
    });
  });

  group('PlanStep', () {
    test('defaults to pending status', () {
      final s = step('s1', 'Do the thing');
      expect(s.id, 's1');
      expect(s.description, 'Do the thing');
      expect(s.status, StepStatus.pending);
    });

    test('copyWith returns a new step with the transition applied', () {
      final s = step('s1', 'Do the thing');
      final inProgress = s.copyWith(status: StepStatus.inProgress);
      expect(identical(inProgress, s), isFalse);
      expect(s.status, StepStatus.pending, reason: 'original is untouched');
      expect(inProgress.id, 's1');
      expect(inProgress.description, 'Do the thing');
      expect(inProgress.status, StepStatus.inProgress);
    });

    test('value equality across id, description, status', () {
      expect(step('s1', 'a'), step('s1', 'a'));
      expect(step('s1', 'a').hashCode, step('s1', 'a').hashCode);
      expect(step('s1', 'a'), isNot(step('s1', 'b')));
      expect(
        step('s1', 'a', status: StepStatus.completed),
        isNot(step('s1', 'a')),
      );
      expect(step('s1', 'a'), isNot(step('s2', 'a')));
    });
  });

  group('PlanState — SC-001 accurate progress', () {
    test('3 todos with 2 completed reflect accurate counts', () {
      final plan = threeTodos()
          .markStep('s1', StepStatus.completed)
          .markStep('s2', StepStatus.completed);
      expect(plan.totalSteps, 3);
      expect(plan.completedCount, 2);
      expect(plan.pendingCount, 1);
      expect(plan.inProgressCount, 0);
      expect(plan.cancelledCount, 0);
    });

    test('progressFraction is completed over total', () {
      final plan = threeTodos()
          .markStep('s1', StepStatus.completed)
          .markStep('s2', StepStatus.completed);
      expect(plan.progressFraction, closeTo(2 / 3, 1e-9));
    });

    test('empty plan has zero progress and is not complete', () {
      const plan = PlanState(id: 'mission-1', steps: []);
      expect(plan.totalSteps, 0);
      expect(plan.progressFraction, 0.0);
      expect(plan.isComplete, isFalse);
    });

    test('counts include in_progress and cancelled steps', () {
      final plan = threeTodos()
          .markStep('s1', StepStatus.inProgress)
          .markStep('s2', StepStatus.cancelled);
      expect(plan.inProgressCount, 1);
      expect(plan.cancelledCount, 1);
      expect(plan.completedCount, 0);
      expect(plan.pendingCount, 1);
      expect(plan.progressFraction, 0.0);
    });

    test('isComplete only when every step is terminal', () {
      final twoDone = threeTodos()
          .markStep('s1', StepStatus.completed)
          .markStep('s2', StepStatus.cancelled)
          .markStep('s3', StepStatus.completed);
      expect(twoDone.isComplete, isTrue);

      final oneLeft = threeTodos().markStep('s1', StepStatus.completed);
      expect(oneLeft.isComplete, isFalse);
    });

    test('currentStep resolves currentStepId against steps', () {
      final plan = threeTodos();
      expect(plan.currentStep?.id, 's1');

      const empty = PlanState(id: 'mission-1', steps: []);
      expect(empty.currentStep, isNull);

      final dangling = PlanState(
        id: 'mission-1',
        steps: [step('s1', 'a')],
        currentStepId: 'gone',
      );
      expect(dangling.currentStep, isNull);
    });

    test('updateStep replaces the step with the same id', () {
      final plan = threeTodos().updateStep(
        step('s2', 'Write the failing test', status: StepStatus.inProgress),
      );
      expect(plan.steps[1].status, StepStatus.inProgress);
      expect(plan.steps[0].status, StepStatus.pending);
      expect(plan.steps.length, 3);
    });

    test('markStep on unknown id returns an equal snapshot', () {
      final plan = threeTodos();
      final untouched = plan.markStep('nope', StepStatus.completed);
      expect(untouched, plan);
    });

    test('withSteps replaces the whole list immutably', () {
      final plan = threeTodos();
      final replaced = plan.withSteps([step('only', 'One thing')]);
      expect(replaced.steps.length, 1);
      expect(replaced.steps.first.id, 'only');
      expect(plan.steps.length, 3, reason: 'original snapshot untouched');
      expect(replaced.id, plan.id);
    });
  });

  group('PlanState — SC-003 persists across turns', () {
    test('state threaded through 5 simulated turns is preserved', () {
      // Turn 1: the model writes 3 todos.
      var plan = threeTodos();
      // Turn 2: starts step 1.
      plan = plan.markStep('s1', StepStatus.inProgress);
      // Turn 3: completes step 1, starts step 2.
      plan = plan
          .markStep('s1', StepStatus.completed)
          .markStep('s2', StepStatus.inProgress);
      // Turn 4: completes step 2 (nothing new injected).
      plan = plan.markStep('s2', StepStatus.completed);
      // Turn 5: starts step 3.
      plan = plan.markStep('s3', StepStatus.inProgress);

      expect(plan.totalSteps, 3);
      expect(plan.completedCount, 2);
      expect(plan.inProgressCount, 1);
      expect(plan.pendingCount, 0);
      expect(plan.progressFraction, closeTo(2 / 3, 1e-9));
      expect(plan.steps.firstWhere((s) => s.id == 's3').status,
          StepStatus.inProgress);
    });

    test('value equality holds for identical snapshots', () {
      final a = threeTodos().markStep('s1', StepStatus.completed);
      final b = threeTodos().markStep('s1', StepStatus.completed);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(threeTodos(),
          isNot(threeTodos().markStep('s1', StepStatus.completed)));
    });
  });

  group('PlanMode — FR-003 configuration', () {
    test('has none / auto / must', () {
      expect(PlanMode.values.length, 3);
      expect(PlanMode.values, contains(PlanMode.none));
      expect(PlanMode.values, contains(PlanMode.auto));
      expect(PlanMode.values, contains(PlanMode.must));
    });

    test('none injects no planner tools', () {
      expect(PlanMode.none.injectsPlannerTools, isFalse);
      expect(PlanMode.none.requiresPlanningBeforeExecution, isFalse);
    });

    test('auto injects optional planner tools', () {
      expect(PlanMode.auto.injectsPlannerTools, isTrue);
      expect(PlanMode.auto.requiresPlanningBeforeExecution, isFalse);
    });

    test('must force planning before execution', () {
      expect(PlanMode.must.injectsPlannerTools, isTrue);
      expect(PlanMode.must.requiresPlanningBeforeExecution, isTrue);
    });
  });

  group('Planner + WriteTodosTool — FR-001 injectable tool', () {
    test('write_todos is an AgentTool declaration with a todos schema', () {
      final tool = WriteTodosTool.declaration;
      expect(tool, isA<AgentTool>());
      expect(tool.id, 'write_todos');
      expect(tool.riskTier, RiskTier.safe);
      expect(tool.executionMode, ExecutionMode.sequential);
      expect(tool.requiresConfirmation, isFalse);
      expect(tool.paramsSchema, isNotNull);
      expect(tool.paramsSchema!['required'], contains('todos'));
    });

    test('Planner defaults to auto mode', () {
      const planner = Planner();
      expect(planner.mode, PlanMode.auto);
    });

    test('Planner exposes the write_todos tool', () {
      const planner = Planner(mode: PlanMode.must);
      expect(planner.writeTodosTool.id, 'write_todos');
      expect(planner.writeTodosTool, same(WriteTodosTool.declaration));
    });

    test('toolsForInjection returns write_todos for auto and must', () {
      expect(
        const Planner(mode: PlanMode.auto).toolsForInjection(),
        [WriteTodosTool.declaration],
      );
      expect(
        const Planner(mode: PlanMode.must).toolsForInjection(),
        [WriteTodosTool.declaration],
      );
    });

    test('toolsForInjection is empty for none', () {
      expect(const Planner(mode: PlanMode.none).toolsForInjection(), isEmpty);
    });

    test('SC-002: mode=must forces planning before execution', () {
      const planner = Planner(mode: PlanMode.must);
      expect(planner.injectsWriteTodosTool, isTrue);
      expect(planner.requiresPlanningBeforeExecution, isTrue);
      expect(planner.toolsForInjection(), isNotEmpty);
    });
  });

  group('PlanChangedEvent — FR-005', () {
    test('carries previous, next, and emittedAt', () {
      final previous = threeTodos();
      final next = previous.markStep('s1', StepStatus.completed);
      final event = PlanChangedEvent(
        emittedAt: DateTime.utc(2026, 8, 27, 12, 0, 0),
        previous: previous,
        next: next,
      );
      expect(event.previous, previous);
      expect(event.next, next);
      expect(event.emittedAt, DateTime.utc(2026, 8, 27, 12, 0, 0));
    });

    test('records progress gains between snapshots', () {
      final previous = threeTodos();
      final progressed = previous
          .markStep('s1', StepStatus.completed)
          .markStep('s2', StepStatus.completed);
      final event = PlanChangedEvent(
        emittedAt: DateTime.utc(2026, 8, 27, 12, 0, 0),
        previous: previous,
        next: progressed,
      );
      expect(event.completedGained, 2);

      final regressed = progressed.markStep('s2', StepStatus.inProgress);
      final rollback = PlanChangedEvent(
        emittedAt: DateTime.utc(2026, 8, 27, 12, 0, 1),
        previous: progressed,
        next: regressed,
      );
      expect(rollback.completedGained, -1);
    });

    test('value equality across fields', () {
      final at = DateTime.utc(2026, 8, 27, 12, 0, 0);
      final a = PlanChangedEvent(
        emittedAt: at,
        previous: threeTodos(),
        next: threeTodos().markStep('s1', StepStatus.completed),
      );
      final b = PlanChangedEvent(
        emittedAt: at,
        previous: threeTodos(),
        next: threeTodos().markStep('s1', StepStatus.completed),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Clean-architecture layers (PR #48 pattern)', () {
    test('PlannerProvider is a PlannerService', () {
      expect(PlannerProvider(), isA<PlannerService>());
    });

    test('PlannerProvider.current throws UnimplementedError', () {
      expect(
        () => PlannerProvider().current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('PlannerProvider.mode throws UnimplementedError', () {
      expect(
        () => PlannerProvider().mode(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('PlannerService is usable as a type bound', () {
      PlannerService mk(PlannerService s) => s;
      final provider = PlannerProvider();
      expect(mk(provider), same(provider));
    });

    test('PlanStateRepository is usable as a type bound', () {
      void fn<T extends PlanStateRepository>() {}
      fn<PlanStateRepository>();
      expect(true, isTrue);
    });
  });
}
