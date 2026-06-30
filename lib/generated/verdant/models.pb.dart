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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'models.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'models.pbenum.dart';

class User extends $pb.GeneratedMessage {
  factory User({
    $core.String? id,
    $core.String? username,
    $core.String? email,
    $core.String? avatarUrl,
    UserStatus? status,
    $core.bool? subscribed,
    $core.String? createdAt,
    $core.String? updatedAt,
    $core.bool? usernameSet,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (username != null) result.username = username;
    if (email != null) result.email = email;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (status != null) result.status = status;
    if (subscribed != null) result.subscribed = subscribed;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (usernameSet != null) result.usernameSet = usernameSet;
    return result;
  }

  User._();

  factory User.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory User.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'User',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(4, _omitFieldNames ? '' : 'email')
    ..aOS(5, _omitFieldNames ? '' : 'avatarUrl')
    ..aE<UserStatus>(6, _omitFieldNames ? '' : 'status',
        enumValues: UserStatus.values)
    ..aOB(7, _omitFieldNames ? '' : 'subscribed')
    ..aOS(8, _omitFieldNames ? '' : 'createdAt')
    ..aOS(9, _omitFieldNames ? '' : 'updatedAt')
    ..aOB(10, _omitFieldNames ? '' : 'usernameSet')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User copyWith(void Function(User) updates) =>
      super.copyWith((message) => updates(message as User)) as User;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static User create() => User._();
  @$core.override
  User createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static User getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<User>(create);
  static User? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(4)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(4)
  set email($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(4)
  void clearEmail() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get avatarUrl => $_getSZ(3);
  @$pb.TagNumber(5)
  set avatarUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasAvatarUrl() => $_has(3);
  @$pb.TagNumber(5)
  void clearAvatarUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  UserStatus get status => $_getN(4);
  @$pb.TagNumber(6)
  set status(UserStatus value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(6)
  void clearStatus() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get subscribed => $_getBF(5);
  @$pb.TagNumber(7)
  set subscribed($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(7)
  $core.bool hasSubscribed() => $_has(5);
  @$pb.TagNumber(7)
  void clearSubscribed() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get createdAt => $_getSZ(6);
  @$pb.TagNumber(8)
  set createdAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(8)
  void clearCreatedAt() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get updatedAt => $_getSZ(7);
  @$pb.TagNumber(9)
  set updatedAt($core.String value) => $_setString(7, value);
  @$pb.TagNumber(9)
  $core.bool hasUpdatedAt() => $_has(7);
  @$pb.TagNumber(9)
  void clearUpdatedAt() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get usernameSet => $_getBF(8);
  @$pb.TagNumber(10)
  set usernameSet($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(10)
  $core.bool hasUsernameSet() => $_has(8);
  @$pb.TagNumber(10)
  void clearUsernameSet() => $_clearField(10);
}

class UserProfile extends $pb.GeneratedMessage {
  factory UserProfile({
    $core.String? id,
    $core.String? userId,
    $core.String? displayName,
    $core.String? bio,
    $core.String? bannerUrl,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (displayName != null) result.displayName = displayName;
    if (bio != null) result.bio = bio;
    if (bannerUrl != null) result.bannerUrl = bannerUrl;
    return result;
  }

  UserProfile._();

  factory UserProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserProfile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aOS(4, _omitFieldNames ? '' : 'bio')
    ..aOS(5, _omitFieldNames ? '' : 'bannerUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserProfile copyWith(void Function(UserProfile) updates) =>
      super.copyWith((message) => updates(message as UserProfile))
          as UserProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserProfile create() => UserProfile._();
  @$core.override
  UserProfile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserProfile>(create);
  static UserProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get bio => $_getSZ(3);
  @$pb.TagNumber(4)
  set bio($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBio() => $_has(3);
  @$pb.TagNumber(4)
  void clearBio() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get bannerUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set bannerUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBannerUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearBannerUrl() => $_clearField(5);
}

class MessageAuthor extends $pb.GeneratedMessage {
  factory MessageAuthor({
    $core.String? id,
    $core.String? username,
    $core.String? avatarUrl,
    $core.String? displayName,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (username != null) result.username = username;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  MessageAuthor._();

  factory MessageAuthor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageAuthor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageAuthor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(4, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageAuthor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageAuthor copyWith(void Function(MessageAuthor) updates) =>
      super.copyWith((message) => updates(message as MessageAuthor))
          as MessageAuthor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageAuthor create() => MessageAuthor._();
  @$core.override
  MessageAuthor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MessageAuthor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageAuthor>(create);
  static MessageAuthor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get avatarUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatarUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatarUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatarUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => $_clearField(4);
}

class Server extends $pb.GeneratedMessage {
  factory Server({
    $core.String? id,
    $core.String? name,
    $core.String? ownerId,
    $core.String? iconUrl,
    $core.String? description,
    $core.int? voiceBitrate,
    $core.String? createdAt,
    $core.String? updatedAt,
    $core.String? welcomeChannelId,
    $core.String? announceChannelId,
    $core.String? welcomeMessage,
    $core.int? emojiVersion,
    $core.bool? large,
    $fixnum.Int64? memberCount,
    $core.String? bannerUrl,
    $core.String? accentColor,
    $core.int? bannerOffsetY,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (ownerId != null) result.ownerId = ownerId;
    if (iconUrl != null) result.iconUrl = iconUrl;
    if (description != null) result.description = description;
    if (voiceBitrate != null) result.voiceBitrate = voiceBitrate;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (welcomeChannelId != null) result.welcomeChannelId = welcomeChannelId;
    if (announceChannelId != null) result.announceChannelId = announceChannelId;
    if (welcomeMessage != null) result.welcomeMessage = welcomeMessage;
    if (emojiVersion != null) result.emojiVersion = emojiVersion;
    if (large != null) result.large = large;
    if (memberCount != null) result.memberCount = memberCount;
    if (bannerUrl != null) result.bannerUrl = bannerUrl;
    if (accentColor != null) result.accentColor = accentColor;
    if (bannerOffsetY != null) result.bannerOffsetY = bannerOffsetY;
    return result;
  }

  Server._();

  factory Server.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Server.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Server',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'ownerId')
    ..aOS(4, _omitFieldNames ? '' : 'iconUrl')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..aI(6, _omitFieldNames ? '' : 'voiceBitrate')
    ..aOS(7, _omitFieldNames ? '' : 'createdAt')
    ..aOS(8, _omitFieldNames ? '' : 'updatedAt')
    ..aOS(9, _omitFieldNames ? '' : 'welcomeChannelId')
    ..aOS(10, _omitFieldNames ? '' : 'announceChannelId')
    ..aOS(11, _omitFieldNames ? '' : 'welcomeMessage')
    ..aI(12, _omitFieldNames ? '' : 'emojiVersion')
    ..aOB(13, _omitFieldNames ? '' : 'large')
    ..aInt64(14, _omitFieldNames ? '' : 'memberCount')
    ..aOS(15, _omitFieldNames ? '' : 'bannerUrl')
    ..aOS(16, _omitFieldNames ? '' : 'accentColor')
    ..aI(17, _omitFieldNames ? '' : 'bannerOffsetY')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Server clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Server copyWith(void Function(Server) updates) =>
      super.copyWith((message) => updates(message as Server)) as Server;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Server create() => Server._();
  @$core.override
  Server createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Server getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Server>(create);
  static Server? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get ownerId => $_getSZ(2);
  @$pb.TagNumber(3)
  set ownerId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOwnerId() => $_has(2);
  @$pb.TagNumber(3)
  void clearOwnerId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get iconUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set iconUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIconUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearIconUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get voiceBitrate => $_getIZ(5);
  @$pb.TagNumber(6)
  set voiceBitrate($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVoiceBitrate() => $_has(5);
  @$pb.TagNumber(6)
  void clearVoiceBitrate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get createdAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set createdAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get updatedAt => $_getSZ(7);
  @$pb.TagNumber(8)
  set updatedAt($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUpdatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearUpdatedAt() => $_clearField(8);

  /// Fields 9–14: added to match JSON READY server objects.
  @$pb.TagNumber(9)
  $core.String get welcomeChannelId => $_getSZ(8);
  @$pb.TagNumber(9)
  set welcomeChannelId($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasWelcomeChannelId() => $_has(8);
  @$pb.TagNumber(9)
  void clearWelcomeChannelId() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get announceChannelId => $_getSZ(9);
  @$pb.TagNumber(10)
  set announceChannelId($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAnnounceChannelId() => $_has(9);
  @$pb.TagNumber(10)
  void clearAnnounceChannelId() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get welcomeMessage => $_getSZ(10);
  @$pb.TagNumber(11)
  set welcomeMessage($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasWelcomeMessage() => $_has(10);
  @$pb.TagNumber(11)
  void clearWelcomeMessage() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get emojiVersion => $_getIZ(11);
  @$pb.TagNumber(12)
  set emojiVersion($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasEmojiVersion() => $_has(11);
  @$pb.TagNumber(12)
  void clearEmojiVersion() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get large => $_getBF(12);
  @$pb.TagNumber(13)
  set large($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasLarge() => $_has(12);
  @$pb.TagNumber(13)
  void clearLarge() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get memberCount => $_getI64(13);
  @$pb.TagNumber(14)
  set memberCount($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasMemberCount() => $_has(13);
  @$pb.TagNumber(14)
  void clearMemberCount() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get bannerUrl => $_getSZ(14);
  @$pb.TagNumber(15)
  set bannerUrl($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasBannerUrl() => $_has(14);
  @$pb.TagNumber(15)
  void clearBannerUrl() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get accentColor => $_getSZ(15);
  @$pb.TagNumber(16)
  set accentColor($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasAccentColor() => $_has(15);
  @$pb.TagNumber(16)
  void clearAccentColor() => $_clearField(16);

  /// Vertical focal point of the banner (0-100). 0 = top, 50 = center,
  /// 100 = bottom. Applied client-side as object-position Y%.
  @$pb.TagNumber(17)
  $core.int get bannerOffsetY => $_getIZ(16);
  @$pb.TagNumber(17)
  set bannerOffsetY($core.int value) => $_setSignedInt32(16, value);
  @$pb.TagNumber(17)
  $core.bool hasBannerOffsetY() => $_has(16);
  @$pb.TagNumber(17)
  void clearBannerOffsetY() => $_clearField(17);
}

class ServerMember extends $pb.GeneratedMessage {
  factory ServerMember({
    $core.String? id,
    $core.String? userId,
    $core.String? serverId,
    $core.String? nickname,
    $core.Iterable<$core.String>? roleIds,
    $core.String? joinedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (serverId != null) result.serverId = serverId;
    if (nickname != null) result.nickname = nickname;
    if (roleIds != null) result.roleIds.addAll(roleIds);
    if (joinedAt != null) result.joinedAt = joinedAt;
    return result;
  }

  ServerMember._();

  factory ServerMember.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerMember.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerMember',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'serverId')
    ..aOS(4, _omitFieldNames ? '' : 'nickname')
    ..pPS(5, _omitFieldNames ? '' : 'roleIds')
    ..aOS(6, _omitFieldNames ? '' : 'joinedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerMember clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerMember copyWith(void Function(ServerMember) updates) =>
      super.copyWith((message) => updates(message as ServerMember))
          as ServerMember;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerMember create() => ServerMember._();
  @$core.override
  ServerMember createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerMember getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerMember>(create);
  static ServerMember? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get serverId => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerId() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get nickname => $_getSZ(3);
  @$pb.TagNumber(4)
  set nickname($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNickname() => $_has(3);
  @$pb.TagNumber(4)
  void clearNickname() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get roleIds => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get joinedAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set joinedAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasJoinedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearJoinedAt() => $_clearField(6);
}

class Channel extends $pb.GeneratedMessage {
  factory Channel({
    $core.String? id,
    ChannelType? type,
    $core.String? serverId,
    $core.String? name,
    $core.String? topic,
    $core.int? position,
    $core.String? categoryId,
    $core.String? createdAt,
    $core.bool? readOnly,
    $core.int? slowmodeSeconds,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (serverId != null) result.serverId = serverId;
    if (name != null) result.name = name;
    if (topic != null) result.topic = topic;
    if (position != null) result.position = position;
    if (categoryId != null) result.categoryId = categoryId;
    if (createdAt != null) result.createdAt = createdAt;
    if (readOnly != null) result.readOnly = readOnly;
    if (slowmodeSeconds != null) result.slowmodeSeconds = slowmodeSeconds;
    return result;
  }

  Channel._();

  factory Channel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Channel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Channel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ChannelType>(2, _omitFieldNames ? '' : 'type',
        enumValues: ChannelType.values)
    ..aOS(3, _omitFieldNames ? '' : 'serverId')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'topic')
    ..aI(6, _omitFieldNames ? '' : 'position')
    ..aOS(7, _omitFieldNames ? '' : 'categoryId')
    ..aOS(8, _omitFieldNames ? '' : 'createdAt')
    ..aOB(9, _omitFieldNames ? '' : 'readOnly')
    ..aI(10, _omitFieldNames ? '' : 'slowmodeSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Channel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Channel copyWith(void Function(Channel) updates) =>
      super.copyWith((message) => updates(message as Channel)) as Channel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Channel create() => Channel._();
  @$core.override
  Channel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Channel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Channel>(create);
  static Channel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ChannelType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(ChannelType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get serverId => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerId() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get topic => $_getSZ(4);
  @$pb.TagNumber(5)
  set topic($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTopic() => $_has(4);
  @$pb.TagNumber(5)
  void clearTopic() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get position => $_getIZ(5);
  @$pb.TagNumber(6)
  set position($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPosition() => $_has(5);
  @$pb.TagNumber(6)
  void clearPosition() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get categoryId => $_getSZ(6);
  @$pb.TagNumber(7)
  set categoryId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCategoryId() => $_has(6);
  @$pb.TagNumber(7)
  void clearCategoryId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get createdAt => $_getSZ(7);
  @$pb.TagNumber(8)
  set createdAt($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAt() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get readOnly => $_getBF(8);
  @$pb.TagNumber(9)
  set readOnly($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasReadOnly() => $_has(8);
  @$pb.TagNumber(9)
  void clearReadOnly() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get slowmodeSeconds => $_getIZ(9);
  @$pb.TagNumber(10)
  set slowmodeSeconds($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSlowmodeSeconds() => $_has(9);
  @$pb.TagNumber(10)
  void clearSlowmodeSeconds() => $_clearField(10);
}

class ChannelReadState extends $pb.GeneratedMessage {
  factory ChannelReadState({
    $core.String? channelId,
    $core.String? lastReadMessageId,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (lastReadMessageId != null) result.lastReadMessageId = lastReadMessageId;
    return result;
  }

  ChannelReadState._();

  factory ChannelReadState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelReadState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelReadState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'lastReadMessageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelReadState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelReadState copyWith(void Function(ChannelReadState) updates) =>
      super.copyWith((message) => updates(message as ChannelReadState))
          as ChannelReadState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelReadState create() => ChannelReadState._();
  @$core.override
  ChannelReadState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChannelReadState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelReadState>(create);
  static ChannelReadState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get lastReadMessageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set lastReadMessageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLastReadMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastReadMessageId() => $_clearField(2);
}

class Category extends $pb.GeneratedMessage {
  factory Category({
    $core.String? id,
    $core.String? serverId,
    $core.String? name,
    $core.int? position,
    $core.String? createdAt,
    $core.String? emoji,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (serverId != null) result.serverId = serverId;
    if (name != null) result.name = name;
    if (position != null) result.position = position;
    if (createdAt != null) result.createdAt = createdAt;
    if (emoji != null) result.emoji = emoji;
    return result;
  }

  Category._();

  factory Category.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Category.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Category',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aI(4, _omitFieldNames ? '' : 'position')
    ..aOS(5, _omitFieldNames ? '' : 'createdAt')
    ..aOS(6, _omitFieldNames ? '' : 'emoji')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Category clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Category copyWith(void Function(Category) updates) =>
      super.copyWith((message) => updates(message as Category)) as Category;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Category create() => Category._();
  @$core.override
  Category createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Category getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Category>(create);
  static Category? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get position => $_getIZ(3);
  @$pb.TagNumber(4)
  set position($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get createdAt => $_getSZ(4);
  @$pb.TagNumber(5)
  set createdAt($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get emoji => $_getSZ(5);
  @$pb.TagNumber(6)
  set emoji($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEmoji() => $_has(5);
  @$pb.TagNumber(6)
  void clearEmoji() => $_clearField(6);
}

class Attachment extends $pb.GeneratedMessage {
  factory Attachment({
    $core.String? id,
    $core.String? messageId,
    $core.String? filename,
    $core.String? url,
    $core.String? contentType,
    $core.int? size,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (messageId != null) result.messageId = messageId;
    if (filename != null) result.filename = filename;
    if (url != null) result.url = url;
    if (contentType != null) result.contentType = contentType;
    if (size != null) result.size = size;
    return result;
  }

  Attachment._();

  factory Attachment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Attachment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Attachment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'filename')
    ..aOS(4, _omitFieldNames ? '' : 'url')
    ..aOS(5, _omitFieldNames ? '' : 'contentType')
    ..aI(6, _omitFieldNames ? '' : 'size')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Attachment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Attachment copyWith(void Function(Attachment) updates) =>
      super.copyWith((message) => updates(message as Attachment)) as Attachment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Attachment create() => Attachment._();
  @$core.override
  Attachment createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Attachment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Attachment>(create);
  static Attachment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get filename => $_getSZ(2);
  @$pb.TagNumber(3)
  set filename($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFilename() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilename() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get url => $_getSZ(3);
  @$pb.TagNumber(4)
  set url($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get contentType => $_getSZ(4);
  @$pb.TagNumber(5)
  set contentType($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContentType() => $_has(4);
  @$pb.TagNumber(5)
  void clearContentType() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get size => $_getIZ(5);
  @$pb.TagNumber(6)
  set size($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSize() => $_has(5);
  @$pb.TagNumber(6)
  void clearSize() => $_clearField(6);
}

class Reaction extends $pb.GeneratedMessage {
  factory Reaction({
    $core.String? emoji,
    $core.String? emojiId,
    $core.int? count,
    $core.bool? me,
  }) {
    final result = create();
    if (emoji != null) result.emoji = emoji;
    if (emojiId != null) result.emojiId = emojiId;
    if (count != null) result.count = count;
    if (me != null) result.me = me;
    return result;
  }

  Reaction._();

  factory Reaction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Reaction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Reaction',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'emoji')
    ..aOS(2, _omitFieldNames ? '' : 'emojiId')
    ..aI(3, _omitFieldNames ? '' : 'count')
    ..aOB(4, _omitFieldNames ? '' : 'me')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Reaction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Reaction copyWith(void Function(Reaction) updates) =>
      super.copyWith((message) => updates(message as Reaction)) as Reaction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Reaction create() => Reaction._();
  @$core.override
  Reaction createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Reaction getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Reaction>(create);
  static Reaction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get emoji => $_getSZ(0);
  @$pb.TagNumber(1)
  set emoji($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEmoji() => $_has(0);
  @$pb.TagNumber(1)
  void clearEmoji() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get emojiId => $_getSZ(1);
  @$pb.TagNumber(2)
  set emojiId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEmojiId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmojiId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get count => $_getIZ(2);
  @$pb.TagNumber(3)
  set count($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get me => $_getBF(3);
  @$pb.TagNumber(4)
  set me($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMe() => $_has(3);
  @$pb.TagNumber(4)
  void clearMe() => $_clearField(4);
}

class ReplySnapshot extends $pb.GeneratedMessage {
  factory ReplySnapshot({
    $core.String? id,
    $core.String? content,
    MessageAuthor? author,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (content != null) result.content = content;
    if (author != null) result.author = author;
    return result;
  }

  ReplySnapshot._();

  factory ReplySnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplySnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplySnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..aOM<MessageAuthor>(3, _omitFieldNames ? '' : 'author',
        subBuilder: MessageAuthor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplySnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplySnapshot copyWith(void Function(ReplySnapshot) updates) =>
      super.copyWith((message) => updates(message as ReplySnapshot))
          as ReplySnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplySnapshot create() => ReplySnapshot._();
  @$core.override
  ReplySnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReplySnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplySnapshot>(create);
  static ReplySnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => $_clearField(2);

  @$pb.TagNumber(3)
  MessageAuthor get author => $_getN(2);
  @$pb.TagNumber(3)
  set author(MessageAuthor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthor() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthor() => $_clearField(3);
  @$pb.TagNumber(3)
  MessageAuthor ensureAuthor() => $_ensure(2);
}

class Message extends $pb.GeneratedMessage {
  factory Message({
    $core.String? id,
    $core.String? channelId,
    $core.String? authorId,
    MessageAuthor? author,
    $core.String? content,
    $core.Iterable<Attachment>? attachments,
    $core.Iterable<Reaction>? reactions,
    $core.bool? edited,
    $core.String? createdAt,
    $core.String? updatedAt,
    $core.String? nonce,
    $core.int? type,
    ReplySnapshot? replyTo,
    $core.String? editedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (channelId != null) result.channelId = channelId;
    if (authorId != null) result.authorId = authorId;
    if (author != null) result.author = author;
    if (content != null) result.content = content;
    if (attachments != null) result.attachments.addAll(attachments);
    if (reactions != null) result.reactions.addAll(reactions);
    if (edited != null) result.edited = edited;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (nonce != null) result.nonce = nonce;
    if (type != null) result.type = type;
    if (replyTo != null) result.replyTo = replyTo;
    if (editedAt != null) result.editedAt = editedAt;
    return result;
  }

  Message._();

  factory Message.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Message.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Message',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aOS(3, _omitFieldNames ? '' : 'authorId')
    ..aOM<MessageAuthor>(4, _omitFieldNames ? '' : 'author',
        subBuilder: MessageAuthor.create)
    ..aOS(5, _omitFieldNames ? '' : 'content')
    ..pPM<Attachment>(6, _omitFieldNames ? '' : 'attachments',
        subBuilder: Attachment.create)
    ..pPM<Reaction>(7, _omitFieldNames ? '' : 'reactions',
        subBuilder: Reaction.create)
    ..aOB(8, _omitFieldNames ? '' : 'edited')
    ..aOS(9, _omitFieldNames ? '' : 'createdAt')
    ..aOS(10, _omitFieldNames ? '' : 'updatedAt')
    ..aOS(11, _omitFieldNames ? '' : 'nonce')
    ..aI(12, _omitFieldNames ? '' : 'type')
    ..aOM<ReplySnapshot>(13, _omitFieldNames ? '' : 'replyTo',
        subBuilder: ReplySnapshot.create)
    ..aOS(14, _omitFieldNames ? '' : 'editedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message copyWith(void Function(Message) updates) =>
      super.copyWith((message) => updates(message as Message)) as Message;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Message create() => Message._();
  @$core.override
  Message createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Message getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Message>(create);
  static Message? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get authorId => $_getSZ(2);
  @$pb.TagNumber(3)
  set authorId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthorId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthorId() => $_clearField(3);

  @$pb.TagNumber(4)
  MessageAuthor get author => $_getN(3);
  @$pb.TagNumber(4)
  set author(MessageAuthor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthor() => $_clearField(4);
  @$pb.TagNumber(4)
  MessageAuthor ensureAuthor() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get content => $_getSZ(4);
  @$pb.TagNumber(5)
  set content($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContent() => $_has(4);
  @$pb.TagNumber(5)
  void clearContent() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<Attachment> get attachments => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<Reaction> get reactions => $_getList(6);

  @$pb.TagNumber(8)
  $core.bool get edited => $_getBF(7);
  @$pb.TagNumber(8)
  set edited($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEdited() => $_has(7);
  @$pb.TagNumber(8)
  void clearEdited() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get createdAt => $_getSZ(8);
  @$pb.TagNumber(9)
  set createdAt($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedAt() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get updatedAt => $_getSZ(9);
  @$pb.TagNumber(10)
  set updatedAt($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUpdatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedAt() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get nonce => $_getSZ(10);
  @$pb.TagNumber(11)
  set nonce($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasNonce() => $_has(10);
  @$pb.TagNumber(11)
  void clearNonce() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get type => $_getIZ(11);
  @$pb.TagNumber(12)
  set type($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasType() => $_has(11);
  @$pb.TagNumber(12)
  void clearType() => $_clearField(12);

  @$pb.TagNumber(13)
  ReplySnapshot get replyTo => $_getN(12);
  @$pb.TagNumber(13)
  set replyTo(ReplySnapshot value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasReplyTo() => $_has(12);
  @$pb.TagNumber(13)
  void clearReplyTo() => $_clearField(13);
  @$pb.TagNumber(13)
  ReplySnapshot ensureReplyTo() => $_ensure(12);

  @$pb.TagNumber(14)
  $core.String get editedAt => $_getSZ(13);
  @$pb.TagNumber(14)
  set editedAt($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasEditedAt() => $_has(13);
  @$pb.TagNumber(14)
  void clearEditedAt() => $_clearField(14);
}

class Role extends $pb.GeneratedMessage {
  factory Role({
    $core.String? id,
    $core.String? serverId,
    $core.String? name,
    $core.String? color,
    $core.String? permissions,
    $core.int? position,
    $core.String? createdAt,
    $core.String? updatedAt,
    $core.bool? colorOnly,
    $core.bool? showAsSection,
    $core.int? colorPriority,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (serverId != null) result.serverId = serverId;
    if (name != null) result.name = name;
    if (color != null) result.color = color;
    if (permissions != null) result.permissions = permissions;
    if (position != null) result.position = position;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (colorOnly != null) result.colorOnly = colorOnly;
    if (showAsSection != null) result.showAsSection = showAsSection;
    if (colorPriority != null) result.colorPriority = colorPriority;
    return result;
  }

  Role._();

  factory Role.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Role.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Role',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'color')
    ..aOS(5, _omitFieldNames ? '' : 'permissions')
    ..aI(6, _omitFieldNames ? '' : 'position')
    ..aOS(7, _omitFieldNames ? '' : 'createdAt')
    ..aOS(8, _omitFieldNames ? '' : 'updatedAt')
    ..aOB(9, _omitFieldNames ? '' : 'colorOnly')
    ..aOB(10, _omitFieldNames ? '' : 'showAsSection')
    ..aI(11, _omitFieldNames ? '' : 'colorPriority')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Role clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Role copyWith(void Function(Role) updates) =>
      super.copyWith((message) => updates(message as Role)) as Role;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Role create() => Role._();
  @$core.override
  Role createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Role getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Role>(create);
  static Role? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get color => $_getSZ(3);
  @$pb.TagNumber(4)
  set color($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasColor() => $_has(3);
  @$pb.TagNumber(4)
  void clearColor() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get permissions => $_getSZ(4);
  @$pb.TagNumber(5)
  set permissions($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPermissions() => $_has(4);
  @$pb.TagNumber(5)
  void clearPermissions() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get position => $_getIZ(5);
  @$pb.TagNumber(6)
  set position($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPosition() => $_has(5);
  @$pb.TagNumber(6)
  void clearPosition() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get createdAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set createdAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get updatedAt => $_getSZ(7);
  @$pb.TagNumber(8)
  set updatedAt($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUpdatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearUpdatedAt() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get colorOnly => $_getBF(8);
  @$pb.TagNumber(9)
  set colorOnly($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasColorOnly() => $_has(8);
  @$pb.TagNumber(9)
  void clearColorOnly() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get showAsSection => $_getBF(9);
  @$pb.TagNumber(10)
  set showAsSection($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasShowAsSection() => $_has(9);
  @$pb.TagNumber(10)
  void clearShowAsSection() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get colorPriority => $_getIZ(10);
  @$pb.TagNumber(11)
  set colorPriority($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasColorPriority() => $_has(10);
  @$pb.TagNumber(11)
  void clearColorPriority() => $_clearField(11);
}

class Emoji extends $pb.GeneratedMessage {
  factory Emoji({
    $core.String? id,
    $core.String? serverId,
    $core.String? name,
    $core.String? url,
    $core.String? createdBy,
    $core.String? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (serverId != null) result.serverId = serverId;
    if (name != null) result.name = name;
    if (url != null) result.url = url;
    if (createdBy != null) result.createdBy = createdBy;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  Emoji._();

  factory Emoji.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Emoji.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Emoji',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'url')
    ..aOS(5, _omitFieldNames ? '' : 'createdBy')
    ..aOS(6, _omitFieldNames ? '' : 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Emoji clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Emoji copyWith(void Function(Emoji) updates) =>
      super.copyWith((message) => updates(message as Emoji)) as Emoji;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Emoji create() => Emoji._();
  @$core.override
  Emoji createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Emoji getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Emoji>(create);
  static Emoji? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get url => $_getSZ(3);
  @$pb.TagNumber(4)
  set url($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get createdBy => $_getSZ(4);
  @$pb.TagNumber(5)
  set createdBy($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedBy() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedBy() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get createdAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set createdAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
}

class VoiceState extends $pb.GeneratedMessage {
  factory VoiceState({
    $core.String? userId,
    $core.String? channelId,
    $core.String? serverId,
    $core.bool? selfMute,
    $core.bool? selfDeaf,
    $core.bool? serverMute,
    $core.bool? serverDeaf,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (channelId != null) result.channelId = channelId;
    if (serverId != null) result.serverId = serverId;
    if (selfMute != null) result.selfMute = selfMute;
    if (selfDeaf != null) result.selfDeaf = selfDeaf;
    if (serverMute != null) result.serverMute = serverMute;
    if (serverDeaf != null) result.serverDeaf = serverDeaf;
    return result;
  }

  VoiceState._();

  factory VoiceState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VoiceState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VoiceState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aOS(3, _omitFieldNames ? '' : 'serverId')
    ..aOB(4, _omitFieldNames ? '' : 'selfMute')
    ..aOB(5, _omitFieldNames ? '' : 'selfDeaf')
    ..aOB(6, _omitFieldNames ? '' : 'serverMute')
    ..aOB(7, _omitFieldNames ? '' : 'serverDeaf')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoiceState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoiceState copyWith(void Function(VoiceState) updates) =>
      super.copyWith((message) => updates(message as VoiceState)) as VoiceState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VoiceState create() => VoiceState._();
  @$core.override
  VoiceState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VoiceState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VoiceState>(create);
  static VoiceState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get serverId => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerId() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get selfMute => $_getBF(3);
  @$pb.TagNumber(4)
  set selfMute($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSelfMute() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelfMute() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get selfDeaf => $_getBF(4);
  @$pb.TagNumber(5)
  set selfDeaf($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSelfDeaf() => $_has(4);
  @$pb.TagNumber(5)
  void clearSelfDeaf() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get serverMute => $_getBF(5);
  @$pb.TagNumber(6)
  set serverMute($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasServerMute() => $_has(5);
  @$pb.TagNumber(6)
  void clearServerMute() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get serverDeaf => $_getBF(6);
  @$pb.TagNumber(7)
  set serverDeaf($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasServerDeaf() => $_has(6);
  @$pb.TagNumber(7)
  void clearServerDeaf() => $_clearField(7);
}

class Invite extends $pb.GeneratedMessage {
  factory Invite({
    $core.String? code,
    $core.String? serverId,
    $core.String? inviterId,
    $core.String? inviterUsername,
    $core.int? maxUses,
    $core.int? uses,
    $core.String? expiresAt,
    $core.String? createdAt,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (serverId != null) result.serverId = serverId;
    if (inviterId != null) result.inviterId = inviterId;
    if (inviterUsername != null) result.inviterUsername = inviterUsername;
    if (maxUses != null) result.maxUses = maxUses;
    if (uses != null) result.uses = uses;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  Invite._();

  factory Invite.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Invite.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Invite',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..aOS(3, _omitFieldNames ? '' : 'inviterId')
    ..aOS(4, _omitFieldNames ? '' : 'inviterUsername')
    ..aI(5, _omitFieldNames ? '' : 'maxUses')
    ..aI(6, _omitFieldNames ? '' : 'uses')
    ..aOS(7, _omitFieldNames ? '' : 'expiresAt')
    ..aOS(8, _omitFieldNames ? '' : 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Invite clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Invite copyWith(void Function(Invite) updates) =>
      super.copyWith((message) => updates(message as Invite)) as Invite;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Invite create() => Invite._();
  @$core.override
  Invite createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Invite getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Invite>(create);
  static Invite? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get inviterId => $_getSZ(2);
  @$pb.TagNumber(3)
  set inviterId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInviterId() => $_has(2);
  @$pb.TagNumber(3)
  void clearInviterId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get inviterUsername => $_getSZ(3);
  @$pb.TagNumber(4)
  set inviterUsername($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInviterUsername() => $_has(3);
  @$pb.TagNumber(4)
  void clearInviterUsername() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get maxUses => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxUses($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxUses() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxUses() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get uses => $_getIZ(5);
  @$pb.TagNumber(6)
  set uses($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUses() => $_has(5);
  @$pb.TagNumber(6)
  void clearUses() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get expiresAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set expiresAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasExpiresAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearExpiresAt() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get createdAt => $_getSZ(7);
  @$pb.TagNumber(8)
  set createdAt($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAt() => $_clearField(8);
}

class InvitePreviewServer extends $pb.GeneratedMessage {
  factory InvitePreviewServer({
    $core.String? id,
    $core.String? name,
    $core.String? iconUrl,
    $core.int? memberCount,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (iconUrl != null) result.iconUrl = iconUrl;
    if (memberCount != null) result.memberCount = memberCount;
    return result;
  }

  InvitePreviewServer._();

  factory InvitePreviewServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InvitePreviewServer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvitePreviewServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'iconUrl')
    ..aI(4, _omitFieldNames ? '' : 'memberCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvitePreviewServer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvitePreviewServer copyWith(void Function(InvitePreviewServer) updates) =>
      super.copyWith((message) => updates(message as InvitePreviewServer))
          as InvitePreviewServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InvitePreviewServer create() => InvitePreviewServer._();
  @$core.override
  InvitePreviewServer createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InvitePreviewServer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvitePreviewServer>(create);
  static InvitePreviewServer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get iconUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set iconUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIconUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearIconUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get memberCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set memberCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMemberCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearMemberCount() => $_clearField(4);
}

class InvitePreview extends $pb.GeneratedMessage {
  factory InvitePreview({
    $core.String? code,
    InvitePreviewServer? server,
    $core.String? inviterUsername,
    $core.String? expiresAt,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (server != null) result.server = server;
    if (inviterUsername != null) result.inviterUsername = inviterUsername;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  InvitePreview._();

  factory InvitePreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InvitePreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvitePreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOM<InvitePreviewServer>(2, _omitFieldNames ? '' : 'server',
        subBuilder: InvitePreviewServer.create)
    ..aOS(3, _omitFieldNames ? '' : 'inviterUsername')
    ..aOS(4, _omitFieldNames ? '' : 'expiresAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvitePreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvitePreview copyWith(void Function(InvitePreview) updates) =>
      super.copyWith((message) => updates(message as InvitePreview))
          as InvitePreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InvitePreview create() => InvitePreview._();
  @$core.override
  InvitePreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InvitePreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvitePreview>(create);
  static InvitePreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  InvitePreviewServer get server => $_getN(1);
  @$pb.TagNumber(2)
  set server(InvitePreviewServer value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearServer() => $_clearField(2);
  @$pb.TagNumber(2)
  InvitePreviewServer ensureServer() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get inviterUsername => $_getSZ(2);
  @$pb.TagNumber(3)
  set inviterUsername($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInviterUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearInviterUsername() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get expiresAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set expiresAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExpiresAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiresAt() => $_clearField(4);
}

class RelationshipUser extends $pb.GeneratedMessage {
  factory RelationshipUser({
    $core.String? id,
    $core.String? username,
    $core.String? avatarUrl,
    $core.String? status,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (username != null) result.username = username;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (status != null) result.status = status;
    return result;
  }

  RelationshipUser._();

  factory RelationshipUser.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelationshipUser.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelationshipUser',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(5, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelationshipUser clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelationshipUser copyWith(void Function(RelationshipUser) updates) =>
      super.copyWith((message) => updates(message as RelationshipUser))
          as RelationshipUser;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelationshipUser create() => RelationshipUser._();
  @$core.override
  RelationshipUser createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelationshipUser getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelationshipUser>(create);
  static RelationshipUser? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(4)
  $core.String get avatarUrl => $_getSZ(2);
  @$pb.TagNumber(4)
  set avatarUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasAvatarUrl() => $_has(2);
  @$pb.TagNumber(4)
  void clearAvatarUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get status => $_getSZ(3);
  @$pb.TagNumber(5)
  set status($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(5)
  void clearStatus() => $_clearField(5);
}

class Relationship extends $pb.GeneratedMessage {
  factory Relationship({
    $core.String? userId,
    RelationshipType? type,
    RelationshipUser? user,
    $core.String? createdAt,
    $core.String? notes,
    $core.String? nicknameColor,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (type != null) result.type = type;
    if (user != null) result.user = user;
    if (createdAt != null) result.createdAt = createdAt;
    if (notes != null) result.notes = notes;
    if (nicknameColor != null) result.nicknameColor = nicknameColor;
    return result;
  }

  Relationship._();

  factory Relationship.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Relationship.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Relationship',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aE<RelationshipType>(2, _omitFieldNames ? '' : 'type',
        enumValues: RelationshipType.values)
    ..aOM<RelationshipUser>(3, _omitFieldNames ? '' : 'user',
        subBuilder: RelationshipUser.create)
    ..aOS(4, _omitFieldNames ? '' : 'createdAt')
    ..aOS(5, _omitFieldNames ? '' : 'notes')
    ..aOS(6, _omitFieldNames ? '' : 'nicknameColor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Relationship clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Relationship copyWith(void Function(Relationship) updates) =>
      super.copyWith((message) => updates(message as Relationship))
          as Relationship;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Relationship create() => Relationship._();
  @$core.override
  Relationship createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Relationship getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Relationship>(create);
  static Relationship? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  RelationshipType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(RelationshipType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  RelationshipUser get user => $_getN(2);
  @$pb.TagNumber(3)
  set user(RelationshipUser value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasUser() => $_has(2);
  @$pb.TagNumber(3)
  void clearUser() => $_clearField(3);
  @$pb.TagNumber(3)
  RelationshipUser ensureUser() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get createdAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set createdAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get notes => $_getSZ(4);
  @$pb.TagNumber(5)
  set notes($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNotes() => $_has(4);
  @$pb.TagNumber(5)
  void clearNotes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get nicknameColor => $_getSZ(5);
  @$pb.TagNumber(6)
  set nicknameColor($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNicknameColor() => $_has(5);
  @$pb.TagNumber(6)
  void clearNicknameColor() => $_clearField(6);
}

class Feed extends $pb.GeneratedMessage {
  factory Feed({
    $core.String? id,
    $core.String? serverId,
    $core.String? name,
    $core.String? description,
    $core.Iterable<$core.String>? publishRoleIds,
    $core.Iterable<$core.String>? viewRoleIds,
    $core.String? createdAt,
    $core.String? icon,
    $core.int? position,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (serverId != null) result.serverId = serverId;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (publishRoleIds != null) result.publishRoleIds.addAll(publishRoleIds);
    if (viewRoleIds != null) result.viewRoleIds.addAll(viewRoleIds);
    if (createdAt != null) result.createdAt = createdAt;
    if (icon != null) result.icon = icon;
    if (position != null) result.position = position;
    return result;
  }

  Feed._();

  factory Feed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Feed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Feed',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..pPS(5, _omitFieldNames ? '' : 'publishRoleIds')
    ..pPS(6, _omitFieldNames ? '' : 'viewRoleIds')
    ..aOS(7, _omitFieldNames ? '' : 'createdAt')
    ..aOS(8, _omitFieldNames ? '' : 'icon')
    ..aI(9, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Feed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Feed copyWith(void Function(Feed) updates) =>
      super.copyWith((message) => updates(message as Feed)) as Feed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Feed create() => Feed._();
  @$core.override
  Feed createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Feed getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Feed>(create);
  static Feed? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get publishRoleIds => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get viewRoleIds => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get createdAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set createdAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get icon => $_getSZ(7);
  @$pb.TagNumber(8)
  set icon($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIcon() => $_has(7);
  @$pb.TagNumber(8)
  void clearIcon() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get position => $_getIZ(8);
  @$pb.TagNumber(9)
  set position($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPosition() => $_has(8);
  @$pb.TagNumber(9)
  void clearPosition() => $_clearField(9);
}

class Announcement extends $pb.GeneratedMessage {
  factory Announcement({
    $core.String? id,
    $core.String? feedId,
    $core.String? serverId,
    $core.String? title,
    $core.String? content,
    $core.String? authorId,
    $core.String? authorUsername,
    $core.String? authorAvatar,
    $core.String? createdAt,
    $core.String? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (feedId != null) result.feedId = feedId;
    if (serverId != null) result.serverId = serverId;
    if (title != null) result.title = title;
    if (content != null) result.content = content;
    if (authorId != null) result.authorId = authorId;
    if (authorUsername != null) result.authorUsername = authorUsername;
    if (authorAvatar != null) result.authorAvatar = authorAvatar;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  Announcement._();

  factory Announcement.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Announcement.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Announcement',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'feedId')
    ..aOS(3, _omitFieldNames ? '' : 'serverId')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'content')
    ..aOS(6, _omitFieldNames ? '' : 'authorId')
    ..aOS(7, _omitFieldNames ? '' : 'authorUsername')
    ..aOS(8, _omitFieldNames ? '' : 'authorAvatar')
    ..aOS(9, _omitFieldNames ? '' : 'createdAt')
    ..aOS(10, _omitFieldNames ? '' : 'updatedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Announcement clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Announcement copyWith(void Function(Announcement) updates) =>
      super.copyWith((message) => updates(message as Announcement))
          as Announcement;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Announcement create() => Announcement._();
  @$core.override
  Announcement createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Announcement getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Announcement>(create);
  static Announcement? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get feedId => $_getSZ(1);
  @$pb.TagNumber(2)
  set feedId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFeedId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeedId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get serverId => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerId() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get content => $_getSZ(4);
  @$pb.TagNumber(5)
  set content($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContent() => $_has(4);
  @$pb.TagNumber(5)
  void clearContent() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get authorId => $_getSZ(5);
  @$pb.TagNumber(6)
  set authorId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAuthorId() => $_has(5);
  @$pb.TagNumber(6)
  void clearAuthorId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get authorUsername => $_getSZ(6);
  @$pb.TagNumber(7)
  set authorUsername($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAuthorUsername() => $_has(6);
  @$pb.TagNumber(7)
  void clearAuthorUsername() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get authorAvatar => $_getSZ(7);
  @$pb.TagNumber(8)
  set authorAvatar($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAuthorAvatar() => $_has(7);
  @$pb.TagNumber(8)
  void clearAuthorAvatar() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get createdAt => $_getSZ(8);
  @$pb.TagNumber(9)
  set createdAt($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedAt() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get updatedAt => $_getSZ(9);
  @$pb.TagNumber(10)
  set updatedAt($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUpdatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedAt() => $_clearField(10);
}

class DmParticipant extends $pb.GeneratedMessage {
  factory DmParticipant({
    $core.String? id,
    $core.String? username,
    $core.String? avatarUrl,
    $core.String? status,
    $core.String? displayName,
    $core.String? nameColor,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (username != null) result.username = username;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (status != null) result.status = status;
    if (displayName != null) result.displayName = displayName;
    if (nameColor != null) result.nameColor = nameColor;
    return result;
  }

  DmParticipant._();

  factory DmParticipant.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DmParticipant.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DmParticipant',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(4, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(5, _omitFieldNames ? '' : 'status')
    ..aOS(6, _omitFieldNames ? '' : 'displayName')
    ..aOS(7, _omitFieldNames ? '' : 'nameColor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DmParticipant clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DmParticipant copyWith(void Function(DmParticipant) updates) =>
      super.copyWith((message) => updates(message as DmParticipant))
          as DmParticipant;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DmParticipant create() => DmParticipant._();
  @$core.override
  DmParticipant createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DmParticipant getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DmParticipant>(create);
  static DmParticipant? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(4)
  $core.String get avatarUrl => $_getSZ(2);
  @$pb.TagNumber(4)
  set avatarUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasAvatarUrl() => $_has(2);
  @$pb.TagNumber(4)
  void clearAvatarUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get status => $_getSZ(3);
  @$pb.TagNumber(5)
  set status($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(5)
  void clearStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get displayName => $_getSZ(4);
  @$pb.TagNumber(6)
  set displayName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(6)
  $core.bool hasDisplayName() => $_has(4);
  @$pb.TagNumber(6)
  void clearDisplayName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get nameColor => $_getSZ(5);
  @$pb.TagNumber(7)
  set nameColor($core.String value) => $_setString(5, value);
  @$pb.TagNumber(7)
  $core.bool hasNameColor() => $_has(5);
  @$pb.TagNumber(7)
  void clearNameColor() => $_clearField(7);
}

class DmChannel extends $pb.GeneratedMessage {
  factory DmChannel({
    $core.String? id,
    ChannelType? type,
    $core.String? name,
    $core.Iterable<DmParticipant>? participants,
    $core.String? lastMessageId,
    $core.String? lastMessageAt,
    $core.String? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (type != null) result.type = type;
    if (name != null) result.name = name;
    if (participants != null) result.participants.addAll(participants);
    if (lastMessageId != null) result.lastMessageId = lastMessageId;
    if (lastMessageAt != null) result.lastMessageAt = lastMessageAt;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  DmChannel._();

  factory DmChannel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DmChannel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DmChannel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ChannelType>(2, _omitFieldNames ? '' : 'type',
        enumValues: ChannelType.values)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..pPM<DmParticipant>(4, _omitFieldNames ? '' : 'participants',
        subBuilder: DmParticipant.create)
    ..aOS(5, _omitFieldNames ? '' : 'lastMessageId')
    ..aOS(6, _omitFieldNames ? '' : 'lastMessageAt')
    ..aOS(7, _omitFieldNames ? '' : 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DmChannel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DmChannel copyWith(void Function(DmChannel) updates) =>
      super.copyWith((message) => updates(message as DmChannel)) as DmChannel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DmChannel create() => DmChannel._();
  @$core.override
  DmChannel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DmChannel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DmChannel>(create);
  static DmChannel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ChannelType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(ChannelType value) => $_setField(2, value);
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
  $pb.PbList<DmParticipant> get participants => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get lastMessageId => $_getSZ(4);
  @$pb.TagNumber(5)
  set lastMessageId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastMessageId() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastMessageId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get lastMessageAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set lastMessageAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastMessageAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastMessageAt() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get createdAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set createdAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
