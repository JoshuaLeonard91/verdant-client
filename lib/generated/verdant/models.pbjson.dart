// This is a generated file - do not edit.
//
// Generated from verdant/models.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use userStatusDescriptor instead')
const UserStatus$json = {
  '1': 'UserStatus',
  '2': [
    {'1': 'USER_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'USER_STATUS_ONLINE', '2': 1},
    {'1': 'USER_STATUS_IDLE', '2': 2},
    {'1': 'USER_STATUS_DND', '2': 3},
    {'1': 'USER_STATUS_OFFLINE', '2': 4},
  ],
};

/// Descriptor for `UserStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List userStatusDescriptor = $convert.base64Decode(
    'CgpVc2VyU3RhdHVzEhsKF1VTRVJfU1RBVFVTX1VOU1BFQ0lGSUVEEAASFgoSVVNFUl9TVEFUVV'
    'NfT05MSU5FEAESFAoQVVNFUl9TVEFUVVNfSURMRRACEhMKD1VTRVJfU1RBVFVTX0RORBADEhcK'
    'E1VTRVJfU1RBVFVTX09GRkxJTkUQBA==');

@$core.Deprecated('Use channelTypeDescriptor instead')
const ChannelType$json = {
  '1': 'ChannelType',
  '2': [
    {'1': 'CHANNEL_TYPE_SERVER_TEXT', '2': 0},
    {'1': 'CHANNEL_TYPE_DM', '2': 1},
    {'1': 'CHANNEL_TYPE_GROUP_DM', '2': 2},
    {'1': 'CHANNEL_TYPE_SERVER_VOICE', '2': 3},
  ],
};

/// Descriptor for `ChannelType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List channelTypeDescriptor = $convert.base64Decode(
    'CgtDaGFubmVsVHlwZRIcChhDSEFOTkVMX1RZUEVfU0VSVkVSX1RFWFQQABITCg9DSEFOTkVMX1'
    'RZUEVfRE0QARIZChVDSEFOTkVMX1RZUEVfR1JPVVBfRE0QAhIdChlDSEFOTkVMX1RZUEVfU0VS'
    'VkVSX1ZPSUNFEAM=');

@$core.Deprecated('Use relationshipTypeDescriptor instead')
const RelationshipType$json = {
  '1': 'RelationshipType',
  '2': [
    {'1': 'RELATIONSHIP_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'RELATIONSHIP_TYPE_FRIEND', '2': 1},
    {'1': 'RELATIONSHIP_TYPE_BLOCKED', '2': 2},
    {'1': 'RELATIONSHIP_TYPE_PENDING_OUTGOING', '2': 3},
    {'1': 'RELATIONSHIP_TYPE_PENDING_INCOMING', '2': 4},
  ],
};

/// Descriptor for `RelationshipType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List relationshipTypeDescriptor = $convert.base64Decode(
    'ChBSZWxhdGlvbnNoaXBUeXBlEiEKHVJFTEFUSU9OU0hJUF9UWVBFX1VOU1BFQ0lGSUVEEAASHA'
    'oYUkVMQVRJT05TSElQX1RZUEVfRlJJRU5EEAESHQoZUkVMQVRJT05TSElQX1RZUEVfQkxPQ0tF'
    'RBACEiYKIlJFTEFUSU9OU0hJUF9UWVBFX1BFTkRJTkdfT1VUR09JTkcQAxImCiJSRUxBVElPTl'
    'NISVBfVFlQRV9QRU5ESU5HX0lOQ09NSU5HEAQ=');

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'email', '3': 4, '4': 1, '5': 9, '10': 'email'},
    {
      '1': 'avatar_url',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'avatarUrl',
      '17': true
    },
    {
      '1': 'status',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.verdant.UserStatus',
      '10': 'status'
    },
    {'1': 'subscribed', '3': 7, '4': 1, '5': 8, '10': 'subscribed'},
    {'1': 'created_at', '3': 8, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updated_at', '3': 9, '4': 1, '5': 9, '10': 'updatedAt'},
    {'1': 'username_set', '3': 10, '4': 1, '5': 8, '10': 'usernameSet'},
  ],
  '8': [
    {'1': '_avatar_url'},
  ],
  '9': [
    {'1': 3, '2': 4},
  ],
  '10': ['discriminator'],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEg4KAmlkGAEgASgJUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5hbWUSFAoFZW'
    '1haWwYBCABKAlSBWVtYWlsEiIKCmF2YXRhcl91cmwYBSABKAlIAFIJYXZhdGFyVXJsiAEBEisK'
    'BnN0YXR1cxgGIAEoDjITLnZlcmRhbnQuVXNlclN0YXR1c1IGc3RhdHVzEh4KCnN1YnNjcmliZW'
    'QYByABKAhSCnN1YnNjcmliZWQSHQoKY3JlYXRlZF9hdBgIIAEoCVIJY3JlYXRlZEF0Eh0KCnVw'
    'ZGF0ZWRfYXQYCSABKAlSCXVwZGF0ZWRBdBIhCgx1c2VybmFtZV9zZXQYCiABKAhSC3VzZXJuYW'
    '1lU2V0Qg0KC19hdmF0YXJfdXJsSgQIAxAEUg1kaXNjcmltaW5hdG9y');

