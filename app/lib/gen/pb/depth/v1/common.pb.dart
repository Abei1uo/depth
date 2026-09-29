// This is a generated file - do not edit.
//
// Generated from depth/v1/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'common.pbenum.dart';

/// MessageContent 消息正文负载。
/// 对应后端 message.Content（JSON: type/text/media_url/thumb_url/size）。
class MessageContent extends $pb.GeneratedMessage {
  factory MessageContent({
    MessageType? type,
    $core.String? text,
    $core.String? mediaUrl,
    $core.String? thumbUrl,
    $fixnum.Int64? size,
  }) {
    final result = MessageContent._();
    if (type != null) result.type = type;
    if (text != null) result.text = text;
    if (mediaUrl != null) result.mediaUrl = mediaUrl;
    if (thumbUrl != null) result.thumbUrl = thumbUrl;
    if (size != null) result.size = size;
    return result;
  }

  MessageContent._();

  factory MessageContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageContent()..mergeFromBuffer(data, registry);
  factory MessageContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageContent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'depth.v1'),
      createEmptyInstance: MessageContent.$_createMessage)
    ..aE<MessageType>(1, _omitFieldNames ? '' : 'type',
        enumValues: MessageType.values)
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOS(3, _omitFieldNames ? '' : 'mediaUrl')
    ..aOS(4, _omitFieldNames ? '' : 'thumbUrl')
    ..aInt64(5, _omitFieldNames ? '' : 'size')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageContent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageContent copyWith(void Function(MessageContent) updates) =>
      super.copyWith((message) => updates(message as MessageContent))
          as MessageContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageContent() / MessageContent.new instead')
  static MessageContent create() => MessageContent._();
  static $pb.GeneratedMessage $_createMessage() => MessageContent._();
  @$core.override
  MessageContent createEmptyInstance() => MessageContent._();
  @$core.pragma('dart2js:noInline')
  static MessageContent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageContent>(
          MessageContent.$_createMessage);
  static MessageContent? _defaultInstance;

  @$pb.TagNumber(1)
  MessageType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(MessageType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get mediaUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set mediaUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMediaUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearMediaUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get thumbUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set thumbUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasThumbUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearThumbUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get size => $_getI64(4);
  @$pb.TagNumber(5)
  set size($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearSize() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
