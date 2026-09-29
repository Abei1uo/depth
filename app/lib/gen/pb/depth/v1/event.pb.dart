// This is a generated file - do not edit.
//
// Generated from depth/v1/event.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'message.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// SyncRequest 断线重连后按 last_seq 补拉增量（对应 ws "sync" 事件）。
class SyncRequest extends $pb.GeneratedMessage {
  factory SyncRequest({
    $core.String? conversationId,
    $fixnum.Int64? lastSeq,
  }) {
    final result = SyncRequest._();
    if (conversationId != null) result.conversationId = conversationId;
    if (lastSeq != null) result.lastSeq = lastSeq;
    return result;
  }

  SyncRequest._();

  factory SyncRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncRequest()..mergeFromBuffer(data, registry);
  factory SyncRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: SyncRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'lastSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncRequest copyWith(void Function(SyncRequest) updates) =>
      super.copyWith((message) => updates(message as SyncRequest))
          as SyncRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncRequest() / SyncRequest.new instead')
  static SyncRequest create() => SyncRequest._();
  static $pb.GeneratedMessage $_createMessage() => SyncRequest._();
  @$core.override
  SyncRequest createEmptyInstance() => SyncRequest._();
  @$core.pragma('dart2js:noInline')
  static SyncRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncRequest>(
          SyncRequest.$_createMessage);
  static SyncRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get lastSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set lastSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLastSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastSeq() => $_clearField(2);
}

/// SyncResult 补拉结果（对应 ws "sync_result"，复用消息列表下发）。
class SyncResult extends $pb.GeneratedMessage {
  factory SyncResult({
    $core.Iterable<$0.Message>? messages,
  }) {
    final result = SyncResult._();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  SyncResult._();

  factory SyncResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncResult()..mergeFromBuffer(data, registry);
  factory SyncResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: SyncResult.$_createMessage)
    ..pPM<$0.Message>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: $0.Message.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncResult copyWith(void Function(SyncResult) updates) =>
      super.copyWith((message) => updates(message as SyncResult)) as SyncResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncResult() / SyncResult.new instead')
  static SyncResult create() => SyncResult._();
  static $pb.GeneratedMessage $_createMessage() => SyncResult._();
  @$core.override
  SyncResult createEmptyInstance() => SyncResult._();
  @$core.pragma('dart2js:noInline')
  static SyncResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncResult>(SyncResult.$_createMessage);
  static SyncResult? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Message> get messages => $_getList(0);
}

/// MarkRead 已读回执上报（Phase 2，对应 ws "mark_read"）。
class MarkRead extends $pb.GeneratedMessage {
  factory MarkRead({
    $core.String? conversationId,
    $fixnum.Int64? maxSeq,
  }) {
    final result = MarkRead._();
    if (conversationId != null) result.conversationId = conversationId;
    if (maxSeq != null) result.maxSeq = maxSeq;
    return result;
  }

  MarkRead._();

  factory MarkRead.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRead()..mergeFromBuffer(data, registry);
  factory MarkRead.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRead()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkRead',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: MarkRead.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aInt64(2, _omitFieldNames ? '' : 'maxSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRead clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRead copyWith(void Function(MarkRead) updates) =>
      super.copyWith((message) => updates(message as MarkRead)) as MarkRead;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkRead() / MarkRead.new instead')
  static MarkRead create() => MarkRead._();
  static $pb.GeneratedMessage $_createMessage() => MarkRead._();
  @$core.override
  MarkRead createEmptyInstance() => MarkRead._();
  @$core.pragma('dart2js:noInline')
  static MarkRead getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MarkRead>(MarkRead.$_createMessage);
  static MarkRead? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get maxSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set maxSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxSeq() => $_clearField(2);
}

/// Typing 输入状态（Phase 2，对应 ws "typing"）。
class Typing extends $pb.GeneratedMessage {
  factory Typing({
    $core.String? conversationId,
    $core.bool? typing,
  }) {
    final result = Typing._();
    if (conversationId != null) result.conversationId = conversationId;
    if (typing != null) result.typing = typing;
    return result;
  }

  Typing._();

  factory Typing.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Typing()..mergeFromBuffer(data, registry);
  factory Typing.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Typing()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Typing',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: Typing.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'conversationId')
    ..aOB(2, _omitFieldNames ? '' : 'typing')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Typing clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Typing copyWith(void Function(Typing) updates) =>
      super.copyWith((message) => updates(message as Typing)) as Typing;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Typing() / Typing.new instead')
  static Typing create() => Typing._();
  static $pb.GeneratedMessage $_createMessage() => Typing._();
  @$core.override
  Typing createEmptyInstance() => Typing._();
  @$core.pragma('dart2js:noInline')
  static Typing getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Typing>(Typing.$_createMessage);
  static Typing? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get conversationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set conversationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get typing => $_getBF(1);
  @$pb.TagNumber(2)
  set typing($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTyping() => $_has(1);
  @$pb.TagNumber(2)
  void clearTyping() => $_clearField(2);
}

/// PresenceUpdate 在线状态变更（对应 ws "presence_update"）。
class PresenceUpdate extends $pb.GeneratedMessage {
  factory PresenceUpdate({
    $core.String? userId,
    $core.bool? online,
    $fixnum.Int64? lastSeen,
  }) {
    final result = PresenceUpdate._();
    if (userId != null) result.userId = userId;
    if (online != null) result.online = online;
    if (lastSeen != null) result.lastSeen = lastSeen;
    return result;
  }