@$core.Deprecated('Use userProfileDescriptor instead')
const UserProfile$json = {
  '1': 'UserProfile',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'display_name',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'displayName',
      '17': true
    },
    {'1': 'bio', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'bio', '17': true},
    {
      '1': 'banner_url',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'bannerUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_display_name'},
    {'1': '_bio'},
    {'1': '_banner_url'},
  ],
};

/// Descriptor for `UserProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userProfileDescriptor = $convert.base64Decode(
    'CgtVc2VyUHJvZmlsZRIOCgJpZBgBIAEoCVICaWQSFwoHdXNlcl9pZBgCIAEoCVIGdXNlcklkEi'
    'YKDGRpc3BsYXlfbmFtZRgDIAEoCUgAUgtkaXNwbGF5TmFtZYgBARIVCgNiaW8YBCABKAlIAVID'
    'YmlviAEBEiIKCmJhbm5lcl91cmwYBSABKAlIAlIJYmFubmVyVXJsiAEBQg8KDV9kaXNwbGF5X2'
    '5hbWVCBgoEX2Jpb0INCgtfYmFubmVyX3VybA==');

@$core.Deprecated('Use messageAuthorDescriptor instead')
const MessageAuthor$json = {
  '1': 'MessageAuthor',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {
      '1': 'avatar_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'avatarUrl',
      '17': true
    },
    {
      '1': 'display_name',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'displayName',
      '17': true
    },
  ],
  '8': [
    {'1': '_avatar_url'},
    {'1': '_display_name'},
  ],
};

/// Descriptor for `MessageAuthor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageAuthorDescriptor = $convert.base64Decode(
    'Cg1NZXNzYWdlQXV0aG9yEg4KAmlkGAEgASgJUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm'
    '5hbWUSIgoKYXZhdGFyX3VybBgDIAEoCUgAUglhdmF0YXJVcmyIAQESJgoMZGlzcGxheV9uYW1l'
    'GAQgASgJSAFSC2Rpc3BsYXlOYW1liAEBQg0KC19hdmF0YXJfdXJsQg8KDV9kaXNwbGF5X25hbW'
    'U=');

@$core.Deprecated('Use serverDescriptor instead')
const Server$json = {
  '1': 'Server',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'owner_id', '3': 3, '4': 1, '5': 9, '10': 'ownerId'},
    {
      '1': 'icon_url',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'iconUrl',
      '17': true
    },
    {
      '1': 'description',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'description',
      '17': true
    },
    {'1': 'voice_bitrate', '3': 6, '4': 1, '5': 5, '10': 'voiceBitrate'},
    {'1': 'created_at', '3': 7, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updated_at', '3': 8, '4': 1, '5': 9, '10': 'updatedAt'},
    {
      '1': 'welcome_channel_id',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'welcomeChannelId',
      '17': true
    },
    {
      '1': 'announce_channel_id',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'announceChannelId',
      '17': true
    },
    {
      '1': 'welcome_message',
      '3': 11,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'welcomeMessage',
      '17': true
    },
    {'1': 'emoji_version', '3': 12, '4': 1, '5': 5, '10': 'emojiVersion'},
    {'1': 'large', '3': 13, '4': 1, '5': 8, '10': 'large'},
    {'1': 'member_count', '3': 14, '4': 1, '5': 3, '10': 'memberCount'},
    {
      '1': 'banner_url',
      '3': 15,
      '4': 1,
      '5': 9,
      '9': 5,
      '10': 'bannerUrl',
      '17': true
    },
    {
      '1': 'accent_color',
      '3': 16,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'accentColor',
      '17': true
    },
    {'1': 'banner_offset_y', '3': 17, '4': 1, '5': 5, '10': 'bannerOffsetY'},
  ],
  '8': [
    {'1': '_icon_url'},
    {'1': '_description'},
    {'1': '_welcome_channel_id'},
    {'1': '_announce_channel_id'},
    {'1': '_welcome_message'},
    {'1': '_banner_url'},
    {'1': '_accent_color'},
  ],
};

