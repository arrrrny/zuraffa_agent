/// Host-injection port for lifecycle hooks (FR-006).
///
/// The runtime calls these around open/close so the host can run setup/teardown
/// (state transitions in data-model.md: unopened -> opening -> open -> closing
/// -> closed). Tests use [InMemoryAgentLifecyclePort].
library;

/// Receives the runtime's lifecycle callbacks.
abstract class AgentLifecyclePort {
  Future<void> onOpening();
  Future<void> onOpened();
  Future<void> onClosing();
  Future<void> onClosed();
}

/// Pure-Dart in-memory [AgentLifecyclePort] that records the callback order.
class InMemoryAgentLifecyclePort implements AgentLifecyclePort {
  final List<String> calls = [];

  @override
  Future<void> onOpening() async => calls.add('opening');

  @override
  Future<void> onOpened() async => calls.add('opened');

  @override
  Future<void> onClosing() async => calls.add('closing');

  @override
  Future<void> onClosed() async => calls.add('closed');
}
