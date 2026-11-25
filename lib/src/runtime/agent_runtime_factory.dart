/// The thin runtime factory/facade (FR-003, contracts/agent-runtime-factory.md).
///
/// Validates what composition can leave wrong (non-empty provider/model),
/// composes the installed extensions into pi hooks, drives the lifecycle port,
/// constructs through [PiRuntimeAdapter], and returns pi's own [Conversation].
/// It carries no parallel result model and translates no pi failure into a
/// wrapper taxonomy.
library;

import 'package:pi/pi.dart';

import '../config/agent_port_registry.dart';
import '../domain/entities/agent_runtime_config/agent_runtime_config.dart';
import '../extensions/extension_bootstrap.dart';
import '../extensions/zuraffa_extension.dart';
import '../pi/pi_runtime_adapter.dart';

/// Opens pi runtimes from injected configuration.
class AgentRuntimeFactory {
  final AgentRuntimeConfig config;
  final AgentPortRegistry ports;
  final PiRuntimeAdapter _adapter;
  final ExtensionBootstrap _bootstrap;

  AgentRuntimeFactory({
    required this.config,
    required this.ports,
    PiRuntimeAdapter? adapter,
    ExtensionBootstrap? bootstrap,
  }) : _adapter = adapter ?? const DefaultPiRuntimeAdapter(),
       _bootstrap = bootstrap ?? const ExtensionBootstrap() {
    _validateConfig();
  }

  void _validateConfig() {
    if (config.modelProvider.isEmpty) {
      throw ArgumentError.value(
        config.modelProvider,
        'config.modelProvider',
        'must not be empty',
      );
    }
    if (config.modelId.isEmpty) {
      throw ArgumentError.value(
        config.modelId,
        'config.modelId',
        'must not be empty',
      );
    }
  }

  /// Opens the pi runtime and returns pi's own [Conversation].
  ///
  /// Tool names in [AgentRuntimeConfig] are not validated against a known set:
  /// pi owns the tool registry and this package has no tool catalog to check
  /// against (data-model.md).
  Future<Conversation> open({
    List<ZuraffaExtension> extensions = const [],
  }) async {
    final hooks = _bootstrap.compose(extensions);
    await ports.lifecycle.onOpening();
    try {
      final conversation = await _adapter.open(config, ports, hooks);
      await ports.lifecycle.onOpened();
      return conversation;
    } catch (error) {
      // A failed open yields `closed` with the pi error surfaced as-is
      // (data-model.md state transitions); no wrapper-authored outcome type.
      await ports.lifecycle.onClosed();
      rethrow;
    }
  }
}
