/// The public runtime facade (FR-003, plan §Project Structure).
///
/// A thin, ergonomic entry over [AgentRuntimeFactory]: it holds the injected
/// configuration and ports and opens pi runtimes. It owns no agent loop, no
/// result model, and no policy — every capability is pi's or an installed
/// [ZuraffaExtension].
library;

import 'package:pi/pi.dart';

import '../config/agent_port_registry.dart';
import '../domain/entities/agent_runtime_config/agent_runtime_config.dart';
import '../extensions/zuraffa_extension.dart';
import '../pi/pi_runtime_adapter.dart';
import 'agent_runtime_factory.dart';

/// Opens pi runtimes behind the Zuraffa DI seam.
class ZuraffaAgent {
  final AgentRuntimeFactory _factory;

  /// Composes a facade from [config] and [ports]. [adapter] overrides the pi
  /// construction boundary (tests inject a fake; hosts take the default).
  ZuraffaAgent({
    required AgentRuntimeConfig config,
    required AgentPortRegistry ports,
    PiRuntimeAdapter? adapter,
  }) : _factory = AgentRuntimeFactory(
         config: config,
         ports: ports,
         adapter: adapter,
       );

  /// Opens the pi runtime and returns pi's own [Conversation].
  Future<Conversation> open({List<ZuraffaExtension> extensions = const []}) =>
      _factory.open(extensions: extensions);
}
