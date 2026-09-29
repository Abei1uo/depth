// This is a generated file - do not edit.
//
// Generated from depth/v1/chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// ConversationType 会话类型（对应 chat.TypeDirect/TypeGroup）。
class ConversationType extends $pb.ProtobufEnum {
  static const ConversationType CONVERSATION_TYPE_DIRECT =
      ConversationType._(0, _omitEnumNames ? '' : 'CONVERSATION_TYPE_DIRECT');
  static const ConversationType CONVERSATION_TYPE_GROUP =
      ConversationType._(1, _omitEnumNames ? '' : 'CONVERSATION_TYPE_GROUP');

  static const $core.List<ConversationType> values = <ConversationType>[
    CONVERSATION_TYPE_DIRECT,
    CONVERSATION_TYPE_GROUP,
  ];

  static final $core.List<ConversationType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static ConversationType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ConversationType._(super.value, super.name);
}

/// MemberRole 成员角色（对应建群时 owner=2、普通=0）。
class MemberRole extends $pb.ProtobufEnum {
  static const MemberRole MEMBER_ROLE_MEMBER =
      MemberRole._(0, _omitEnumNames ? '' : 'MEMBER_ROLE_MEMBER');
  static const MemberRole MEMBER_ROLE_OWNER =
      MemberRole._(2, _omitEnumNames ? '' : 'MEMBER_ROLE_OWNER');

  static const $core.List<MemberRole> values = <MemberRole>[
    MEMBER_ROLE_MEMBER,
    MEMBER_ROLE_OWNER,
  ];

  static final $core.Map<$core.int, MemberRole> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static MemberRole? valueOf($core.int value) => _byValue[value];

  const MemberRole._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
