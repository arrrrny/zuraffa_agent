/// Host-injection port for egress / HTTP (FR-006).
///
/// pi's provider transport is pi's own; this port exists so a host can route
/// any wrapper-initiated traffic through its own egress (proxy, allowlist,
/// audit). [AgentHttpRequest] / [AgentHttpResponse] are this port's own value
/// types because pi has no HTTP seam to borrow.
library;

/// A minimal HTTP request the wrapper routes through the host's egress.
class AgentHttpRequest {
  final String method;
  final String url;
  final Map<String, String> headers;
  final List<int>? body;

  const AgentHttpRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
  });
}

/// A minimal HTTP response returned by the host's egress.
class AgentHttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final List<int> body;

  const AgentHttpResponse({
    required this.statusCode,
    this.headers = const {},
    this.body = const [],
  });
}

/// Routes wrapper-initiated HTTP traffic through the host's egress.
abstract class AgentEgressPort {
  Future<AgentHttpResponse> send(AgentHttpRequest request);
}

/// Pure-Dart in-memory [AgentEgressPort] that records requests and returns a
/// scripted response.
class InMemoryAgentEgressPort implements AgentEgressPort {
  final List<AgentHttpRequest> requests = [];
  AgentHttpResponse response;

  InMemoryAgentEgressPort({
    this.response = const AgentHttpResponse(statusCode: 200),
  });

  @override
  Future<AgentHttpResponse> send(AgentHttpRequest request) async {
    requests.add(request);
    return response;
  }
}
