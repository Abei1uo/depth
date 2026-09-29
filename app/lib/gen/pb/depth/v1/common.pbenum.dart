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

import 'package:protobuf/protobuf.dart' as $pb;

/// MessageType 消息正文类型。
/// 取值与后端 internal/message/model.go 的常量严格对应。
class MessageType extends $pb.ProtobufEnum {
  static const MessageType MESSAGE_TYPE_TEXT =
      MessageType._(0, _omitEnumNames ? '' : 'MESSAGE_TYPE_TEXT');
  static const MessageType MESSAGE_TYPE_IMAGE =
      MessageType._(1, _omitEnumNames ? '' : 'MESSAGE_TYPE_IMAGE');
  static const MessageType MESSAGE_TYPE_FILE =
      MessageType._(2, _omitEnumNames ? '' : 'MESSAGE_TYPE_FILE');
  static const MessageType MESSAGE_TYPE_VOICE =
      MessageType._(3, _omitEnumNames ? '' : 'MESSAGE_TYPE_VOICE');
  static const MessageType MESSAGE_TYPE_SYS =
      MessageType._(4, _omitEnumNames ? '' : 'MESSAGE_TYPE_SYS');

  static const $core.List<MessageType> values = <MessageType>[
    MESSAGE_TYPE_TEXT,
    MESSAGE_TYPE_IMAGE,
    MESSAGE_TYPE_FILE,
    MESSAGE_TYPE_VOICE,
    MESSAGE_TYPE_SYS,
  ];

  static final $core.List<MessageType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static MessageType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MessageType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
