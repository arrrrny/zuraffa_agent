// Provider configuration — single source of truth.
//
// This file previously defined a hand-written duplicate ProviderConfig plus a
// ProviderResolver / ResolvedModel pair. Those were removed during production
// hardening: the canonical, spec-exact ProviderConfig value object lives at
// domain/entities/provider_config/provider_config.dart (spec 052) and is the
// single ProviderConfig type for the whole package. Provider fallback/resolution
// is handled by the FallbackChain provider (spec 037 / issue #7).
//
// This file now simply re-exports the canonical entity so the public API
// `package:zuraffa_agent/providers.dart` continues to resolve ProviderConfig to
// the single correct definition.

export 'domain/entities/provider_config/provider_config.dart';
