// This is a generated file - do not edit.
//
// Generated from depth/v1/event.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use syncRequestDescriptor instead')
const SyncRequest$json = {
  '1': 'SyncRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'last_seq', '3': 2, '4': 1, '5': 3, '10': 'lastSeq'},
  ],
};

/// Descriptor for `SyncRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncRequestDescriptor = $convert.base64Decode(
    'CgtTeW5jUmVxdWVzdBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEh'
    'kKCGxhc3Rfc2VxGAIgASgDUgdsYXN0U2Vx');

@$core.Deprecated('Use syncResultDescriptor instead')
const SyncResult$json = {
  '1': 'SyncResult',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.depth.v1.Message',
      '10': 'messages'
    },
  ],
};

/// Descriptor for `SyncResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncResultDescriptor = $convert.base64Decode(
    'CgpTeW5jUmVzdWx0Ei0KCG1lc3NhZ2VzGAEgAygLMhEuZGVwdGgudjEuTWVzc2FnZVIIbWVzc2'
    'FnZXM=');

@$core.Deprecated('Use markReadDescriptor instead')
const MarkRead$json = {
  '1': 'MarkRead',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'max_seq', '3': 2, '4': 1, '5': 3, '10': 'maxSeq'},
  ],
};

/// Descriptor for `MarkRead`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markReadDescriptor = $convert.base64Decode(
    'CghNYXJrUmVhZBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEhcKB2'
    '1heF9zZXEYAiABKANSBm1heFNlcQ==');

@$core.Deprecated('Use typingDescriptor instead')
const Typing$json = {
  '1': 'Typing',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'typing', '3': 2, '4': 1, '5': 8, '10': 'typing'},
  ],
};

/// Descriptor for `Typing`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typingDescriptor = $convert.base64Decode(
    'CgZUeXBpbmcSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYXRpb25JZBIWCgZ0eX'
    'BpbmcYAiABKAhSBnR5cGluZw==');

@$core.Deprecated('Use presenceUpdateDescriptor instead')
const PresenceUpdate$json = {
  '1': 'PresenceUpdate',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'online', '3': 2, '4': 1, '5': 8, '10': 'online'},
    {'1': 'last_seen', '3': 3, '4': 1, '5': 3, '10': 'lastSeen'},
  ],
};

/// Descriptor for `PresenceUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceUpdateDescriptor = $convert.base64Decode(
    'Cg5QcmVzZW5jZVVwZGF0ZRIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSFgoGb25saW5lGAIgAS'
    'gIUgZvbmxpbmUSGwoJbGFzdF9zZWVuGAMgASgDUghsYXN0U2Vlbg==');

@$core.Deprecated('Use errorEventDescriptor instead')
const ErrorEvent$json = {
  '1': 'ErrorEvent',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'related_client_msg_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'relatedClientMsgId'
    },
  ],
};

/// Descriptor for `ErrorEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorEventDescriptor = $convert.base64Decode(
    'CgpFcnJvckV2ZW50EhIKBGNvZGUYASABKAlSBGNvZGUSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2'
    'FnZRIxChVyZWxhdGVkX2NsaWVudF9tc2dfaWQYAyABKAlSEnJlbGF0ZWRDbGllbnRNc2dJZA==');

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {
      '1': 'send_message',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.SendInput',
      '9': 0,
      '10': 'sendMessage'
    },
    {
      '1': 'sync',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.SyncRequest',
      '9': 0,
      '10': 'sync'
    },
    {
      '1': 'mark_read',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.MarkRead',
      '9': 0,
      '10': 'markRead'
    },
    {
      '1': 'typing',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.Typing',
      '9': 0,
      '10': 'typing'
    },
    {
      '1': 'new_message',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.Message',
      '9': 0,
      '10': 'newMessage'
    },
    {
      '1': 'msg_ack',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.Ack',
      '9': 0,
      '10': 'msgAck'
    },
    {
      '1': 'sync_result',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.SyncResult',
      '9': 0,
      '10': 'syncResult'
    },
    {
      '1': 'presence_update',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.PresenceUpdate',
      '9': 0,
      '10': 'presenceUpdate'
    },
    {
      '1': 'error',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.ErrorEvent',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'kind'},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBISCgR0eXBlGAEgASgJUgR0eXBlEjgKDHNlbmRfbWVzc2FnZRgCIAEoCzITLmRlcH'
    'RoLnYxLlNlbmRJbnB1dEgAUgtzZW5kTWVzc2FnZRIrCgRzeW5jGAMgASgLMhUuZGVwdGgudjEu'
    'U3luY1JlcXVlc3RIAFIEc3luYxIxCgltYXJrX3JlYWQYBCABKAsyEi5kZXB0aC52MS5NYXJrUm'
    'VhZEgAUghtYXJrUmVhZBIqCgZ0eXBpbmcYBSABKAsyEC5kZXB0aC52MS5UeXBpbmdIAFIGdHlw'
    'aW5nEjQKC25ld19tZXNzYWdlGAYgASgLMhEuZGVwdGgudjEuTWVzc2FnZUgAUgpuZXdNZXNzYW'
    'dlEigKB21zZ19hY2sYByABKAsyDS5kZXB0aC52MS5BY2tIAFIGbXNnQWNrEjcKC3N5bmNfcmVz'
    'dWx0GAggASgLMhQuZGVwdGgudjEuU3luY1Jlc3VsdEgAUgpzeW5jUmVzdWx0EkMKD3ByZXNlbm'
    'NlX3VwZGF0ZRgJIAEoCzIYLmRlcHRoLnYxLlByZXNlbmNlVXBkYXRlSABSDnByZXNlbmNlVXBk'
    'YXRlEiwKBWVycm9yGAogASgLMhQuZGVwdGgudjEuRXJyb3JFdmVudEgAUgVlcnJvckIGCgRraW'
    '5k');
