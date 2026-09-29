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

/// CallState 通话状态机。
class CallState extends $pb.ProtobufEnum {
  static const CallState CALL_STATE_UNSPECIFIED =
      CallState._(0, _omitEnumNames ? '' : 'CALL_STATE_UNSPECIFIED');
  static const CallState CALL_STATE_INVITING =
      CallState._(1, _omitEnumNames ? '' : 'CALL_STATE_INVITING');
  static const CallState CALL_STATE_RINGING =
      CallState._(2, _omitEnumNames ? '' : 'CALL_STATE_RINGING');
  static const CallState CALL_STATE_CONNECTING =
      CallState._(3, _omitEnumNames ? '' : 'CALL_STATE_CONNECTING');
  static const CallState CALL_STATE_CONNECTED =
      CallState._(4, _omitEnumNames ? '' : 'CALL_STATE_CONNECTED');
  static const CallState CALL_STATE_ENDED =
      CallState._(5, _omitEnumNames ? '' : 'CALL_STATE_ENDED');
  static const CallState CALL_STATE_REJECTED =
      CallState._(6, _omitEnumNames ? '' : 'CALL_STATE_REJECTED');
  static const CallState CALL_STATE_MISSED =
      CallState._(7, _omitEnumNames ? '' : 'CALL_STATE_MISSED');

  static const $core.List<CallState> values = <CallState>[
    CALL_STATE_UNSPECIFIED,
    CALL_STATE_INVITING,
    CALL_STATE_RINGING,
    CALL_STATE_CONNECTING,
    CALL_STATE_CONNECTED,
    CALL_STATE_ENDED,
    CALL_STATE_REJECTED,
    CALL_STATE_MISSED,
  ];

  static final $core.List<CallState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static CallState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CallState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
