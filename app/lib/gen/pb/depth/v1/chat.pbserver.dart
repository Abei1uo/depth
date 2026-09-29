// This is a generated file - do not edit.
//
// Generated from depth/v1/chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $1;

import 'chat.pb.dart' as $3;
import 'chat.pbjson.dart';

export 'chat.pb.dart';

abstract class ChatServiceBase extends $pb.GeneratedService {
  $async.Future<$3.ConversationIdResponse> createDirect(
      $pb.ServerContext ctx, $3.CreateDirectRequest request);
  $async.Future<$3.ConversationIdResponse> createGroup(
      $pb.ServerContext ctx, $3.CreateGroupRequest request);
  $async.Future<$3.ListConversationsResponse> listConversations(
      $pb.ServerContext ctx, $1.Empty request);
  $async.Future<$3.ListMessagesResponse> listMessages(
      $pb.ServerContext ctx, $3.ListMessagesRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'CreateDirect':
        return $3.CreateDirectRequest();
      case 'CreateGroup':
        return $3.CreateGroupRequest();
      case 'ListConversations':
        return $1.Empty();
      case 'ListMessages':
        return $3.ListMessagesRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'CreateDirect':
        return createDirect(ctx, request as $3.CreateDirectRequest);
      case 'CreateGroup':
        return createGroup(ctx, request as $3.CreateGroupRequest);
      case 'ListConversations':
        return listConversations(ctx, request as $1.Empty);
      case 'ListMessages':
        return listMessages(ctx, request as $3.ListMessagesRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ChatServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => ChatServiceBase$messageJson;
}
