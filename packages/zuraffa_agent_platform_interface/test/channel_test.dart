// Channel-contract test (spec 115 SC-003): the Dart side encodes the
// pinned method names and argument shapes; host responses decode.
//
// Runs under `flutter test` (binding-required); the transcript is
// recorded in the feature cycle-log.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zuraffa_agent_platform_interface/zuraffa_agent_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('channel contract: method names + argument shapes (FR-005)',
      () async {
    final recorded = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.zuraffa/agent_platform'),
            (call) async {
      recorded.add(call);
      switch (call.method) {
        case 'getAgentHome':
          return '/support';
        case 'secureRead':
          return 'sk-test-value';
        default:
          return null;
      }
    });

    final platform = ZuraffaAgentMethodChannelPlatform();
    expect(await platform.getAgentHome(), '/support');
    expect(await platform.secureRead('openai'), 'sk-test-value');
    await platform.secureWrite('openai', 'sk-new');
    await platform.secureDelete('openai');

    expect(
      recorded.map((c) => c.method),
      ['getAgentHome', 'secureRead', 'secureWrite', 'secureDelete'],
    );
    expect(recorded[1].arguments, {'key': 'openai'});
    expect(recorded[2].arguments, {'key': 'openai', 'value': 'sk-new'});
    expect(recorded[3].arguments, {'key': 'openai'});
  });

  test('fake round-trip (US2)', () async {
    final fake = AgentPlatformFake(home: '/support');
    expect(await fake.getAgentHome(), '/support');
    await fake.secureWrite('k', 'v');
    expect(await fake.secureRead('k'), 'v');
    await fake.secureDelete('k');
    expect(await fake.secureRead('k'), isNull);
    expect(fake.calls, [
      'getAgentHome',
      'secureWrite:k',
      'secureRead:k',
      'secureDelete:k',
      'secureRead:k',
    ]);
  });

  test('engine validation runs before the channel (FR-003)', () async {
    var channelCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dev.zuraffa/agent_platform'), (call) async {
      channelCalls++;
      return null;
    });
    final platform = ZuraffaAgentMethodChannelPlatform();
    expect(() => platform.secureRead(' '), throwsArgumentError);
    expect(() => platform.secureWrite('', 'v'), throwsArgumentError);
    expect(channelCalls, 0);
  });
}
