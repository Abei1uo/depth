// This is a generated file - do not edit.
//
// Generated from depth/v1/user.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $0;

import 'user.pb.dart' as $1;
import 'user.pbjson.dart';

export 'user.pb.dart';

abstract class UserServiceBase extends $pb.GeneratedService {
  $async.Future<$1.User> me($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$1.SearchUsersResponse> search(
      $pb.ServerContext ctx, $1.SearchUsersRequest request);
  $async.Future<$1.AuthSession> register(
      $pb.ServerContext ctx, $1.RegisterRequest request);
  $async.Future<$1.AuthSession> login(
      $pb.ServerContext ctx, $1.LoginRequest request);
  $async.Future<$1.AuthSession> refresh(
      $pb.ServerContext ctx, $1.RefreshRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'Me':
        return $0.Empty();
      case 'Search':
        return $1.SearchUsersRequest();
      case 'Register':
        return $1.RegisterRequest();
      case 'Login':
        return $1.LoginRequest();
      case 'Refresh':
        return $1.RefreshRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'Me':
        return me(ctx, request as $0.Empty);
      case 'Search':
        return search(ctx, request as $1.SearchUsersRequest);
      case 'Register':
        return register(ctx, request as $1.RegisterRequest);
      case 'Login':
        return login(ctx, request as $1.LoginRequest);
      case 'Refresh':
        return refresh(ctx, request as $1.RefreshRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => UserServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => UserServiceBase$messageJson;
}
