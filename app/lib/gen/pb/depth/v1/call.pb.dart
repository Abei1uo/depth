// This is a generated file - do not edit.
//
// Generated from depth/v1/call.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'call.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'call.pbenum.dart';

/// CallInvite 邀请建立通话。
class CallInvite extends $pb.GeneratedMessage {
  factory CallInvite({
    $core.String? callId,
    $core.String? conversationId,
    $core.String? fromUserId,
    $core.Iterable<$core.String>? toUserIds,
    $core.bool? video,
  }) {
    final result = CallInvite._();
    if (callId != null) result.callId = callId;
    if (conversationId != null) result.conversationId = conversationId;
    if (fromUserId != null) result.fromUserId = fromUserId;
    if (toUserIds != null) result.toUserIds.addAll(toUserIds);
    if (video != null) result.video = video;
    return result;
  }

  CallInvite._();

  factory CallInvite.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallInvite()..mergeFromBuffer(data, registry);
  factory CallInvite.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallInvite()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallInvite',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: CallInvite.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'callId')
    ..aOS(2, _omitFieldNames ? '' : 'conversationId')
    ..aOS(3, _omitFieldNames ? '' : 'fromUserId')
    ..pPS(4, _omitFieldNames ? '' : 'toUserIds')
    ..aOB(5, _omitFieldNames ? '' : 'video')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallInvite clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallInvite copyWith(void Function(CallInvite) updates) =>
      super.copyWith((message) => updates(message as CallInvite)) as CallInvite;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallInvite() / CallInvite.new instead')
  static CallInvite create() => CallInvite._();
  static $pb.GeneratedMessage $_createMessage() => CallInvite._();
  @$core.override
  CallInvite createEmptyInstance() => CallInvite._();
  @$core.pragma('dart2js:noInline')
  static CallInvite getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CallInvite>(CallInvite.$_createMessage);
  static CallInvite? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get callId => $_getSZ(0);
  @$pb.TagNumber(1)
  set callId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get conversationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set conversationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConversationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fromUserId => $_getSZ(2);
  @$pb.TagNumber(3)
  set fromUserId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFromUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFromUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get toUserIds => $_getList(3);

  @$pb.TagNumber(5)
  $core.bool get video => $_getBF(4);
  @$pb.TagNumber(5)
  set video($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasVideo() => $_has(4);
  @$pb.TagNumber(5)
  void clearVideo() => $_clearField(5);
}

/// CallSignal 携带 SDP 协商内容（offer/answer）。
class CallSignal extends $pb.GeneratedMessage {
  factory CallSignal({
    $core.String? callId,
    $core.String? fromUserId,
    $core.String? sdp,
    $core.String? sdpType,
  }) {
    final result = CallSignal._();
    if (callId != null) result.callId = callId;
    if (fromUserId != null) result.fromUserId = fromUserId;
    if (sdp != null) result.sdp = sdp;
    if (sdpType != null) result.sdpType = sdpType;
    return result;
  }

  CallSignal._();

