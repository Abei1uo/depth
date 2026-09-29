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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $1;

import 'chat.pbenum.dart';
import 'message.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'chat.pbenum.dart';

/// Conversation 会话实体。
class Conversation extends $pb.GeneratedMessage {
  factory Conversation({
    $core.String? id,
    ConversationType? type,
    $core.String? name,
    $core.String? avatarUrl,
    $core.String? ownerId,
    $core.Iterable<$core.String>? memberIds,
  }) {
    final result = Conversation._();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (name != null) result.name = name;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (ownerId != null) result.ownerId = ownerId;
    if (memberIds != null) result.memberIds.addAll(memberIds);
    return result;
  }

  Conversation._();

  factory Conversation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Conversation()..mergeFromBuffer(data, registry);
  factory Conversation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Conversation()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Conversation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: Conversation.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ConversationType>(2, _omitFieldNames ? '' : 'type',
        enumValues: ConversationType.values)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(5, _omitFieldNames ? '' : 'ownerId')
    ..pPS(6, _omitFieldNames ? '' : 'memberIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Conversation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Conversation copyWith(void Function(Conversation) updates) =>
      super.copyWith((message) => updates(message as Conversation))
          as Conversation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Conversation() / Conversation.new instead')
  static Conversation create() => Conversation._();
  static $pb.GeneratedMessage $_createMessage() => Conversation._();
  @$core.override
  Conversation createEmptyInstance() => Conversation._();
  @$core.pragma('dart2js:noInline')
  static Conversation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Conversation>(
          Conversation.$_createMessage);
  static Conversation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ConversationType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(ConversationType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get avatarUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set avatarUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAvatarUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvatarUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get ownerId => $_getSZ(4);
  @$pb.TagNumber(5)
  set ownerId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOwnerId() => $_has(4);
  @$pb.TagNumber(5)
  void clearOwnerId() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get memberIds => $_getList(5);
}

class CreateDirectRequest extends $pb.GeneratedMessage {
  factory CreateDirectRequest({
    $core.String? peerId,
  }) {
    final result = CreateDirectRequest._();
    if (peerId != null) result.peerId = peerId;
    return result;
  }

  CreateDirectRequest._();

  factory CreateDirectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateDirectRequest()..mergeFromBuffer(data, registry);
  factory CreateDirectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateDirectRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateDirectRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: CreateDirectRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'peerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateDirectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateDirectRequest copyWith(void Function(CreateDirectRequest) updates) =>
      super.copyWith((message) => updates(message as CreateDirectRequest))
          as CreateDirectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use CreateDirectRequest() / CreateDirectRequest.new instead')
  static CreateDirectRequest create() => CreateDirectRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateDirectRequest._();
  @$core.override
  CreateDirectRequest createEmptyInstance() => CreateDirectRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateDirectRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateDirectRequest>(
          CreateDirectRequest.$_createMessage);
  static CreateDirectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get peerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set peerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPeerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPeerId() => $_clearField(1);
}

class CreateGroupRequest extends $pb.GeneratedMessage {
  factory CreateGroupRequest({
    $core.String? name,
    $core.Iterable<$core.String>? memberIds,
  }) {
    final result = CreateGroupRequest._();
    if (name != null) result.name = name;
    if (memberIds != null) result.memberIds.addAll(memberIds);
    return result;
  }

  CreateGroupRequest._();

  factory CreateGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupRequest()..mergeFromBuffer(data, registry);
  factory CreateGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateGroupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: CreateGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'memberIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupRequest copyWith(void Function(CreateGroupRequest) updates) =>
      super.copyWith((message) => updates(message as CreateGroupRequest))
          as CreateGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreateGroupRequest() / CreateGroupRequest.new instead')
  static CreateGroupRequest create() => CreateGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateGroupRequest._();
  @$core.override
  CreateGroupRequest createEmptyInstance() => CreateGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateGroupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateGroupRequest>(
          CreateGroupRequest.$_createMessage);
  static CreateGroupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get memberIds => $_getList(1);
}

class ConversationIdResponse extends $pb.GeneratedMessage {
  factory ConversationIdResponse({
    $core.String? conversationId,
  }) {
    final result = ConversationIdResponse._();
    if (conversationId != null) result.conversationId = conversationId;
    return result;
  }

  ConversationIdResponse._();

  factory ConversationIdResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationIdResponse()..mergeFromBuffer(data, registry);
  factory ConversationIdResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationIdResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConversationIdResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: ConversationIdResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationIdResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationIdResponse copyWith(
          void Function(ConversationIdResponse) updates) =>
      super.copyWith((message) => updates(message as ConversationIdResponse))
          as ConversationIdResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ConversationIdResponse() / ConversationIdResponse.new instead')
  static ConversationIdResponse create() => ConversationIdResponse._();
  static $pb.GeneratedMessage $_createMessage() => ConversationIdResponse._();
  @$core.override
  ConversationIdResponse createEmptyInstance() => ConversationIdResponse._();
  @$core.pragma('dart2js:noInline')
  static ConversationIdResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConversationIdResponse>(
          ConversationIdResponse.$_createMessage);
  static ConversationIdResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);
}

class ListConversationsResponse extends $pb.GeneratedMessage {
  factory ListConversationsResponse({
    $core.Iterable<Conversation>? conversations,
  }) {
    final result = ListConversationsResponse._();
    if (conversations != null) result.conversations.addAll(conversations);
    return result;
  }

