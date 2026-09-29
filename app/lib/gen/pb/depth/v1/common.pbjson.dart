// This is a generated file - do not edit.
//
// Generated from depth/v1/common.proto.

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

@$core.Deprecated('Use messageTypeDescriptor instead')
const MessageType$json = {
  '1': 'MessageType',
  '2': [
    {'1': 'MESSAGE_TYPE_TEXT', '2': 0},
    {'1': 'MESSAGE_TYPE_IMAGE', '2': 1},
    {'1': 'MESSAGE_TYPE_FILE', '2': 2},
    {'1': 'MESSAGE_TYPE_VOICE', '2': 3},
    {'1': 'MESSAGE_TYPE_SYS', '2': 4},
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlVHlwZRIVChFNRVNTQUdFX1RZUEVfVEVYVBAAEhYKEk1FU1NBR0VfVFlQRV9JTU'
    'FHRRABEhUKEU1FU1NBR0VfVFlQRV9GSUxFEAISFgoSTUVTU0FHRV9UWVBFX1ZPSUNFEAMSFAoQ'
    'TUVTU0FHRV9UWVBFX1NZUxAE');

@$core.Deprecated('Use messageContentDescriptor instead')
const MessageContent$json = {
  '1': 'MessageContent',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.depth.v1.MessageType',
      '10': 'type'
    },
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'media_url', '3': 3, '4': 1, '5': 9, '10': 'mediaUrl'},
    {'1': 'thumb_url', '3': 4, '4': 1, '5': 9, '10': 'thumbUrl'},
    {'1': 'size', '3': 5, '4': 1, '5': 3, '10': 'size'},
  ],
};

/// Descriptor for `MessageContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageContentDescriptor = $convert.base64Decode(
    'Cg5NZXNzYWdlQ29udGVudBIpCgR0eXBlGAEgASgOMhUuZGVwdGgudjEuTWVzc2FnZVR5cGVSBH'
    'R5cGUSEgoEdGV4dBgCIAEoCVIEdGV4dBIbCgltZWRpYV91cmwYAyABKAlSCG1lZGlhVXJsEhsK'
    'CXRodW1iX3VybBgEIAEoCVIIdGh1bWJVcmwSEgoEc2l6ZRgFIAEoA1IEc2l6ZQ==');