  PresenceUpdate._();

  factory PresenceUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PresenceUpdate()..mergeFromBuffer(data, registry);
  factory PresenceUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PresenceUpdate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PresenceUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: PresenceUpdate.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOB(2, _omitFieldNames ? '' : 'online')
    ..aInt64(3, _omitFieldNames ? '' : 'lastSeen')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceUpdate copyWith(void Function(PresenceUpdate) updates) =>
      super.copyWith((message) => updates(message as PresenceUpdate))
          as PresenceUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PresenceUpdate() / PresenceUpdate.new instead')
  static PresenceUpdate create() => PresenceUpdate._();
  static $pb.GeneratedMessage $_createMessage() => PresenceUpdate._();
  @$core.override
  PresenceUpdate createEmptyInstance() => PresenceUpdate._();
  @$core.pragma('dart2js:noInline')
  static PresenceUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PresenceUpdate>(
          PresenceUpdate.$_createMessage);
  static PresenceUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get online => $_getBF(1);
  @$pb.TagNumber(2)
  set online($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOnline() => $_has(1);
  @$pb.TagNumber(2)
  void clearOnline() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get lastSeen => $_getI64(2);
  @$pb.TagNumber(3)
  set lastSeen($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLastSeen() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastSeen() => $_clearField(3);
}

/// ErrorEvent 服务端错误通知（对应 ws "error"）。
class ErrorEvent extends $pb.GeneratedMessage {
  factory ErrorEvent({
    $core.String? code,
    $core.String? message,
    $core.String? relatedClientMsgId,
  }) {
    final result = ErrorEvent._();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    if (relatedClientMsgId != null)
      result.relatedClientMsgId = relatedClientMsgId;
    return result;
  }

  ErrorEvent._();

  factory ErrorEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ErrorEvent()..mergeFromBuffer(data, registry);
  factory ErrorEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ErrorEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ErrorEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: ErrorEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'relatedClientMsgId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ErrorEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ErrorEvent copyWith(void Function(ErrorEvent) updates) =>
      super.copyWith((message) => updates(message as ErrorEvent)) as ErrorEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ErrorEvent() / ErrorEvent.new instead')
  static ErrorEvent create() => ErrorEvent._();
  static $pb.GeneratedMessage $_createMessage() => ErrorEvent._();
  @$core.override
  ErrorEvent createEmptyInstance() => ErrorEvent._();
  @$core.pragma('dart2js:noInline')
  static ErrorEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ErrorEvent>(ErrorEvent.$_createMessage);
  static ErrorEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get relatedClientMsgId => $_getSZ(2);
  @$pb.TagNumber(3)
  set relatedClientMsgId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRelatedClientMsgId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRelatedClientMsgId() => $_clearField(3);
}

enum Event_Kind {
  sendMessage,
  sync,
  markRead,
  typing,
  newMessage,
  msgAck,
  syncResult,
  presenceUpdate,
  error,
  notSet
}

/// Event 是所有 WS 上下行事件的统一封装。
/// 客户端上行：send_message / sync / mark_read / typing
/// 服务端下行：new_message / msg_ack / sync_result / presence_update / error
class Event extends $pb.GeneratedMessage {
  factory Event({
    $core.String? type,
    $0.SendInput? sendMessage,
    SyncRequest? sync,
    MarkRead? markRead,
    Typing? typing,
    $0.Message? newMessage,
    $0.Ack? msgAck,
    SyncResult? syncResult,
    PresenceUpdate? presenceUpdate,
    ErrorEvent? error,
  }) {
    final result = Event._();
    if (type != null) result.type = type;
    if (sendMessage != null) result.sendMessage = sendMessage;
    if (sync != null) result.sync = sync;
    if (markRead != null) result.markRead = markRead;
    if (typing != null) result.typing = typing;
    if (newMessage != null) result.newMessage = newMessage;
    if (msgAck != null) result.msgAck = msgAck;
    if (syncResult != null) result.syncResult = syncResult;
    if (presenceUpdate != null) result.presenceUpdate = presenceUpdate;
    if (error != null) result.error = error;
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Event_Kind> _Event_KindByTag = {
    2: Event_Kind.sendMessage,
    3: Event_Kind.sync,
    4: Event_Kind.markRead,
    5: Event_Kind.typing,
    6: Event_Kind.newMessage,
    7: Event_Kind.msgAck,
    8: Event_Kind.syncResult,
    9: Event_Kind.presenceUpdate,
    10: Event_Kind.error,
    0: Event_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: Event.$_createMessage)
    ..oo(0, [2, 3, 4, 5, 6, 7, 8, 9, 10])
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOM<$0.SendInput>(2, _omitFieldNames ? '' : 'sendMessage',
        subBuilder: $0.SendInput.$_createMessage)
    ..aOM<SyncRequest>(3, _omitFieldNames ? '' : 'sync',
        subBuilder: SyncRequest.$_createMessage)
    ..aOM<MarkRead>(4, _omitFieldNames ? '' : 'markRead',
        subBuilder: MarkRead.$_createMessage)
    ..aOM<Typing>(5, _omitFieldNames ? '' : 'typing',
        subBuilder: Typing.$_createMessage)
    ..aOM<$0.Message>(6, _omitFieldNames ? '' : 'newMessage',
        subBuilder: $0.Message.$_createMessage)
    ..aOM<$0.Ack>(7, _omitFieldNames ? '' : 'msgAck',
        subBuilder: $0.Ack.$_createMessage)
    ..aOM<SyncResult>(8, _omitFieldNames ? '' : 'syncResult',
        subBuilder: SyncResult.$_createMessage)
    ..aOM<PresenceUpdate>(9, _omitFieldNames ? '' : 'presenceUpdate',
        subBuilder: PresenceUpdate.$_createMessage)
    ..aOM<ErrorEvent>(10, _omitFieldNames ? '' : 'error',
        subBuilder: ErrorEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) =>
      super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Event() / Event.new instead')
  static Event create() => Event._();
  static $pb.GeneratedMessage $_createMessage() => Event._();
  @$core.override
  Event createEmptyInstance() => Event._();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Event>(Event.$_createMessage);
  static Event? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  Event_Kind whichKind() => _Event_KindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  void clearKind() => $_clearField($_whichOneof(0));

  /// 保留原始事件名以便与 JSON MVP 对齐（可选字段）。
  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.SendInput get sendMessage => $_getN(1);
  @$pb.TagNumber(2)
  set sendMessage($0.SendInput value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSendMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearSendMessage() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.SendInput ensureSendMessage() => $_ensure(1);

  @$pb.TagNumber(3)
  SyncRequest get sync => $_getN(2);
  @$pb.TagNumber(3)
  set sync(SyncRequest value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSync() => $_has(2);
  @$pb.TagNumber(3)
  void clearSync() => $_clearField(3);
  @$pb.TagNumber(3)
  SyncRequest ensureSync() => $_ensure(2);

  @$pb.TagNumber(4)
  MarkRead get markRead => $_getN(3);
  @$pb.TagNumber(4)
  set markRead(MarkRead value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMarkRead() => $_has(3);
  @$pb.TagNumber(4)
  void clearMarkRead() => $_clearField(4);
  @$pb.TagNumber(4)
  MarkRead ensureMarkRead() => $_ensure(3);

  @$pb.TagNumber(5)
  Typing get typing => $_getN(4);
  @$pb.TagNumber(5)
  set typing(Typing value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTyping() => $_has(4);
  @$pb.TagNumber(5)
  void clearTyping() => $_clearField(5);
  @$pb.TagNumber(5)
  Typing ensureTyping() => $_ensure(4);

  @$pb.TagNumber(6)
  $0.Message get newMessage => $_getN(5);
  @$pb.TagNumber(6)
  set newMessage($0.Message value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasNewMessage() => $_has(5);
  @$pb.TagNumber(6)
  void clearNewMessage() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Message ensureNewMessage() => $_ensure(5);

  @$pb.TagNumber(7)
  $0.Ack get msgAck => $_getN(6);
  @$pb.TagNumber(7)
  set msgAck($0.Ack value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMsgAck() => $_has(6);
  @$pb.TagNumber(7)
  void clearMsgAck() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Ack ensureMsgAck() => $_ensure(6);

  @$pb.TagNumber(8)
  SyncResult get syncResult => $_getN(7);
  @$pb.TagNumber(8)
  set syncResult(SyncResult value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSyncResult() => $_has(7);
  @$pb.TagNumber(8)
  void clearSyncResult() => $_clearField(8);
  @$pb.TagNumber(8)
  SyncResult ensureSyncResult() => $_ensure(7);

  @$pb.TagNumber(9)
  PresenceUpdate get presenceUpdate => $_getN(8);
  @$pb.TagNumber(9)
  set presenceUpdate(PresenceUpdate value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPresenceUpdate() => $_has(8);
  @$pb.TagNumber(9)
  void clearPresenceUpdate() => $_clearField(9);
  @$pb.TagNumber(9)
  PresenceUpdate ensurePresenceUpdate() => $_ensure(8);

  @$pb.TagNumber(10)
  ErrorEvent get error => $_getN(9);
  @$pb.TagNumber(10)
  set error(ErrorEvent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasError() => $_has(9);
  @$pb.TagNumber(10)
  void clearError() => $_clearField(10);
  @$pb.TagNumber(10)
  ErrorEvent ensureError() => $_ensure(9);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
