// This is a generated file - do not edit.
//
// Generated from verdant/models.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class UserStatus extends $pb.ProtobufEnum {
  static const UserStatus USER_STATUS_UNSPECIFIED =
      UserStatus._(0, _omitEnumNames ? '' : 'USER_STATUS_UNSPECIFIED');
  static const UserStatus USER_STATUS_ONLINE =
      UserStatus._(1, _omitEnumNames ? '' : 'USER_STATUS_ONLINE');
  static const UserStatus USER_STATUS_IDLE =
      UserStatus._(2, _omitEnumNames ? '' : 'USER_STATUS_IDLE');
  static const UserStatus USER_STATUS_DND =
      UserStatus._(3, _omitEnumNames ? '' : 'USER_STATUS_DND');
  static const UserStatus USER_STATUS_OFFLINE =
      UserStatus._(4, _omitEnumNames ? '' : 'USER_STATUS_OFFLINE');

  static const $core.List<UserStatus> values = <UserStatus>[
    USER_STATUS_UNSPECIFIED,
    USER_STATUS_ONLINE,
    USER_STATUS_IDLE,
    USER_STATUS_DND,
    USER_STATUS_OFFLINE,
  ];

  static final $core.List<UserStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static UserStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UserStatus._(super.value, super.name);
}

/// 0=server text, 1=DM, 2=group DM, 3=server voice
class ChannelType extends $pb.ProtobufEnum {
  static const ChannelType CHANNEL_TYPE_SERVER_TEXT =
      ChannelType._(0, _omitEnumNames ? '' : 'CHANNEL_TYPE_SERVER_TEXT');
  static const ChannelType CHANNEL_TYPE_DM =
      ChannelType._(1, _omitEnumNames ? '' : 'CHANNEL_TYPE_DM');
  static const ChannelType CHANNEL_TYPE_GROUP_DM =
      ChannelType._(2, _omitEnumNames ? '' : 'CHANNEL_TYPE_GROUP_DM');
  static const ChannelType CHANNEL_TYPE_SERVER_VOICE =
      ChannelType._(3, _omitEnumNames ? '' : 'CHANNEL_TYPE_SERVER_VOICE');

  static const $core.List<ChannelType> values = <ChannelType>[
    CHANNEL_TYPE_SERVER_TEXT,
    CHANNEL_TYPE_DM,
    CHANNEL_TYPE_GROUP_DM,
    CHANNEL_TYPE_SERVER_VOICE,
  ];

  static final $core.List<ChannelType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ChannelType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ChannelType._(super.value, super.name);
}

/// 1=friend, 2=blocked, 3=pending_outgoing, 4=pending_incoming
class RelationshipType extends $pb.ProtobufEnum {
  static const RelationshipType RELATIONSHIP_TYPE_UNSPECIFIED =
      RelationshipType._(
          0, _omitEnumNames ? '' : 'RELATIONSHIP_TYPE_UNSPECIFIED');
  static const RelationshipType RELATIONSHIP_TYPE_FRIEND =
      RelationshipType._(1, _omitEnumNames ? '' : 'RELATIONSHIP_TYPE_FRIEND');
  static const RelationshipType RELATIONSHIP_TYPE_BLOCKED =
      RelationshipType._(2, _omitEnumNames ? '' : 'RELATIONSHIP_TYPE_BLOCKED');
  static const RelationshipType RELATIONSHIP_TYPE_PENDING_OUTGOING =
      RelationshipType._(
          3, _omitEnumNames ? '' : 'RELATIONSHIP_TYPE_PENDING_OUTGOING');
  static const RelationshipType RELATIONSHIP_TYPE_PENDING_INCOMING =
      RelationshipType._(
          4, _omitEnumNames ? '' : 'RELATIONSHIP_TYPE_PENDING_INCOMING');

  static const $core.List<RelationshipType> values = <RelationshipType>[
    RELATIONSHIP_TYPE_UNSPECIFIED,
    RELATIONSHIP_TYPE_FRIEND,
    RELATIONSHIP_TYPE_BLOCKED,
    RELATIONSHIP_TYPE_PENDING_OUTGOING,
    RELATIONSHIP_TYPE_PENDING_INCOMING,
  ];

  static final $core.List<RelationshipType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static RelationshipType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RelationshipType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