/// Descriptor for `Server`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverDescriptor = $convert.base64Decode(
    'CgZTZXJ2ZXISDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSGQoIb3duZXJfaW'
    'QYAyABKAlSB293bmVySWQSHgoIaWNvbl91cmwYBCABKAlIAFIHaWNvblVybIgBARIlCgtkZXNj'
    'cmlwdGlvbhgFIAEoCUgBUgtkZXNjcmlwdGlvbogBARIjCg12b2ljZV9iaXRyYXRlGAYgASgFUg'
    'x2b2ljZUJpdHJhdGUSHQoKY3JlYXRlZF9hdBgHIAEoCVIJY3JlYXRlZEF0Eh0KCnVwZGF0ZWRf'
    'YXQYCCABKAlSCXVwZGF0ZWRBdBIxChJ3ZWxjb21lX2NoYW5uZWxfaWQYCSABKAlIAlIQd2VsY2'
    '9tZUNoYW5uZWxJZIgBARIzChNhbm5vdW5jZV9jaGFubmVsX2lkGAogASgJSANSEWFubm91bmNl'
    'Q2hhbm5lbElkiAEBEiwKD3dlbGNvbWVfbWVzc2FnZRgLIAEoCUgEUg53ZWxjb21lTWVzc2FnZY'
    'gBARIjCg1lbW9qaV92ZXJzaW9uGAwgASgFUgxlbW9qaVZlcnNpb24SFAoFbGFyZ2UYDSABKAhS'
    'BWxhcmdlEiEKDG1lbWJlcl9jb3VudBgOIAEoA1ILbWVtYmVyQ291bnQSIgoKYmFubmVyX3VybB'
    'gPIAEoCUgFUgliYW5uZXJVcmyIAQESJgoMYWNjZW50X2NvbG9yGBAgASgJSAZSC2FjY2VudENv'
    'bG9yiAEBEiYKD2Jhbm5lcl9vZmZzZXRfeRgRIAEoBVINYmFubmVyT2Zmc2V0WUILCglfaWNvbl'
    '91cmxCDgoMX2Rlc2NyaXB0aW9uQhUKE193ZWxjb21lX2NoYW5uZWxfaWRCFgoUX2Fubm91bmNl'
    'X2NoYW5uZWxfaWRCEgoQX3dlbGNvbWVfbWVzc2FnZUINCgtfYmFubmVyX3VybEIPCg1fYWNjZW'
    '50X2NvbG9y');

@$core.Deprecated('Use serverMemberDescriptor instead')
const ServerMember$json = {
  '1': 'ServerMember',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'server_id', '3': 3, '4': 1, '5': 9, '10': 'serverId'},
    {
      '1': 'nickname',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nickname',
      '17': true
    },
    {'1': 'role_ids', '3': 5, '4': 3, '5': 9, '10': 'roleIds'},
    {'1': 'joined_at', '3': 6, '4': 1, '5': 9, '10': 'joinedAt'},
  ],
  '8': [
    {'1': '_nickname'},
  ],
};

/// Descriptor for `ServerMember`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverMemberDescriptor = $convert.base64Decode(
    'CgxTZXJ2ZXJNZW1iZXISDgoCaWQYASABKAlSAmlkEhcKB3VzZXJfaWQYAiABKAlSBnVzZXJJZB'
    'IbCglzZXJ2ZXJfaWQYAyABKAlSCHNlcnZlcklkEh8KCG5pY2tuYW1lGAQgASgJSABSCG5pY2tu'
    'YW1liAEBEhkKCHJvbGVfaWRzGAUgAygJUgdyb2xlSWRzEhsKCWpvaW5lZF9hdBgGIAEoCVIIam'
    '9pbmVkQXRCCwoJX25pY2tuYW1l');

@$core.Deprecated('Use channelDescriptor instead')
const Channel$json = {
  '1': 'Channel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.verdant.ChannelType',
      '10': 'type'
    },
    {
      '1': 'server_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'serverId',
      '17': true
    },
    {'1': 'name', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'name', '17': true},
    {'1': 'topic', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'topic', '17': true},
    {'1': 'position', '3': 6, '4': 1, '5': 5, '10': 'position'},
    {
      '1': 'category_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'categoryId',
      '17': true
    },
    {'1': 'created_at', '3': 8, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'read_only', '3': 9, '4': 1, '5': 8, '10': 'readOnly'},
    {'1': 'slowmode_seconds', '3': 10, '4': 1, '5': 5, '10': 'slowmodeSeconds'},
  ],
  '8': [
    {'1': '_server_id'},
    {'1': '_name'},
    {'1': '_topic'},
    {'1': '_category_id'},
  ],
};

/// Descriptor for `Channel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelDescriptor = $convert.base64Decode(
    'CgdDaGFubmVsEg4KAmlkGAEgASgJUgJpZBIoCgR0eXBlGAIgASgOMhQudmVyZGFudC5DaGFubm'
    'VsVHlwZVIEdHlwZRIgCglzZXJ2ZXJfaWQYAyABKAlIAFIIc2VydmVySWSIAQESFwoEbmFtZRgE'
    'IAEoCUgBUgRuYW1liAEBEhkKBXRvcGljGAUgASgJSAJSBXRvcGljiAEBEhoKCHBvc2l0aW9uGA'
    'YgASgFUghwb3NpdGlvbhIkCgtjYXRlZ29yeV9pZBgHIAEoCUgDUgpjYXRlZ29yeUlkiAEBEh0K'
    'CmNyZWF0ZWRfYXQYCCABKAlSCWNyZWF0ZWRBdBIbCglyZWFkX29ubHkYCSABKAhSCHJlYWRPbm'
    'x5EikKEHNsb3dtb2RlX3NlY29uZHMYCiABKAVSD3Nsb3dtb2RlU2Vjb25kc0IMCgpfc2VydmVy'
    'X2lkQgcKBV9uYW1lQggKBl90b3BpY0IOCgxfY2F0ZWdvcnlfaWQ=');

@$core.Deprecated('Use channelReadStateDescriptor instead')
const ChannelReadState$json = {
  '1': 'ChannelReadState',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {
      '1': 'last_read_message_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'lastReadMessageId'
    },
  ],
};