  ListConversationsResponse._();

  factory ListConversationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversationsResponse()..mergeFromBuffer(data, registry);
  factory ListConversationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversationsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConversationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: ListConversationsResponse.$_createMessage)
    ..pPM<Conversation>(1, _omitFieldNames ? '' : 'conversations',
        subBuilder: Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversationsResponse copyWith(
          void Function(ListConversationsResponse) updates) =>
      super.copyWith((message) => updates(message as ListConversationsResponse))
          as ListConversationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListConversationsResponse() / ListConversationsResponse.new instead')
  static ListConversationsResponse create() => ListConversationsResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      ListConversationsResponse._();
  @$core.override
  ListConversationsResponse createEmptyInstance() =>
      ListConversationsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListConversationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConversationsResponse>(
          ListConversationsResponse.$_createMessage);
  static ListConversationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Conversation> get conversations => $_getList(0);
}

class ListMessagesRequest extends $pb.GeneratedMessage {
  factory ListMessagesRequest({
    $core.String? conversationId,
    $fixnum.Int64? beforeSeq,
    $core.int? limit,
  }) {
    final result = ListMessagesRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (beforeSeq != null) result.beforeSeq = beforeSeq;
    if (limit != null) result.limit = limit;
    return result;
  }

  ListMessagesRequest._();

  factory ListMessagesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessagesRequest()..mergeFromBuffer(data, registry);
  factory ListMessagesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessagesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMessagesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: ListMessagesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'beforeSeq')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessagesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessagesRequest copyWith(void Function(ListMessagesRequest) updates) =>
      super.copyWith((message) => updates(message as ListMessagesRequest))
          as ListMessagesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListMessagesRequest() / ListMessagesRequest.new instead')
  static ListMessagesRequest create() => ListMessagesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListMessagesRequest._();
  @$core.override
  ListMessagesRequest createEmptyInstance() => ListMessagesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListMessagesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMessagesRequest>(
          ListMessagesRequest.$_createMessage);
  static ListMessagesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get beforeSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set beforeSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBeforeSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeforeSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class ListMessagesResponse extends $pb.GeneratedMessage {
  factory ListMessagesResponse({
    $core.Iterable<$0.Message>? messages,
  }) {
    final result = ListMessagesResponse._();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  ListMessagesResponse._();

  factory ListMessagesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessagesResponse()..mergeFromBuffer(data, registry);
  factory ListMessagesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessagesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMessagesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: ListMessagesResponse.$_createMessage)
    ..pPM<$0.Message>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: $0.Message.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessagesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessagesResponse copyWith(void Function(ListMessagesResponse) updates) =>
      super.copyWith((message) => updates(message as ListMessagesResponse))
          as ListMessagesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListMessagesResponse() / ListMessagesResponse.new instead')
  static ListMessagesResponse create() => ListMessagesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListMessagesResponse._();
  @$core.override
  ListMessagesResponse createEmptyInstance() => ListMessagesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListMessagesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMessagesResponse>(
          ListMessagesResponse.$_createMessage);
  static ListMessagesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Message> get messages => $_getList(0);
}

/// ChatService 会话与历史消息接口。
class ChatServiceApi {
  final $pb.RpcClient _client;

  ChatServiceApi(this._client);

  $async.Future<ConversationIdResponse> createDirect(
          $pb.ClientContext? ctx, CreateDirectRequest request) =>
      _client.invoke<ConversationIdResponse>(ctx, 'ChatService', 'CreateDirect',
          request, ConversationIdResponse());
  $async.Future<ConversationIdResponse> createGroup(
          $pb.ClientContext? ctx, CreateGroupRequest request) =>
      _client.invoke<ConversationIdResponse>(
          ctx, 'ChatService', 'CreateGroup', request, ConversationIdResponse());
  $async.Future<ListConversationsResponse> listConversations(
          $pb.ClientContext? ctx, $1.Empty request) =>
      _client.invoke<ListConversationsResponse>(ctx, 'ChatService',
          'ListConversations', request, ListConversationsResponse());
  $async.Future<ListMessagesResponse> listMessages(
          $pb.ClientContext? ctx, ListMessagesRequest request) =>
      _client.invoke<ListMessagesResponse>(
          ctx, 'ChatService', 'ListMessages', request, ListMessagesResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