  factory CallSignal.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallSignal()..mergeFromBuffer(data, registry);
  factory CallSignal.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallSignal()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallSignal',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: CallSignal.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'callId')
    ..aOS(2, _omitFieldNames ? '' : 'fromUserId')
    ..aOS(3, _omitFieldNames ? '' : 'sdp')
    ..aOS(4, _omitFieldNames ? '' : 'sdpType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallSignal clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallSignal copyWith(void Function(CallSignal) updates) =>
      super.copyWith((message) => updates(message as CallSignal)) as CallSignal;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallSignal() / CallSignal.new instead')
  static CallSignal create() => CallSignal._();
  static $pb.GeneratedMessage $_createMessage() => CallSignal._();
  @$core.override
  CallSignal createEmptyInstance() => CallSignal._();
  @$core.pragma('dart2js:noInline')
  static CallSignal getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CallSignal>(CallSignal.$_createMessage);
  static CallSignal? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get callId => $_getSZ(0);
  @$pb.TagNumber(1)
  set callId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get fromUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromUserId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sdp => $_getSZ(2);
  @$pb.TagNumber(3)
  set sdp($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSdp() => $_has(2);
  @$pb.TagNumber(3)
  void clearSdp() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sdpType => $_getSZ(3);
  @$pb.TagNumber(4)
  set sdpType($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSdpType() => $_has(3);
  @$pb.TagNumber(4)
  void clearSdpType() => $_clearField(4);
}

/// IceCandidate 单条 ICE 候选。
class IceCandidate extends $pb.GeneratedMessage {
  factory IceCandidate({
    $core.String? callId,
    $core.String? fromUserId,
    $core.String? candidate,
    $core.String? sdpMid,
    $core.int? sdpMlineIndex,
  }) {
    final result = IceCandidate._();
    if (callId != null) result.callId = callId;
    if (fromUserId != null) result.fromUserId = fromUserId;
    if (candidate != null) result.candidate = candidate;
    if (sdpMid != null) result.sdpMid = sdpMid;
    if (sdpMlineIndex != null) result.sdpMlineIndex = sdpMlineIndex;
    return result;
  }

  IceCandidate._();

  factory IceCandidate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IceCandidate()..mergeFromBuffer(data, registry);
  factory IceCandidate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IceCandidate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IceCandidate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: IceCandidate.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'callId')
    ..aOS(2, _omitFieldNames ? '' : 'fromUserId')
    ..aOS(3, _omitFieldNames ? '' : 'candidate')
    ..aOS(4, _omitFieldNames ? '' : 'sdpMid')
    ..aI(5, _omitFieldNames ? '' : 'sdpMlineIndex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IceCandidate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IceCandidate copyWith(void Function(IceCandidate) updates) =>
      super.copyWith((message) => updates(message as IceCandidate))
          as IceCandidate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IceCandidate() / IceCandidate.new instead')
  static IceCandidate create() => IceCandidate._();
  static $pb.GeneratedMessage $_createMessage() => IceCandidate._();
  @$core.override
  IceCandidate createEmptyInstance() => IceCandidate._();
  @$core.pragma('dart2js:noInline')
  static IceCandidate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IceCandidate>(
          IceCandidate.$_createMessage);
  static IceCandidate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get callId => $_getSZ(0);
  @$pb.TagNumber(1)
  set callId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get fromUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromUserId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get candidate => $_getSZ(2);
  @$pb.TagNumber(3)
  set candidate($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCandidate() => $_has(2);
  @$pb.TagNumber(3)
  void clearCandidate() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sdpMid => $_getSZ(3);
  @$pb.TagNumber(4)
  set sdpMid($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSdpMid() => $_has(3);
  @$pb.TagNumber(4)
  void clearSdpMid() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get sdpMlineIndex => $_getIZ(4);
  @$pb.TagNumber(5)
  set sdpMlineIndex($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSdpMlineIndex() => $_has(4);
  @$pb.TagNumber(5)
  void clearSdpMlineIndex() => $_clearField(5);
}

/// CallControl 挂断/拒绝/取消等控制信令。
class CallControl extends $pb.GeneratedMessage {
  factory CallControl({
    $core.String? callId,
    $core.String? conversationId,
    $core.String? fromUserId,
    CallState? state,
    $core.String? reason,
  }) {
    final result = CallControl._();
    if (callId != null) result.callId = callId;
    if (conversationId != null) result.conversationId = conversationId;
    if (fromUserId != null) result.fromUserId = fromUserId;
    if (state != null) result.state = state;
    if (reason != null) result.reason = reason;
    return result;
  }

  CallControl._();

  factory CallControl.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallControl()..mergeFromBuffer(data, registry);
  factory CallControl.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallControl()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallControl',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: CallControl.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'callId')
    ..aOS(2, _omitFieldNames ? '' : 'conversationId')
    ..aOS(3, _omitFieldNames ? '' : 'fromUserId')
    ..aE<CallState>(4, _omitFieldNames ? '' : 'state',
        enumValues: CallState.values)
    ..aOS(5, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallControl clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallControl copyWith(void Function(CallControl) updates) =>
      super.copyWith((message) => updates(message as CallControl))
          as CallControl;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallControl() / CallControl.new instead')
  static CallControl create() => CallControl._();
  static $pb.GeneratedMessage $_createMessage() => CallControl._();
  @$core.override
  CallControl createEmptyInstance() => CallControl._();
  @$core.pragma('dart2js:noInline')
  static CallControl getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CallControl>(
          CallControl.$_createMessage);
  static CallControl? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get callId => $_getSZ(0);
  @$pb.TagNumber(1)
  set callId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get conversationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set conversationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConversationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConversationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fromUserId => $_getSZ(2);
  @$pb.TagNumber(3)
  set fromUserId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFromUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFromUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  CallState get state => $_getN(3);
  @$pb.TagNumber(4)
  set state(CallState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get reason => $_getSZ(4);
  @$pb.TagNumber(5)
  set reason($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReason() => $_has(4);
  @$pb.TagNumber(5)
  void clearReason() => $_clearField(5);
}

enum CallEvent_Kind { invite, signal, candidate, control, notSet }

/// CallEvent 通话信令事件封装（同样通过 WS 通道传输）。
class CallEvent extends $pb.GeneratedMessage {
  factory CallEvent({
    CallInvite? invite,
    CallSignal? signal,
    IceCandidate? candidate,
    CallControl? control,
  }) {
    final result = CallEvent._();
    if (invite != null) result.invite = invite;
    if (signal != null) result.signal = signal;
    if (candidate != null) result.candidate = candidate;
    if (control != null) result.control = control;
    return result;
  }

  CallEvent._();

  factory CallEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallEvent()..mergeFromBuffer(data, registry);
  factory CallEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CallEvent()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CallEvent_Kind> _CallEvent_KindByTag = {
    1: CallEvent_Kind.invite,
    2: CallEvent_Kind.signal,
    3: CallEvent_Kind.candidate,
    4: CallEvent_Kind.control,
    0: CallEvent_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: CallEvent.$_createMessage)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<CallInvite>(1, _omitFieldNames ? '' : 'invite',
        subBuilder: CallInvite.$_createMessage)
    ..aOM<CallSignal>(2, _omitFieldNames ? '' : 'signal',
        subBuilder: CallSignal.$_createMessage)
    ..aOM<IceCandidate>(3, _omitFieldNames ? '' : 'candidate',
        subBuilder: IceCandidate.$_createMessage)
    ..aOM<CallControl>(4, _omitFieldNames ? '' : 'control',
        subBuilder: CallControl.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallEvent copyWith(void Function(CallEvent) updates) =>
      super.copyWith((message) => updates(message as CallEvent)) as CallEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CallEvent() / CallEvent.new instead')
  static CallEvent create() => CallEvent._();
  static $pb.GeneratedMessage $_createMessage() => CallEvent._();
  @$core.override
  CallEvent createEmptyInstance() => CallEvent._();
  @$core.pragma('dart2js:noInline')
  static CallEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CallEvent>(CallEvent.$_createMessage);
  static CallEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  CallEvent_Kind whichKind() => _CallEvent_KindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearKind() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  CallInvite get invite => $_getN(0);
  @$pb.TagNumber(1)
  set invite(CallInvite value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInvite() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvite() => $_clearField(1);
  @$pb.TagNumber(1)
  CallInvite ensureInvite() => $_ensure(0);

  @$pb.TagNumber(2)
  CallSignal get signal => $_getN(1);
  @$pb.TagNumber(2)
  set signal(CallSignal value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSignal() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignal() => $_clearField(2);
  @$pb.TagNumber(2)
  CallSignal ensureSignal() => $_ensure(1);

  @$pb.TagNumber(3)
  IceCandidate get candidate => $_getN(2);
  @$pb.TagNumber(3)
  set candidate(IceCandidate value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCandidate() => $_has(2);
  @$pb.TagNumber(3)
  void clearCandidate() => $_clearField(3);
  @$pb.TagNumber(3)
  IceCandidate ensureCandidate() => $_ensure(2);

  @$pb.TagNumber(4)
  CallControl get control => $_getN(3);
  @$pb.TagNumber(4)
  set control(CallControl value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasControl() => $_has(3);
  @$pb.TagNumber(4)
  void clearControl() => $_clearField(4);
  @$pb.TagNumber(4)
  CallControl ensureControl() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
