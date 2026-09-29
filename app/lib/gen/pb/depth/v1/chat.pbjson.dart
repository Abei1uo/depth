// This is a generated file - do not edit.
//
// Generated from depth/v1/chat.proto.

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

import 'package:protobuf/well_known_types/google/protobuf/empty.pbjson.dart'
    as $1;

import 'common.pbjson.dart' as $2;
import 'message.pbjson.dart' as $0;

@$core.Deprecated('Use conversationTypeDescriptor instead')
const ConversationType$json = {
  '1': 'ConversationType',
  '2': [
    {'1': 'CONVERSATION_TYPE_DIRECT', '2': 0},
    {'1': 'CONVERSATION_TYPE_GROUP', '2': 1},
  ],
};

/// Descriptor for `ConversationType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List conversationTypeDescriptor = $convert.base64Decode(
    'ChBDb252ZXJzYXRpb25UeXBlEhwKGENPTlZFUlNBVElPTl9UWVBFX0RJUkVDVBAAEhsKF0NPTl'
    'ZFUlNBVElPTl9UWVBFX0dST1VQEAE=');

@$core.Deprecated('Use memberRoleDescriptor instead')
const MemberRole$json = {
  '1': 'MemberRole',
  '2': [
    {'1': 'MEMBER_ROLE_MEMBER', '2': 0},
    {'1': 'MEMBER_ROLE_OWNER', '2': 2},
  ],
};

/// Descriptor for `MemberRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List memberRoleDescriptor = $convert.base64Decode(
    'CgpNZW1iZXJSb2xlEhYKEk1FTUJFUl9ST0xFX01FTUJFUhAAEhUKEU1FTUJFUl9ST0xFX09XTk'
    'VSEAI=');

@$core.Deprecated('Use conversationDescriptor instead')
const Conversation$json = {
  '1': 'Conversation',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.depth.v1.ConversationType',
      '10': 'type'
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'avatar_url', '3': 4, '4': 1, '5': 9, '10': 'avatarUrl'},
    {'1': 'owner_id', '3': 5, '4': 1, '5': 9, '10': 'ownerId'},
    {'1': 'member_ids', '3': 6, '4': 3, '5': 9, '10': 'memberIds'},
  ],
};

/// Descriptor for `Conversation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationDescriptor = $convert.base64Decode(
    'CgxDb252ZXJzYXRpb24SDgoCaWQYASABKAlSAmlkEi4KBHR5cGUYAiABKA4yGi5kZXB0aC52MS'
    '5Db252ZXJzYXRpb25UeXBlUgR0eXBlEhIKBG5hbWUYAyABKAlSBG5hbWUSHQoKYXZhdGFyX3Vy'
    'bBgEIAEoCVIJYXZhdGFyVXJsEhkKCG93bmVyX2lkGAUgASgJUgdvd25lcklkEh0KCm1lbWJlcl'
    '9pZHMYBiADKAlSCW1lbWJlcklkcw==');

@$core.Deprecated('Use createDirectRequestDescriptor instead')
const CreateDirectRequest$json = {
  '1': 'CreateDirectRequest',
  '2': [
    {'1': 'peer_id', '3': 1, '4': 1, '5': 9, '10': 'peerId'},
  ],
};

/// Descriptor for `CreateDirectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createDirectRequestDescriptor =
    $convert.base64Decode(
        'ChNDcmVhdGVEaXJlY3RSZXF1ZXN0EhcKB3BlZXJfaWQYASABKAlSBnBlZXJJZA==');

@$core.Deprecated('Use createGroupRequestDescriptor instead')
const CreateGroupRequest$json = {
  '1': 'CreateGroupRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'member_ids', '3': 2, '4': 3, '5': 9, '10': 'memberIds'},
  ],
};

/// Descriptor for `CreateGroupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createGroupRequestDescriptor = $convert.base64Decode(
    'ChJDcmVhdGVHcm91cFJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIdCgptZW1iZXJfaWRzGA'
    'IgAygJUgltZW1iZXJJZHM=');

