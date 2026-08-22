/// Auth Callback — callback for SSE Bearer token rotation.
///
/// Called when the SSE transport receives a 401 Unauthorized response,
/// allowing the token to be refreshed before retrying the request.
library;

/// Signature for auth callback functions.
///
/// Should return a new valid Bearer token.
/// Throws if token cannot be refreshed.
typedef AuthCallback = Future<String> Function();