/// Descriptor for `ChannelReadState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelReadStateDescriptor = $convert.base64Decode(
    'ChBDaGFubmVsUmVhZFN0YXRlEh0KCmNoYW5uZWxfaWQYASABKAlSCWNoYW5uZWxJZBIvChRsYX'
    'N0X3JlYWRfbWVzc2FnZV9pZBgCIAEoCVIRbGFzdFJlYWRNZXNzYWdlSWQ=');

@$core.Deprecated('Use categoryDescriptor instead')
const Category$json = {
  '1': 'Category',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'server_id', '3': 2, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'position', '3': 4, '4': 1, '5': 5, '10': 'position'},
    {'1': 'created_at', '3': 5, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'emoji', '3': 6, '4': 1, '5': 9, '9': 0, '10': 'emoji', '17': true},
  ],
  '8': [
    {'1': '_emoji'},
  ],
};

/// Descriptor for `Category`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoryDescriptor = $convert.base64Decode(
    'CghDYXRlZ29yeRIOCgJpZBgBIAEoCVICaWQSGwoJc2VydmVyX2lkGAIgASgJUghzZXJ2ZXJJZB'
    'ISCgRuYW1lGAMgASgJUgRuYW1lEhoKCHBvc2l0aW9uGAQgASgFUghwb3NpdGlvbhIdCgpjcmVh'
    'dGVkX2F0GAUgASgJUgljcmVhdGVkQXQSGQoFZW1vamkYBiABKAlIAFIFZW1vammIAQFCCAoGX2'
    'Vtb2pp');

@$core.Deprecated('Use attachmentDescriptor instead')
const Attachment$json = {
  '1': 'Attachment',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'filename', '3': 3, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'url', '3': 4, '4': 1, '5': 9, '10': 'url'},
    {'1': 'content_type', '3': 5, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'size', '3': 6, '4': 1, '5': 5, '10': 'size'},
  ],
};

/// Descriptor for `Attachment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attachmentDescriptor = $convert.base64Decode(
    'CgpBdHRhY2htZW50Eg4KAmlkGAEgASgJUgJpZBIdCgptZXNzYWdlX2lkGAIgASgJUgltZXNzYW'
    'dlSWQSGgoIZmlsZW5hbWUYAyABKAlSCGZpbGVuYW1lEhAKA3VybBgEIAEoCVIDdXJsEiEKDGNv'
    'bnRlbnRfdHlwZRgFIAEoCVILY29udGVudFR5cGUSEgoEc2l6ZRgGIAEoBVIEc2l6ZQ==');

@$core.Deprecated('Use reactionDescriptor instead')
const Reaction$json = {
  '1': 'Reaction',
  '2': [
    {'1': 'emoji', '3': 1, '4': 1, '5': 9, '10': 'emoji'},
    {
      '1': 'emoji_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'emojiId',
      '17': true
    },
    {'1': 'count', '3': 3, '4': 1, '5': 5, '10': 'count'},
    {'1': 'me', '3': 4, '4': 1, '5': 8, '10': 'me'},
  ],
  '8': [
    {'1': '_emoji_id'},
  ],
};

/// Descriptor for `Reaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reactionDescriptor = $convert.base64Decode(
    'CghSZWFjdGlvbhIUCgVlbW9qaRgBIAEoCVIFZW1vamkSHgoIZW1vamlfaWQYAiABKAlIAFIHZW'
    '1vamlJZIgBARIUCgVjb3VudBgDIAEoBVIFY291bnQSDgoCbWUYBCABKAhSAm1lQgsKCV9lbW9q'
    'aV9pZA==');

@$core.Deprecated('Use replySnapshotDescriptor instead')
const ReplySnapshot$json = {
  '1': 'ReplySnapshot',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {
      '1': 'author',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.verdant.MessageAuthor',
      '10': 'author'
    },
  ],
};