@$core.Deprecated('Use conversationIdResponseDescriptor instead')
const ConversationIdResponse$json = {
  '1': 'ConversationIdResponse',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `ConversationIdResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationIdResponseDescriptor =
    $convert.base64Decode(
        'ChZDb252ZXJzYXRpb25JZFJlc3BvbnNlEicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udm'
        'Vyc2F0aW9uSWQ=');

@$core.Deprecated('Use listConversationsResponseDescriptor instead')
const ListConversationsResponse$json = {
  '1': 'ListConversationsResponse',
  '2': [
    {
      '1': 'conversations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.depth.v1.Conversation',
      '10': 'conversations'
    },
  ],
};

/// Descriptor for `ListConversationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConversationsResponseDescriptor =
    $convert.base64Decode(
        'ChlMaXN0Q29udmVyc2F0aW9uc1Jlc3BvbnNlEjwKDWNvbnZlcnNhdGlvbnMYASADKAsyFi5kZX'
        'B0aC52MS5Db252ZXJzYXRpb25SDWNvbnZlcnNhdGlvbnM=');

@$core.Deprecated('Use listMessagesRequestDescriptor instead')
const ListMessagesRequest$json = {
  '1': 'ListMessagesRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'before_seq', '3': 2, '4': 1, '5': 3, '10': 'beforeSeq'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ListMessagesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMessagesRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0TWVzc2FnZXNSZXF1ZXN0EicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2'
    'F0aW9uSWQSHQoKYmVmb3JlX3NlcRgCIAEoA1IJYmVmb3JlU2VxEhQKBWxpbWl0GAMgASgFUgVs'
    'aW1pdA==');

@$core.Deprecated('Use listMessagesResponseDescriptor instead')
const ListMessagesResponse$json = {
  '1': 'ListMessagesResponse',
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

/// Descriptor for `ListMessagesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMessagesResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0TWVzc2FnZXNSZXNwb25zZRItCghtZXNzYWdlcxgBIAMoCzIRLmRlcHRoLnYxLk1lc3'
    'NhZ2VSCG1lc3NhZ2Vz');

const $core.Map<$core.String, $core.dynamic> ChatServiceBase$json = {
  '1': 'ChatService',
  '2': [
    {
      '1': 'CreateDirect',
      '2': '.depth.v1.CreateDirectRequest',
      '3': '.depth.v1.ConversationIdResponse'
    },
    {
      '1': 'CreateGroup',
      '2': '.depth.v1.CreateGroupRequest',
      '3': '.depth.v1.ConversationIdResponse'
    },
    {
      '1': 'ListConversations',
      '2': '.google.protobuf.Empty',
      '3': '.depth.v1.ListConversationsResponse'
    },
    {
      '1': 'ListMessages',
      '2': '.depth.v1.ListMessagesRequest',
      '3': '.depth.v1.ListMessagesResponse'
    },
  ],
};

@$core.Deprecated('Use chatServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    ChatServiceBase$messageJson = {
  '.depth.v1.CreateDirectRequest': CreateDirectRequest$json,
  '.depth.v1.ConversationIdResponse': ConversationIdResponse$json,
  '.depth.v1.CreateGroupRequest': CreateGroupRequest$json,
  '.google.protobuf.Empty': $1.Empty$json,
  '.depth.v1.ListConversationsResponse': ListConversationsResponse$json,
  '.depth.v1.Conversation': Conversation$json,
  '.depth.v1.ListMessagesRequest': ListMessagesRequest$json,
  '.depth.v1.ListMessagesResponse': ListMessagesResponse$json,
  '.depth.v1.Message': $0.Message$json,
  '.depth.v1.MessageContent': $2.MessageContent$json,
};

/// Descriptor for `ChatService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List chatServiceDescriptor = $convert.base64Decode(
    'CgtDaGF0U2VydmljZRJPCgxDcmVhdGVEaXJlY3QSHS5kZXB0aC52MS5DcmVhdGVEaXJlY3RSZX'
    'F1ZXN0GiAuZGVwdGgudjEuQ29udmVyc2F0aW9uSWRSZXNwb25zZRJNCgtDcmVhdGVHcm91cBIc'
    'LmRlcHRoLnYxLkNyZWF0ZUdyb3VwUmVxdWVzdBogLmRlcHRoLnYxLkNvbnZlcnNhdGlvbklkUm'
    'VzcG9uc2USUAoRTGlzdENvbnZlcnNhdGlvbnMSFi5nb29nbGUucHJvdG9idWYuRW1wdHkaIy5k'
    'ZXB0aC52MS5MaXN0Q29udmVyc2F0aW9uc1Jlc3BvbnNlEk0KDExpc3RNZXNzYWdlcxIdLmRlcH'
    'RoLnYxLkxpc3RNZXNzYWdlc1JlcXVlc3QaHi5kZXB0aC52MS5MaXN0TWVzc2FnZXNSZXNwb25z'
    'ZQ==');
