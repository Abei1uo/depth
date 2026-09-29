// This is a generated file - do not edit.
//
// Generated from depth/v1/call.proto.

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

@$core.Deprecated('Use callStateDescriptor instead')
const CallState$json = {
  '1': 'CallState',
  '2': [
    {'1': 'CALL_STATE_UNSPECIFIED', '2': 0},
    {'1': 'CALL_STATE_INVITING', '2': 1},
    {'1': 'CALL_STATE_RINGING', '2': 2},
    {'1': 'CALL_STATE_CONNECTING', '2': 3},
    {'1': 'CALL_STATE_CONNECTED', '2': 4},
    {'1': 'CALL_STATE_ENDED', '2': 5},
    {'1': 'CALL_STATE_REJECTED', '2': 6},
    {'1': 'CALL_STATE_MISSED', '2': 7},
  ],
};

/// Descriptor for `CallState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List callStateDescriptor = $convert.base64Decode(
    'CglDYWxsU3RhdGUSGgoWQ0FMTF9TVEFURV9VTlNQRUNJRklFRBAAEhcKE0NBTExfU1RBVEVfSU'
    '5WSVRJTkcQARIWChJDQUxMX1NUQVRFX1JJTkdJTkcQAhIZChVDQUxMX1NUQVRFX0NPTk5FQ1RJ'
    'TkcQAxIYChRDQUxMX1NUQVRFX0NPTk5FQ1RFRBAEEhQKEENBTExfU1RBVEVfRU5ERUQQBRIXCh'
    'NDQUxMX1NUQVRFX1JFSkVDVEVEEAYSFQoRQ0FMTF9TVEFURV9NSVNTRUQQBw==');

@$core.Deprecated('Use callInviteDescriptor instead')
const CallInvite$json = {
  '1': 'CallInvite',
  '2': [
    {'1': 'call_id', '3': 1, '4': 1, '5': 9, '10': 'callId'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'from_user_id', '3': 3, '4': 1, '5': 9, '10': 'fromUserId'},
    {'1': 'to_user_ids', '3': 4, '4': 3, '5': 9, '10': 'toUserIds'},
    {'1': 'video', '3': 5, '4': 1, '5': 8, '10': 'video'},
  ],
};

/// Descriptor for `CallInvite`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callInviteDescriptor = $convert.base64Decode(
    'CgpDYWxsSW52aXRlEhcKB2NhbGxfaWQYASABKAlSBmNhbGxJZBInCg9jb252ZXJzYXRpb25faW'
    'QYAiABKAlSDmNvbnZlcnNhdGlvbklkEiAKDGZyb21fdXNlcl9pZBgDIAEoCVIKZnJvbVVzZXJJ'
    'ZBIeCgt0b191c2VyX2lkcxgEIAMoCVIJdG9Vc2VySWRzEhQKBXZpZGVvGAUgASgIUgV2aWRlbw'
    '==');

@$core.Deprecated('Use callSignalDescriptor instead')
const CallSignal$json = {
  '1': 'CallSignal',
  '2': [
    {'1': 'call_id', '3': 1, '4': 1, '5': 9, '10': 'callId'},
    {'1': 'from_user_id', '3': 2, '4': 1, '5': 9, '10': 'fromUserId'},
    {'1': 'sdp', '3': 3, '4': 1, '5': 9, '10': 'sdp'},
    {'1': 'sdp_type', '3': 4, '4': 1, '5': 9, '10': 'sdpType'},
  ],
};

/// Descriptor for `CallSignal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callSignalDescriptor = $convert.base64Decode(
    'CgpDYWxsU2lnbmFsEhcKB2NhbGxfaWQYASABKAlSBmNhbGxJZBIgCgxmcm9tX3VzZXJfaWQYAi'
    'ABKAlSCmZyb21Vc2VySWQSEAoDc2RwGAMgASgJUgNzZHASGQoIc2RwX3R5cGUYBCABKAlSB3Nk'
    'cFR5cGU=');