/// Descriptor for `ReplySnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replySnapshotDescriptor = $convert.base64Decode(
    'Cg1SZXBseVNuYXBzaG90Eg4KAmlkGAEgASgJUgJpZBIYCgdjb250ZW50GAIgASgJUgdjb250ZW'
    '50Ei4KBmF1dGhvchgDIAEoCzIWLnZlcmRhbnQuTWVzc2FnZUF1dGhvclIGYXV0aG9y');

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'author_id', '3': 3, '4': 1, '5': 9, '10': 'authorId'},
    {
      '1': 'author',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.verdant.MessageAuthor',
      '10': 'author'
    },
    {'1': 'content', '3': 5, '4': 1, '5': 9, '10': 'content'},
    {
      '1': 'attachments',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.verdant.Attachment',
      '10': 'attachments'
    },
    {
      '1': 'reactions',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.verdant.Reaction',
      '10': 'reactions'
    },
    {'1': 'edited', '3': 8, '4': 1, '5': 8, '10': 'edited'},
    {'1': 'created_at', '3': 9, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updated_at', '3': 10, '4': 1, '5': 9, '10': 'updatedAt'},
    {'1': 'nonce', '3': 11, '4': 1, '5': 9, '9': 0, '10': 'nonce', '17': true},
    {'1': 'type', '3': 12, '4': 1, '5': 5, '10': 'type'},
    {
      '1': 'reply_to',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.verdant.ReplySnapshot',
      '9': 1,
      '10': 'replyTo',
      '17': true
    },
    {
      '1': 'edited_at',
      '3': 14,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'editedAt',
      '17': true
    },
  ],
  '8': [
    {'1': '_nonce'},
    {'1': '_reply_to'},
    {'1': '_edited_at'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEg4KAmlkGAEgASgJUgJpZBIdCgpjaGFubmVsX2lkGAIgASgJUgljaGFubmVsSW'
    'QSGwoJYXV0aG9yX2lkGAMgASgJUghhdXRob3JJZBIuCgZhdXRob3IYBCABKAsyFi52ZXJkYW50'
    'Lk1lc3NhZ2VBdXRob3JSBmF1dGhvchIYCgdjb250ZW50GAUgASgJUgdjb250ZW50EjUKC2F0dG'
    'FjaG1lbnRzGAYgAygLMhMudmVyZGFudC5BdHRhY2htZW50UgthdHRhY2htZW50cxIvCglyZWFj'
    'dGlvbnMYByADKAsyES52ZXJkYW50LlJlYWN0aW9uUglyZWFjdGlvbnMSFgoGZWRpdGVkGAggAS'
    'gIUgZlZGl0ZWQSHQoKY3JlYXRlZF9hdBgJIAEoCVIJY3JlYXRlZEF0Eh0KCnVwZGF0ZWRfYXQY'
    'CiABKAlSCXVwZGF0ZWRBdBIZCgVub25jZRgLIAEoCUgAUgVub25jZYgBARISCgR0eXBlGAwgAS'
    'gFUgR0eXBlEjYKCHJlcGx5X3RvGA0gASgLMhYudmVyZGFudC5SZXBseVNuYXBzaG90SAFSB3Jl'
    'cGx5VG+IAQESIAoJZWRpdGVkX2F0GA4gASgJSAJSCGVkaXRlZEF0iAEBQggKBl9ub25jZUILCg'
    'lfcmVwbHlfdG9CDAoKX2VkaXRlZF9hdA==');

@$core.Deprecated('Use roleDescriptor instead')
const Role$json = {
  '1': 'Role',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'server_id', '3': 2, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'color', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'color', '17': true},
    {'1': 'permissions', '3': 5, '4': 1, '5': 9, '10': 'permissions'},
    {'1': 'position', '3': 6, '4': 1, '5': 5, '10': 'position'},
    {'1': 'created_at', '3': 7, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'updated_at', '3': 8, '4': 1, '5': 9, '10': 'updatedAt'},
    {'1': 'color_only', '3': 9, '4': 1, '5': 8, '10': 'colorOnly'},
    {'1': 'show_as_section', '3': 10, '4': 1, '5': 8, '10': 'showAsSection'},
    {'1': 'color_priority', '3': 11, '4': 1, '5': 5, '10': 'colorPriority'},
  ],
  '8': [
    {'1': '_color'},
  ],
};

/// Descriptor for `Role`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleDescriptor = $convert.base64Decode(
    'CgRSb2xlEg4KAmlkGAEgASgJUgJpZBIbCglzZXJ2ZXJfaWQYAiABKAlSCHNlcnZlcklkEhIKBG'
    '5hbWUYAyABKAlSBG5hbWUSGQoFY29sb3IYBCABKAlIAFIFY29sb3KIAQESIAoLcGVybWlzc2lv'
    'bnMYBSABKAlSC3Blcm1pc3Npb25zEhoKCHBvc2l0aW9uGAYgASgFUghwb3NpdGlvbhIdCgpjcm'
    'VhdGVkX2F0GAcgASgJUgljcmVhdGVkQXQSHQoKdXBkYXRlZF9hdBgIIAEoCVIJdXBkYXRlZEF0'
    'Eh0KCmNvbG9yX29ubHkYCSABKAhSCWNvbG9yT25seRImCg9zaG93X2FzX3NlY3Rpb24YCiABKA'
    'hSDXNob3dBc1NlY3Rpb24SJQoOY29sb3JfcHJpb3JpdHkYCyABKAVSDWNvbG9yUHJpb3JpdHlC'
    'CAoGX2NvbG9y');

@$core.Deprecated('Use emojiDescriptor instead')
const Emoji$json = {
  '1': 'Emoji',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'server_id', '3': 2, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'url', '3': 4, '4': 1, '5': 9, '10': 'url'},
    {'1': 'created_by', '3': 5, '4': 1, '5': 9, '10': 'createdBy'},
    {'1': 'created_at', '3': 6, '4': 1, '5': 9, '10': 'createdAt'},
  ],
};

/// Descriptor for `Emoji`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emojiDescriptor = $convert.base64Decode(
    'CgVFbW9qaRIOCgJpZBgBIAEoCVICaWQSGwoJc2VydmVyX2lkGAIgASgJUghzZXJ2ZXJJZBISCg'
    'RuYW1lGAMgASgJUgRuYW1lEhAKA3VybBgEIAEoCVIDdXJsEh0KCmNyZWF0ZWRfYnkYBSABKAlS'
    'CWNyZWF0ZWRCeRIdCgpjcmVhdGVkX2F0GAYgASgJUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use voiceStateDescriptor instead')
