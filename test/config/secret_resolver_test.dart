// spec 107 (issue #121) — SecretResolver: credential-source interface + stub.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/config/secret_resolver.dart';

void main() {
  group('spec 107 — SecretResolver', () {
    test(
      'U11: the stub resolver reports absence for all three sources',
      () async {
        final resolver = NullSecretResolver();
        expect(await resolver.fromEnv('KIMI_API_KEY'), isNull);
        expect(await resolver.fromFile('/run/secrets/kimi'), isNull);
        expect(
          await resolver.fromVault(Uri.parse('vault://secrets/kimi')),
          isNull,
        );
      },
    );
  });
}
