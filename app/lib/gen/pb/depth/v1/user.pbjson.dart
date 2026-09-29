// This is a generated file - do not edit.
//
// Generated from depth/v1/user.proto.

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
    as $0;

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'nickname', '3': 3, '4': 1, '5': 9, '10': 'nickname'},
    {'1': 'avatar_url', '3': 4, '4': 1, '5': 9, '10': 'avatarUrl'},
    {'1': 'created_at', '3': 5, '4': 1, '5': 3, '10': 'createdAt'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEg4KAmlkGAEgASgJUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5hbWUSGgoIbm'
    'lja25hbWUYAyABKAlSCG5pY2tuYW1lEh0KCmF2YXRhcl91cmwYBCABKAlSCWF2YXRhclVybBId'
    'CgpjcmVhdGVkX2F0GAUgASgDUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use authSessionDescriptor instead')
const AuthSession$json = {
  '1': 'AuthSession',
  '2': [
    {'1': 'access_token', '3': 1, '4': 1, '5': 9, '10': 'accessToken'},
    {'1': 'refresh_token', '3': 2, '4': 1, '5': 9, '10': 'refreshToken'},
    {'1': 'expires_at', '3': 3, '4': 1, '5': 3, '10': 'expiresAt'},
    {'1': 'user', '3': 4, '4': 1, '5': 11, '6': '.depth.v1.User', '10': 'user'},
  ],
};

/// Descriptor for `AuthSession`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authSessionDescriptor = $convert.base64Decode(
    'CgtBdXRoU2Vzc2lvbhIhCgxhY2Nlc3NfdG9rZW4YASABKAlSC2FjY2Vzc1Rva2VuEiMKDXJlZn'
    'Jlc2hfdG9rZW4YAiABKAlSDHJlZnJlc2hUb2tlbhIdCgpleHBpcmVzX2F0GAMgASgDUglleHBp'
    'cmVzQXQSIgoEdXNlchgEIAEoCzIOLmRlcHRoLnYxLlVzZXJSBHVzZXI=');

@$core.Deprecated('Use registerRequestDescriptor instead')
const RegisterRequest$json = {
  '1': 'RegisterRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'nickname', '3': 2, '4': 1, '5': 9, '10': 'nickname'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `RegisterRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerRequestDescriptor = $convert.base64Decode(
    'Cg9SZWdpc3RlclJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCG5pY2tuYW'
    '1lGAIgASgJUghuaWNrbmFtZRIaCghwYXNzd29yZBgDIAEoCVIIcGFzc3dvcmQ=');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3JkGA'
    'IgASgJUghwYXNzd29yZA==');

@$core.Deprecated('Use refreshRequestDescriptor instead')
const RefreshRequest$json = {
  '1': 'RefreshRequest',
  '2': [
    {'1': 'refresh_token', '3': 1, '4': 1, '5': 9, '10': 'refreshToken'},
  ],
};

/// Descriptor for `RefreshRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshRequestDescriptor = $convert.base64Decode(
    'Cg5SZWZyZXNoUmVxdWVzdBIjCg1yZWZyZXNoX3Rva2VuGAEgASgJUgxyZWZyZXNoVG9rZW4=');

@$core.Deprecated('Use searchUsersRequestDescriptor instead')
const SearchUsersRequest$json = {
  '1': 'SearchUsersRequest',
  '2': [
    {'1': 'q', '3': 1, '4': 1, '5': 9, '10': 'q'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `SearchUsersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchUsersRequestDescriptor = $convert.base64Decode(
    'ChJTZWFyY2hVc2Vyc1JlcXVlc3QSDAoBcRgBIAEoCVIBcRIUCgVsaW1pdBgCIAEoBVIFbGltaX'
    'Q=');

@$core.Deprecated('Use searchUsersResponseDescriptor instead')
const SearchUsersResponse$json = {
  '1': 'SearchUsersResponse',
  '2': [
    {
      '1': 'users',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.depth.v1.User',
      '10': 'users'
    },
  ],
};

/// Descriptor for `SearchUsersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchUsersResponseDescriptor = $convert.base64Decode(
    'ChNTZWFyY2hVc2Vyc1Jlc3BvbnNlEiQKBXVzZXJzGAEgAygLMg4uZGVwdGgudjEuVXNlclIFdX'
    'NlcnM=');

const $core.Map<$core.String, $core.dynamic> UserServiceBase$json = {
  '1': 'UserService',
  '2': [
    {'1': 'Me', '2': '.google.protobuf.Empty', '3': '.depth.v1.User'},
    {
      '1': 'Search',
      '2': '.depth.v1.SearchUsersRequest',
      '3': '.depth.v1.SearchUsersResponse'
    },
    {
      '1': 'Register',
      '2': '.depth.v1.RegisterRequest',
      '3': '.depth.v1.AuthSession'
    },
    {'1': 'Login', '2': '.depth.v1.LoginRequest', '3': '.depth.v1.AuthSession'},
    {
      '1': 'Refresh',
      '2': '.depth.v1.RefreshRequest',
      '3': '.depth.v1.AuthSession'
    },
  ],
};

@$core.Deprecated('Use userServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    UserServiceBase$messageJson = {
  '.google.protobuf.Empty': $0.Empty$json,
  '.depth.v1.User': User$json,
  '.depth.v1.SearchUsersRequest': SearchUsersRequest$json,
  '.depth.v1.SearchUsersResponse': SearchUsersResponse$json,
  '.depth.v1.RegisterRequest': RegisterRequest$json,
  '.depth.v1.AuthSession': AuthSession$json,
  '.depth.v1.LoginRequest': LoginRequest$json,
  '.depth.v1.RefreshRequest': RefreshRequest$json,
};

/// Descriptor for `UserService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List userServiceDescriptor = $convert.base64Decode(
    'CgtVc2VyU2VydmljZRIsCgJNZRIWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eRoOLmRlcHRoLnYxLl'
    'VzZXISRQoGU2VhcmNoEhwuZGVwdGgudjEuU2VhcmNoVXNlcnNSZXF1ZXN0Gh0uZGVwdGgudjEu'
    'U2VhcmNoVXNlcnNSZXNwb25zZRI8CghSZWdpc3RlchIZLmRlcHRoLnYxLlJlZ2lzdGVyUmVxdW'
    'VzdBoVLmRlcHRoLnYxLkF1dGhTZXNzaW9uEjYKBUxvZ2luEhYuZGVwdGgudjEuTG9naW5SZXF1'
    'ZXN0GhUuZGVwdGgudjEuQXV0aFNlc3Npb24SOgoHUmVmcmVzaBIYLmRlcHRoLnYxLlJlZnJlc2'
    'hSZXF1ZXN0GhUuZGVwdGgudjEuQXV0aFNlc3Npb24=');