const VoiceState$json = {
  '1': 'VoiceState',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'channel_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'channelId',
      '17': true
    },
    {'1': 'server_id', '3': 3, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'self_mute', '3': 4, '4': 1, '5': 8, '10': 'selfMute'},
    {'1': 'self_deaf', '3': 5, '4': 1, '5': 8, '10': 'selfDeaf'},
    {'1': 'server_mute', '3': 6, '4': 1, '5': 8, '10': 'serverMute'},
    {'1': 'server_deaf', '3': 7, '4': 1, '5': 8, '10': 'serverDeaf'},
  ],
  '8': [
    {'1': '_channel_id'},
  ],
};

/// Descriptor for `VoiceState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List voiceStateDescriptor = $convert.base64Decode(
    'CgpWb2ljZVN0YXRlEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIiCgpjaGFubmVsX2lkGAIgAS'
    'gJSABSCWNoYW5uZWxJZIgBARIbCglzZXJ2ZXJfaWQYAyABKAlSCHNlcnZlcklkEhsKCXNlbGZf'
    'bXV0ZRgEIAEoCFIIc2VsZk11dGUSGwoJc2VsZl9kZWFmGAUgASgIUghzZWxmRGVhZhIfCgtzZX'
    'J2ZXJfbXV0ZRgGIAEoCFIKc2VydmVyTXV0ZRIfCgtzZXJ2ZXJfZGVhZhgHIAEoCFIKc2VydmVy'
    'RGVhZkINCgtfY2hhbm5lbF9pZA==');

@$core.Deprecated('Use inviteDescriptor instead')
const Invite$json = {
  '1': 'Invite',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'server_id', '3': 2, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'inviter_id', '3': 3, '4': 1, '5': 9, '10': 'inviterId'},
    {
      '1': 'inviter_username',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'inviterUsername',
      '17': true
    },
    {
      '1': 'max_uses',
      '3': 5,
      '4': 1,
      '5': 5,
      '9': 1,
      '10': 'maxUses',
      '17': true
    },
    {'1': 'uses', '3': 6, '4': 1, '5': 5, '10': 'uses'},
    {
      '1': 'expires_at',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'expiresAt',
      '17': true
    },
    {'1': 'created_at', '3': 8, '4': 1, '5': 9, '10': 'createdAt'},
  ],
  '8': [
    {'1': '_inviter_username'},
    {'1': '_max_uses'},
    {'1': '_expires_at'},
  ],
};

/// Descriptor for `Invite`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inviteDescriptor = $convert.base64Decode(
    'CgZJbnZpdGUSEgoEY29kZRgBIAEoCVIEY29kZRIbCglzZXJ2ZXJfaWQYAiABKAlSCHNlcnZlck'
    'lkEh0KCmludml0ZXJfaWQYAyABKAlSCWludml0ZXJJZBIuChBpbnZpdGVyX3VzZXJuYW1lGAQg'
    'ASgJSABSD2ludml0ZXJVc2VybmFtZYgBARIeCghtYXhfdXNlcxgFIAEoBUgBUgdtYXhVc2VziA'
    'EBEhIKBHVzZXMYBiABKAVSBHVzZXMSIgoKZXhwaXJlc19hdBgHIAEoCUgCUglleHBpcmVzQXSI'
    'AQESHQoKY3JlYXRlZF9hdBgIIAEoCVIJY3JlYXRlZEF0QhMKEV9pbnZpdGVyX3VzZXJuYW1lQg'
    'sKCV9tYXhfdXNlc0INCgtfZXhwaXJlc19hdA==');

@$core.Deprecated('Use invitePreviewServerDescriptor instead')
const InvitePreviewServer$json = {
  '1': 'InvitePreviewServer',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'icon_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'iconUrl',
      '17': true
    },
    {'1': 'member_count', '3': 4, '4': 1, '5': 5, '10': 'memberCount'},
  ],
  '8': [
    {'1': '_icon_url'},
  ],
};

/// Descriptor for `InvitePreviewServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invitePreviewServerDescriptor = $convert.base64Decode(
    'ChNJbnZpdGVQcmV2aWV3U2VydmVyEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW'
    '1lEh4KCGljb25fdXJsGAMgASgJSABSB2ljb25VcmyIAQESIQoMbWVtYmVyX2NvdW50GAQgASgF'
    'UgttZW1iZXJDb3VudEILCglfaWNvbl91cmw=');

@$core.Deprecated('Use invitePreviewDescriptor instead')
const InvitePreview$json = {
  '1': 'InvitePreview',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {
      '1': 'server',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.verdant.InvitePreviewServer',
      '10': 'server'
    },
    {'1': 'inviter_username', '3': 3, '4': 1, '5': 9, '10': 'inviterUsername'},
    {
      '1': 'expires_at',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'expiresAt',
      '17': true
    },
  ],
  '8': [
    {'1': '_expires_at'},
  ],
};

