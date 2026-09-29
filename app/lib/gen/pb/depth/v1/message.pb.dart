// This is a generated file - do not edit.
//
// Generated from depth/v1/message.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Message 服务端落库后的完整消息实体。
/// JSON 字段映射：server_msg_id / client_msg_id / conversation_id /
/// sender_id / seq / content / timestamp。
class Message extends $pb.GeneratedMessage {
  factory Message({
    $core.String? serverMsgId,
    $core.String? clientMsgId,
    $core.String? conversationId,
    $core.String? senderId,
    $fixnum.Int64? seq,
    $0.MessageContent? content,
    $fixnum.Int64? timestamp,
  }) {
    final result = Message._();
    if (serverMsgId != null) result.serverMsgId = serverMsgId;
    if (clientMsgId != null) result.clientMsgId = clientMsgId;
    if (conversationId != null) result.conversationId = conversationId;
    if (senderId != null) result.senderId = senderId;
    if (seq != null) result.seq = seq;
    if (content != null) result.content = content;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  Message._();

  factory Message.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Message()..mergeFromBuffer(data, registry);
  factory Message.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Message()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Message',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: Message.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'serverMsgId')
    ..aOS(2, _omitFieldNames ? '' : 'clientMsgId')
    ..aOS(3, _omitFieldNames ? '' : 'conversationId')
    ..aOS(4, _omitFieldNames ? '' : 'senderId')
    ..aInt64(5, _omitFieldNames ? '' : 'seq')
    ..aOM<$0.MessageContent>(6, _omitFieldNames ? '' : 'content',
        subBuilder: $0.MessageContent.$_createMessage)
    ..aInt64(7, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message copyWith(void Function(Message) updates) =>
      super.copyWith((message) => updates(message as Message)) as Message;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Message() / Message.new instead')
  static Message create() => Message._();
  static $pb.GeneratedMessage $_createMessage() => Message._();
  @$core.override
  Message createEmptyInstance() => Message._();
  @$core.pragma('dart2js:noInline')
  static Message getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Message>(Message.$_createMessage);
  static Message? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverMsgId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverMsgId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerMsgId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerMsgId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get clientMsgId => $_getSZ(1);
  @$pb.TagNumber(2)
  set clientMsgId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientMsgId() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientMsgId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get conversationId => $_getSZ(2);
  @$pb.TagNumber(3)
  set conversationId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConversationId() => $_has(2);
  @$pb.TagNumber(3)
  void clearConversationId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get senderId => $_getSZ(3);
  @$pb.TagNumber(4)
  set senderId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSenderId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSenderId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get seq => $_getI64(4);
  @$pb.TagNumber(5)
  set seq($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSeq() => $_has(4);
  @$pb.TagNumber(5)
  void clearSeq() => $_clearField(5);

  @$pb.TagNumber(6)
  $0.MessageContent get content => $_getN(5);
  @$pb.TagNumber(6)
  set content($0.MessageContent value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasContent() => $_has(5);
  @$pb.TagNumber(6)
  void clearContent() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.MessageContent ensureContent() => $_ensure(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get timestamp => $_getI64(6);
  @$pb.TagNumber(7)
  set timestamp($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTimestamp() => $_has(6);
  @$pb.TagNumber(7)
  void clearTimestamp() => $_clearField(7);
}

/// SendInput 客户端发送消息的入参（对应 message.SendInput）。
class SendInput extends $pb.GeneratedMessage {
  factory SendInput({
    $core.String? clientMsgId,
    $core.String? conversationId,
    $0.MessageContent? content,
  }) {
    final result = SendInput._();
    if (clientMsgId != null) result.clientMsgId = clientMsgId;
    if (conversationId != null) result.conversationId = conversationId;
    if (content != null) result.content = content;
    return result;
  }

  SendInput._();

  factory SendInput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendInput()..mergeFromBuffer(data, registry);
  factory SendInput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendInput()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendInput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: SendInput.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'clientMsgId')
    ..aOS(2, _omitFieldNames ? '' : 'conversationId')
    ..aOM<$0.MessageContent>(3, _omitFieldNames ? '' : 'content',
        subBuilder: $0.MessageContent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendInput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendInput copyWith(void Function(SendInput) updates) =>
      super.copyWith((message) => updates(message as SendInput)) as SendInput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendInput() / SendInput.new instead')
  static SendInput create() => SendInput._();
  static $pb.GeneratedMessage $_createMessage() => SendInput._();
  @$core.override
  SendInput createEmptyInstance() => SendInput._();
  @$core.pragma('dart2js:noInline')
  static SendInput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendInput>(SendInput.$_createMessage);
  static SendInput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientMsgId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientMsgId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientMsgId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientMsgId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get conversationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set conversationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConversationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.MessageContent get content => $_getN(2);
  @$pb.TagNumber(3)
  set content($0.MessageContent value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearContent() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.MessageContent ensureContent() => $_ensure(2);
}

/// Ack 服务端回执给发送方的确认（对应 message.Ack）。
class Ack extends $pb.GeneratedMessage {
  factory Ack({
    $core.String? clientMsgId,
    $core.String? serverMsgId,
    $fixnum.Int64? seq,
    $fixnum.Int64? timestamp,
  }) {
    final result = Ack._();
    if (clientMsgId != null) result.clientMsgId = clientMsgId;
    if (serverMsgId != null) result.serverMsgId = serverMsgId;
    if (seq != null) result.seq = seq;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  Ack._();

  factory Ack.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ack()..mergeFromBuffer(data, registry);
  factory Ack.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ack()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ack',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: Ack.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'clientMsgId')
    ..aOS(2, _omitFieldNames ? '' : 'serverMsgId')
    ..aInt64(3, _omitFieldNames ? '' : 'seq')
    ..aInt64(4, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ack clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ack copyWith(void Function(Ack) updates) =>
      super.copyWith((message) => updates(message as Ack)) as Ack;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Ack() / Ack.new instead')
  static Ack create() => Ack._();
  static $pb.GeneratedMessage $_createMessage() => Ack._();
  @$core.override
  Ack createEmptyInstance() => Ack._();
  @$core.pragma('dart2js:noInline')
  static Ack getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Ack>(Ack.$_createMessage);
  static Ack? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientMsgId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientMsgId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientMsgId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientMsgId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverMsgId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverMsgId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerMsgId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerMsgId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get seq => $_getI64(2);
  @$pb.TagNumber(3)
  set seq($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSeq() => $_has(2);
  @$pb.TagNumber(3)
  void clearSeq() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get timestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set timestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestamp() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