@$core.Deprecated('Use iceCandidateDescriptor instead')
const IceCandidate$json = {
  '1': 'IceCandidate',
  '2': [
    {'1': 'call_id', '3': 1, '4': 1, '5': 9, '10': 'callId'},
    {'1': 'from_user_id', '3': 2, '4': 1, '5': 9, '10': 'fromUserId'},
    {'1': 'candidate', '3': 3, '4': 1, '5': 9, '10': 'candidate'},
    {'1': 'sdp_mid', '3': 4, '4': 1, '5': 9, '10': 'sdpMid'},
    {'1': 'sdp_mline_index', '3': 5, '4': 1, '5': 5, '10': 'sdpMlineIndex'},
  ],
};

/// Descriptor for `IceCandidate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List iceCandidateDescriptor = $convert.base64Decode(
    'CgxJY2VDYW5kaWRhdGUSFwoHY2FsbF9pZBgBIAEoCVIGY2FsbElkEiAKDGZyb21fdXNlcl9pZB'
    'gCIAEoCVIKZnJvbVVzZXJJZBIcCgljYW5kaWRhdGUYAyABKAlSCWNhbmRpZGF0ZRIXCgdzZHBf'
    'bWlkGAQgASgJUgZzZHBNaWQSJgoPc2RwX21saW5lX2luZGV4GAUgASgFUg1zZHBNbGluZUluZG'
    'V4');

@$core.Deprecated('Use callControlDescriptor instead')
const CallControl$json = {
  '1': 'CallControl',
  '2': [
    {'1': 'call_id', '3': 1, '4': 1, '5': 9, '10': 'callId'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'from_user_id', '3': 3, '4': 1, '5': 9, '10': 'fromUserId'},
    {
      '1': 'state',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.depth.v1.CallState',
      '10': 'state'
    },
    {'1': 'reason', '3': 5, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `CallControl`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callControlDescriptor = $convert.base64Decode(
    'CgtDYWxsQ29udHJvbBIXCgdjYWxsX2lkGAEgASgJUgZjYWxsSWQSJwoPY29udmVyc2F0aW9uX2'
    'lkGAIgASgJUg5jb252ZXJzYXRpb25JZBIgCgxmcm9tX3VzZXJfaWQYAyABKAlSCmZyb21Vc2Vy'
    'SWQSKQoFc3RhdGUYBCABKA4yEy5kZXB0aC52MS5DYWxsU3RhdGVSBXN0YXRlEhYKBnJlYXNvbh'
    'gFIAEoCVIGcmVhc29u');

@$core.Deprecated('Use callEventDescriptor instead')
const CallEvent$json = {
  '1': 'CallEvent',
  '2': [
    {
      '1': 'invite',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.CallInvite',
      '9': 0,
      '10': 'invite'
    },
    {
      '1': 'signal',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.CallSignal',
      '9': 0,
      '10': 'signal'
    },
    {
      '1': 'candidate',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.IceCandidate',
      '9': 0,
      '10': 'candidate'
    },
    {
      '1': 'control',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.depth.v1.CallControl',
      '9': 0,
      '10': 'control'
    },
  ],
  '8': [
    {'1': 'kind'},
  ],
};

/// Descriptor for `CallEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callEventDescriptor = $convert.base64Decode(
    'CglDYWxsRXZlbnQSLgoGaW52aXRlGAEgASgLMhQuZGVwdGgudjEuQ2FsbEludml0ZUgAUgZpbn'
    'ZpdGUSLgoGc2lnbmFsGAIgASgLMhQuZGVwdGgudjEuQ2FsbFNpZ25hbEgAUgZzaWduYWwSNgoJ'
    'Y2FuZGlkYXRlGAMgASgLMhYuZGVwdGgudjEuSWNlQ2FuZGlkYXRlSABSCWNhbmRpZGF0ZRIxCg'
    'djb250cm9sGAQgASgLMhUuZGVwdGgudjEuQ2FsbENvbnRyb2xIAFIHY29udHJvbEIGCgRraW5k');