/// Descriptor for `InvitePreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invitePreviewDescriptor = $convert.base64Decode(
    'Cg1JbnZpdGVQcmV2aWV3EhIKBGNvZGUYASABKAlSBGNvZGUSNAoGc2VydmVyGAIgASgLMhwudm'
    'VyZGFudC5JbnZpdGVQcmV2aWV3U2VydmVyUgZzZXJ2ZXISKQoQaW52aXRlcl91c2VybmFtZRgD'
    'IAEoCVIPaW52aXRlclVzZXJuYW1lEiIKCmV4cGlyZXNfYXQYBCABKAlIAFIJZXhwaXJlc0F0iA'
    'EBQg0KC19leHBpcmVzX2F0');

@$core.Deprecated('Use relationshipUserDescriptor instead')
const RelationshipUser$json = {
  '1': 'RelationshipUser',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {
      '1': 'avatar_url',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'avatarUrl',
      '17': true
    },
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
  ],
  '8': [
    {'1': '_avatar_url'},
  ],
  '9': [
    {'1': 3, '2': 4},
  ],
  '10': ['discriminator'],
};

/// Descriptor for `RelationshipUser`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relationshipUserDescriptor = $convert.base64Decode(
    'ChBSZWxhdGlvbnNoaXBVc2VyEg4KAmlkGAEgASgJUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdX'
    'Nlcm5hbWUSIgoKYXZhdGFyX3VybBgEIAEoCUgAUglhdmF0YXJVcmyIAQESFgoGc3RhdHVzGAUg'
    'ASgJUgZzdGF0dXNCDQoLX2F2YXRhcl91cmxKBAgDEARSDWRpc2NyaW1pbmF0b3I=');

@$core.Deprecated('Use relationshipDescriptor instead')
const Relationship$json = {
  '1': 'Relationship',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.verdant.RelationshipType',
      '10': 'type'
    },
    {
      '1': 'user',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.verdant.RelationshipUser',
      '10': 'user'
    },
    {'1': 'created_at', '3': 4, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'notes', '3': 5, '4': 1, '5': 9, '9': 0, '10': 'notes', '17': true},
    {
      '1': 'nickname_color',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'nicknameColor',
      '17': true
    },
  ],
  '8': [
    {'1': '_notes'},
    {'1': '_nickname_color'},
  ],
};

/// Descriptor for `Relationship`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relationshipDescriptor = $convert.base64Decode(
    'CgxSZWxhdGlvbnNoaXASFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklkEi0KBHR5cGUYAiABKA4yGS'
    '52ZXJkYW50LlJlbGF0aW9uc2hpcFR5cGVSBHR5cGUSLQoEdXNlchgDIAEoCzIZLnZlcmRhbnQu'
    'UmVsYXRpb25zaGlwVXNlclIEdXNlchIdCgpjcmVhdGVkX2F0GAQgASgJUgljcmVhdGVkQXQSGQ'
    'oFbm90ZXMYBSABKAlIAFIFbm90ZXOIAQESKgoObmlja25hbWVfY29sb3IYBiABKAlIAVINbmlj'
    'a25hbWVDb2xvcogBAUIICgZfbm90ZXNCEQoPX25pY2tuYW1lX2NvbG9y');

@$core.Deprecated('Use feedDescriptor instead')
const Feed$json = {
  '1': 'Feed',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'server_id', '3': 2, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'description',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'description',
      '17': true
    },
    {'1': 'publish_role_ids', '3': 5, '4': 3, '5': 9, '10': 'publishRoleIds'},
    {'1': 'view_role_ids', '3': 6, '4': 3, '5': 9, '10': 'viewRoleIds'},
    {'1': 'created_at', '3': 7, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'icon', '3': 8, '4': 1, '5': 9, '9': 1, '10': 'icon', '17': true},
    {'1': 'position', '3': 9, '4': 1, '5': 5, '10': 'position'},
  ],
  '8': [
    {'1': '_description'},
    {'1': '_icon'},
  ],
};

/// Descriptor for `Feed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List feedDescriptor = $convert.base64Decode(
    'CgRGZWVkEg4KAmlkGAEgASgJUgJpZBIbCglzZXJ2ZXJfaWQYAiABKAlSCHNlcnZlcklkEhIKBG'
    '5hbWUYAyABKAlSBG5hbWUSJQoLZGVzY3JpcHRpb24YBCABKAlIAFILZGVzY3JpcHRpb26IAQES'
    'KAoQcHVibGlzaF9yb2xlX2lkcxgFIAMoCVIOcHVibGlzaFJvbGVJZHMSIgoNdmlld19yb2xlX2'
    'lkcxgGIAMoCVILdmlld1JvbGVJZHMSHQoKY3JlYXRlZF9hdBgHIAEoCVIJY3JlYXRlZEF0EhcK'
    'BGljb24YCCABKAlIAVIEaWNvbogBARIaCghwb3NpdGlvbhgJIAEoBVIIcG9zaXRpb25CDgoMX2'
    'Rlc2NyaXB0aW9uQgcKBV9pY29u');

