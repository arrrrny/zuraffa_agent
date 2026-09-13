// The MethodChannel bridge: wire contract is pinned by spec 115 FR-005.
//
// channel: dev.zuraffa/agent_platform
// methods: getAgentHome, secureRead {key}, secureWrite {key, value},
//          secureDelete {key}; null reads mean "absent".

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

/// MethodChannel implementation of [AgentPlatform].
class ZuraffaAgentMethodChannelPlatform implements AgentPlatform {
  /// The pinned channel name (spec 115 FR-005).
  static const String channelName = 'dev.zuraffa/agent_platform';

  /// The channel — injectable for tests.
  final MethodChannel channel;

  ZuraffaAgentMethodChannelPlatform()
      : channel = const MethodChannel(channelName);

  /// Test-only constructor with a custom channel.
  ZuraffaAgentMethodChannelPlatform.forChannel(this.channel);

  @override
  Future<String?> getAgentHome() async {
    try {
      return await channel.invokeMethod<String>('getAgentHome');
    } on PlatformException catch (e) {
      throw SecureStore.map(
        'agentHome',
        operation: 'getAgentHome',
        cause: e,
      );
    }
  }

  @override
  Future<String?> secureRead(String key) async {
    SecureStore.validate(key);
    try {
      return await channel
          .invokeMethod<String>('secureRead', <String, Object>{'key': key});
    } on PlatformException catch (e) {
      throw SecureStore.map(key, operation: 'read', cause: e);
    }
  }

  @override
  Future<void> secureWrite(String key, String value) async {
    SecureStore.validate(key);
    try {
      await channel.invokeMethod<void>('secureWrite', <String, Object>{
        'key': key,
        'value': value,
      });
    } on PlatformException catch (e) {
      throw SecureStore.map(key, operation: 'write', cause: e);
    }
  }

  @override
  Future<void> secureDelete(String key) async {
    SecureStore.validate(key);
    try {
      await channel.invokeMethod<void>(
          'secureDelete', <String, Object>{'key': key});
    } on PlatformException catch (e) {
      throw SecureStore.map(key, operation: 'delete', cause: e);
    }
  }
}
