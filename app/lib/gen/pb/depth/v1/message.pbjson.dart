// This is a generated file - do not edit.
//
// Generated from depth/v1/message.proto.

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

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'server_msg_id', '3': 1, '4': 1, '5': 9, '10': 'serverMsgId'},
    {'1': 'client_msg_id', '3': 2, '4': 1, '5': 9, '10': 'clientMsgId'},
    {'1': 'conversation_id', '3': 3, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'sender_id', '3': 4, '4': 1, '5': 9, '10': 'senderId'},
    {'1': 'seq', '3': 5, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'content',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.MessageContent',
      '10': 'content'
    },
    {'1': 'timestamp', '3': 7, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEiIKDXNlcnZlcl9tc2dfaWQYASABKAlSC3NlcnZlck1zZ0lkEiIKDWNsaWVudF'
    '9tc2dfaWQYAiABKAlSC2NsaWVudE1zZ0lkEicKD2NvbnZlcnNhdGlvbl9pZBgDIAEoCVIOY29u'
    'dmVyc2F0aW9uSWQSGwoJc2VuZGVyX2lkGAQgASgJUghzZW5kZXJJZBIQCgNzZXEYBSABKANSA3'
    'NlcRIyCgdjb250ZW50GAYgASgLMhguZGVwdGgudjEuTWVzc2FnZUNvbnRlbnRSB2NvbnRlbnQS'
    'HAoJdGltZXN0YW1wGAcgASgDUgl0aW1lc3RhbXA=');

@$core.Deprecated('Use sendInputDescriptor instead')
const SendInput$json = {
  '1': 'SendInput',
  '2': [
    {'1': 'client_msg_id', '3': 1, '4': 1, '5': 9, '10': 'clientMsgId'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'content',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.MessageContent',
      '10': 'content'
    },
  ],
};

/// Descriptor for `SendInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendInputDescriptor = $convert.base64Decode(
    'CglTZW5kSW5wdXQSIgoNY2xpZW50X21zZ19pZBgBIAEoCVILY2xpZW50TXNnSWQSJwoPY29udm'
    'Vyc2F0aW9uX2lkGAIgASgJUg5jb252ZXJzYXRpb25JZBIyCgdjb250ZW50GAMgASgLMhguZGVw'
    'dGgudjEuTWVzc2FnZUNvbnRlbnRSB2NvbnRlbnQ=');

@$core.Deprecated('Use ackDescriptor instead')
const Ack$json = {
  '1': 'Ack',
  '2': [
    {'1': 'client_msg_id', '3': 1, '4': 1, '5': 9, '10': 'clientMsgId'},
    {'1': 'server_msg_id', '3': 2, '4': 1, '5': 9, '10': 'serverMsgId'},
    {'1': 'seq', '3': 3, '4': 1, '5': 3, '10': 'seq'},
    {'1': 'timestamp', '3': 4, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `Ack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ackDescriptor = $convert.base64Decode(
    'CgNBY2sSIgoNY2xpZW50X21zZ19pZBgBIAEoCVILY2xpZW50TXNnSWQSIgoNc2VydmVyX21zZ1'
    '9pZBgCIAEoCVILc2VydmVyTXNnSWQSEAoDc2VxGAMgASgDUgNzZXESHAoJdGltZXN0YW1wGAQg'
    'ASgDUgl0aW1lc3RhbXA=');