@$core.Deprecated('Use announcementDescriptor instead')
const Announcement$json = {
  '1': 'Announcement',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'feed_id', '3': 2, '4': 1, '5': 9, '10': 'feedId'},
    {'1': 'server_id', '3': 3, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'content', '3': 5, '4': 1, '5': 9, '10': 'content'},
    {'1': 'author_id', '3': 6, '4': 1, '5': 9, '10': 'authorId'},
    {
      '1': 'author_username',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'authorUsername',
      '17': true
    },
    {
      '1': 'author_avatar',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'authorAvatar',
      '17': true
    },
    {'1': 'created_at', '3': 9, '4': 1, '5': 9, '10': 'createdAt'},
    {
      '1': 'updated_at',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'updatedAt',
      '17': true
    },
  ],
  '8': [
    {'1': '_author_username'},
    {'1': '_author_avatar'},
    {'1': '_updated_at'},
  ],
};

/// Descriptor for `Announcement`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List announcementDescriptor = $convert.base64Decode(
    'CgxBbm5vdW5jZW1lbnQSDgoCaWQYASABKAlSAmlkEhcKB2ZlZWRfaWQYAiABKAlSBmZlZWRJZB'
    'IbCglzZXJ2ZXJfaWQYAyABKAlSCHNlcnZlcklkEhQKBXRpdGxlGAQgASgJUgV0aXRsZRIYCgdj'
    'b250ZW50GAUgASgJUgdjb250ZW50EhsKCWF1dGhvcl9pZBgGIAEoCVIIYXV0aG9ySWQSLAoPYX'
    'V0aG9yX3VzZXJuYW1lGAcgASgJSABSDmF1dGhvclVzZXJuYW1liAEBEigKDWF1dGhvcl9hdmF0'
    'YXIYCCABKAlIAVIMYXV0aG9yQXZhdGFyiAEBEh0KCmNyZWF0ZWRfYXQYCSABKAlSCWNyZWF0ZW'
    'RBdBIiCgp1cGRhdGVkX2F0GAogASgJSAJSCXVwZGF0ZWRBdIgBAUISChBfYXV0aG9yX3VzZXJu'
    'YW1lQhAKDl9hdXRob3JfYXZhdGFyQg0KC191cGRhdGVkX2F0');

@$core.Deprecated('Use dmParticipantDescriptor instead')
const DmParticipant$json = {
  '1': 'DmParticipant',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {
      '1': 'avatar_url',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'avatarUrl',
      '17': true
    },
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'display_name',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'displayName',
      '17': true
    },
    {
      '1': 'name_color',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'nameColor',
      '17': true
    },
  ],
  '8': [
    {'1': '_avatar_url'},
    {'1': '_display_name'},
    {'1': '_name_color'},
  ],
  '9': [
    {'1': 3, '2': 4},
  ],
  '10': ['discriminator'],
};

/// Descriptor for `DmParticipant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dmParticipantDescriptor = $convert.base64Decode(
    'Cg1EbVBhcnRpY2lwYW50Eg4KAmlkGAEgASgJUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm'
    '5hbWUSIgoKYXZhdGFyX3VybBgEIAEoCUgAUglhdmF0YXJVcmyIAQESFgoGc3RhdHVzGAUgASgJ'
    'UgZzdGF0dXMSJgoMZGlzcGxheV9uYW1lGAYgASgJSAFSC2Rpc3BsYXlOYW1liAEBEiIKCm5hbW'
    'VfY29sb3IYByABKAlIAlIJbmFtZUNvbG9yiAEBQg0KC19hdmF0YXJfdXJsQg8KDV9kaXNwbGF5'
    'X25hbWVCDQoLX25hbWVfY29sb3JKBAgDEARSDWRpc2NyaW1pbmF0b3I=');

@$core.Deprecated('Use dmChannelDescriptor instead')
const DmChannel$json = {
  '1': 'DmChannel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.verdant.ChannelType',
      '10': 'type'
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'participants',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.verdant.DmParticipant',
      '10': 'participants'
    },
    {
      '1': 'last_message_id',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'lastMessageId',
      '17': true
    },
    {
      '1': 'last_message_at',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'lastMessageAt',
      '17': true
    },
    {'1': 'created_at', '3': 7, '4': 1, '5': 9, '10': 'createdAt'},
  ],
  '8': [
    {'1': '_name'},
    {'1': '_last_message_id'},
    {'1': '_last_message_at'},
  ],
};

/// Descriptor for `DmChannel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dmChannelDescriptor = $convert.base64Decode(
    'CglEbUNoYW5uZWwSDgoCaWQYASABKAlSAmlkEigKBHR5cGUYAiABKA4yFC52ZXJkYW50LkNoYW'
    '5uZWxUeXBlUgR0eXBlEhcKBG5hbWUYAyABKAlIAFIEbmFtZYgBARI6CgxwYXJ0aWNpcGFudHMY'
    'BCADKAsyFi52ZXJkYW50LkRtUGFydGljaXBhbnRSDHBhcnRpY2lwYW50cxIrCg9sYXN0X21lc3'
    'NhZ2VfaWQYBSABKAlIAVINbGFzdE1lc3NhZ2VJZIgBARIrCg9sYXN0X21lc3NhZ2VfYXQYBiAB'
    'KAlIAlINbGFzdE1lc3NhZ2VBdIgBARIdCgpjcmVhdGVkX2F0GAcgASgJUgljcmVhdGVkQXRCBw'
    'oFX25hbWVCEgoQX2xhc3RfbWVzc2FnZV9pZEISChBfbGFzdF9tZXNzYWdlX2F0');
