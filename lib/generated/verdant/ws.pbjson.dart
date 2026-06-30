// This is a generated file - do not edit.
//
// Generated from verdant/ws.proto.

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

@$core.Deprecated('Use wsMessageDescriptor instead')
const WsMessage$json = {
  '1': 'WsMessage',
  '2': [
    {
      '1': 'ready',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Ready',
      '9': 0,
      '10': 'ready'
    },
    {
      '1': 'message_create',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.verdant.MessageCreate',
      '9': 0,
      '10': 'messageCreate'
    },
    {
      '1': 'message_update',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.verdant.MessageUpdate',
      '9': 0,
      '10': 'messageUpdate'
    },
    {
      '1': 'message_delete',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.verdant.MessageDelete',
      '9': 0,
      '10': 'messageDelete'
    },
    {
      '1': 'typing_start',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.verdant.TypingStart',
      '9': 0,
      '10': 'typingStart'
    },
    {
      '1': 'presence_update',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.verdant.PresenceUpdate',
      '9': 0,
      '10': 'presenceUpdate'
    },
    {
      '1': 'channel_create',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.verdant.ChannelCreate',
      '9': 0,
      '10': 'channelCreate'
    },
    {
      '1': 'channel_update',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.verdant.ChannelUpdate',
      '9': 0,
      '10': 'channelUpdate'
    },
    {
      '1': 'channel_delete',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.verdant.ChannelDelete',
      '9': 0,
      '10': 'channelDelete'
    },
    {
      '1': 'member_remove',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.verdant.MemberRemove',
      '9': 0,
      '10': 'memberRemove'
    },
    {
      '1': 'server_delete',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.verdant.ServerDelete',
      '9': 0,
      '10': 'serverDelete'
    },
    {
      '1': 'voice_state_update',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.verdant.VoiceStateUpdate',
      '9': 0,
      '10': 'voiceStateUpdate'
    },
    {
      '1': 'category_create',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.verdant.CategoryCreate',
      '9': 0,
      '10': 'categoryCreate'
    },
    {
      '1': 'category_update',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.verdant.CategoryUpdate',
      '9': 0,
      '10': 'categoryUpdate'
    },
    {
      '1': 'category_delete',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.verdant.CategoryDelete',
      '9': 0,
      '10': 'categoryDelete'
    },
    {
      '1': 'reaction_add',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.verdant.ReactionAdd',
      '9': 0,
      '10': 'reactionAdd'
    },
    {
      '1': 'reaction_remove',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.verdant.ReactionRemove',
      '9': 0,
      '10': 'reactionRemove'
    },
    {
      '1': 'role_create',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.verdant.RoleCreate',
      '9': 0,
      '10': 'roleCreate'
    },
    {
      '1': 'role_update',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.verdant.RoleUpdate',
      '9': 0,
      '10': 'roleUpdate'
    },
    {
      '1': 'role_delete',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.verdant.RoleDelete',
      '9': 0,
      '10': 'roleDelete'
    },
    {
      '1': 'member_role_update',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.verdant.MemberRoleUpdate',
      '9': 0,
      '10': 'memberRoleUpdate'
    },
    {
      '1': 'force_update',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.verdant.ForceUpdate',
      '9': 0,
      '10': 'forceUpdate'
    },
    {
      '1': 'feature_flags_update',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.verdant.FeatureFlagsUpdate',
      '9': 0,
      '10': 'featureFlagsUpdate'
    },
    {
      '1': 'relationship_add',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.verdant.RelationshipAdd',
      '9': 0,
      '10': 'relationshipAdd'
    },
    {
      '1': 'relationship_remove',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.verdant.RelationshipRemove',
      '9': 0,
      '10': 'relationshipRemove'
    },
    {
      '1': 'dm_channel_create',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.verdant.DmChannelCreate',
      '9': 0,
      '10': 'dmChannelCreate'
    },
    {
      '1': 'message_send_error',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.verdant.MessageSendError',
      '9': 0,
      '10': 'messageSendError'
    },
    {
      '1': 'update_available',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.verdant.UpdateAvailable',
      '9': 0,
      '10': 'updateAvailable'
    },
    {
      '1': 'ws_error',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.verdant.WsError',
      '9': 0,
      '10': 'wsError'
    },
    {
      '1': 'message_pin',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.verdant.MessagePin',
      '9': 0,
      '10': 'messagePin'
    },
    {
      '1': 'message_unpin',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.verdant.MessageUnpin',
      '9': 0,
      '10': 'messageUnpin'
    },
    {
      '1': 'member_join',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.verdant.MemberJoin',
      '9': 0,
      '10': 'memberJoin'
    },
    {
      '1': 'user_profile_update',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.verdant.UserProfileUpdate',
      '9': 0,
      '10': 'userProfileUpdate'
    },
    {
      '1': 'server_update',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.verdant.ServerUpdate',
      '9': 0,
      '10': 'serverUpdate'
    },
    {
      '1': 'server_emojis_update',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.verdant.ServerEmojisUpdate',
      '9': 0,
      '10': 'serverEmojisUpdate'
    },
    {
      '1': 'dm_name_color_update',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.verdant.DmNameColorUpdate',
      '9': 0,
      '10': 'dmNameColorUpdate'
    },
    {
      '1': 'announcement_create',
      '3': 42,
      '4': 1,
      '5': 11,
      '6': '.verdant.AnnouncementCreate',
      '9': 0,
      '10': 'announcementCreate'
    },
    {
      '1': 'announcement_update',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.verdant.AnnouncementUpdate',
      '9': 0,
      '10': 'announcementUpdate'
    },
    {
      '1': 'announcement_delete',
      '3': 44,
      '4': 1,
      '5': 11,
      '6': '.verdant.AnnouncementDelete',
      '9': 0,
      '10': 'announcementDelete'
    },
    {
      '1': 'feed_create',
      '3': 45,
      '4': 1,
      '5': 11,
      '6': '.verdant.FeedCreate',
      '9': 0,
      '10': 'feedCreate'
    },
    {
      '1': 'feed_update',
      '3': 46,
      '4': 1,
      '5': 11,
      '6': '.verdant.FeedUpdate',
      '9': 0,
      '10': 'feedUpdate'
    },
    {
      '1': 'feed_delete',
      '3': 47,
      '4': 1,
      '5': 11,
      '6': '.verdant.FeedDelete',
      '9': 0,
      '10': 'feedDelete'
    },
    {
      '1': 'ready_delta',
      '3': 48,
      '4': 1,
      '5': 11,
      '6': '.verdant.ReadyDelta',
      '9': 0,
      '10': 'readyDelta'
    },
    {
      '1': 'batch',
      '3': 49,
      '4': 1,
      '5': 11,
      '6': '.verdant.Batch',
      '9': 0,
      '10': 'batch'
    },
    {
      '1': 'channel_unread_signal',
      '3': 63,
      '4': 1,
      '5': 11,
      '6': '.verdant.ChannelUnreadSignal',
      '9': 0,
      '10': 'channelUnreadSignal'
    },
    {
      '1': 'channel_activity_update',
      '3': 64,
      '4': 1,
      '5': 11,
      '6': '.verdant.ChannelActivityUpdate',
      '9': 0,
      '10': 'channelActivityUpdate'
    },
    {
      '1': 'ping',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.verdant.Ping',
      '9': 0,
      '10': 'ping'
    },
    {
      '1': 'pong',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.verdant.Pong',
      '9': 0,
      '10': 'pong'
    },
    {
      '1': 'identify',
      '3': 50,
      '4': 1,
      '5': 11,
      '6': '.verdant.Identify',
      '9': 0,
      '10': 'identify'
    },
    {
      '1': 'client_typing_start',
      '3': 51,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientTypingStart',
      '9': 0,
      '10': 'clientTypingStart'
    },
    {
      '1': 'client_presence_update',
      '3': 52,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientPresenceUpdate',
      '9': 0,
      '10': 'clientPresenceUpdate'
    },
    {
      '1': 'client_message_send',
      '3': 53,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientMessageSend',
      '9': 0,
      '10': 'clientMessageSend'
    },
    {
      '1': 'client_message_edit',
      '3': 54,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientMessageEdit',
      '9': 0,
      '10': 'clientMessageEdit'
    },
    {
      '1': 'client_message_delete',
      '3': 55,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientMessageDelete',
      '9': 0,
      '10': 'clientMessageDelete'
    },
    {
      '1': 'client_reaction_add',
      '3': 56,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientReactionAdd',
      '9': 0,
      '10': 'clientReactionAdd'
    },
    {
      '1': 'client_reaction_remove',
      '3': 57,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientReactionRemove',
      '9': 0,
      '10': 'clientReactionRemove'
    },
    {
      '1': 'client_channel_ack',
      '3': 58,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientChannelAck',
      '9': 0,
      '10': 'clientChannelAck'
    },
    {
      '1': 'client_voice_state',
      '3': 59,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientVoiceState',
      '9': 0,
      '10': 'clientVoiceState'
    },
    {
      '1': 'client_voice_leave',
      '3': 60,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientVoiceLeave',
      '9': 0,
      '10': 'clientVoiceLeave'
    },
    {
      '1': 'client_focus_server',
      '3': 61,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientFocusServer',
      '9': 0,
      '10': 'clientFocusServer'
    },
    {
      '1': 'client_request_members',
      '3': 62,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientRequestMembers',
      '9': 0,
      '10': 'clientRequestMembers'
    },
    {
      '1': 'client_focus_channel',
      '3': 65,
      '4': 1,
      '5': 11,
      '6': '.verdant.ClientFocusChannel',
      '9': 0,
      '10': 'clientFocusChannel'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `WsMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wsMessageDescriptor = $convert.base64Decode(
    'CglXc01lc3NhZ2USJgoFcmVhZHkYASABKAsyDi52ZXJkYW50LlJlYWR5SABSBXJlYWR5Ej8KDm'
    '1lc3NhZ2VfY3JlYXRlGAIgASgLMhYudmVyZGFudC5NZXNzYWdlQ3JlYXRlSABSDW1lc3NhZ2VD'
    'cmVhdGUSPwoObWVzc2FnZV91cGRhdGUYAyABKAsyFi52ZXJkYW50Lk1lc3NhZ2VVcGRhdGVIAF'
    'INbWVzc2FnZVVwZGF0ZRI/Cg5tZXNzYWdlX2RlbGV0ZRgEIAEoCzIWLnZlcmRhbnQuTWVzc2Fn'
    'ZURlbGV0ZUgAUg1tZXNzYWdlRGVsZXRlEjkKDHR5cGluZ19zdGFydBgFIAEoCzIULnZlcmRhbn'
    'QuVHlwaW5nU3RhcnRIAFILdHlwaW5nU3RhcnQSQgoPcHJlc2VuY2VfdXBkYXRlGAYgASgLMhcu'
    'dmVyZGFudC5QcmVzZW5jZVVwZGF0ZUgAUg5wcmVzZW5jZVVwZGF0ZRI/Cg5jaGFubmVsX2NyZW'
    'F0ZRgHIAEoCzIWLnZlcmRhbnQuQ2hhbm5lbENyZWF0ZUgAUg1jaGFubmVsQ3JlYXRlEj8KDmNo'
    'YW5uZWxfdXBkYXRlGAggASgLMhYudmVyZGFudC5DaGFubmVsVXBkYXRlSABSDWNoYW5uZWxVcG'
    'RhdGUSPwoOY2hhbm5lbF9kZWxldGUYCSABKAsyFi52ZXJkYW50LkNoYW5uZWxEZWxldGVIAFIN'
    'Y2hhbm5lbERlbGV0ZRI8Cg1tZW1iZXJfcmVtb3ZlGAogASgLMhUudmVyZGFudC5NZW1iZXJSZW'
    '1vdmVIAFIMbWVtYmVyUmVtb3ZlEjwKDXNlcnZlcl9kZWxldGUYCyABKAsyFS52ZXJkYW50LlNl'
    'cnZlckRlbGV0ZUgAUgxzZXJ2ZXJEZWxldGUSSQoSdm9pY2Vfc3RhdGVfdXBkYXRlGAwgASgLMh'
    'kudmVyZGFudC5Wb2ljZVN0YXRlVXBkYXRlSABSEHZvaWNlU3RhdGVVcGRhdGUSQgoPY2F0ZWdv'
    'cnlfY3JlYXRlGA0gASgLMhcudmVyZGFudC5DYXRlZ29yeUNyZWF0ZUgAUg5jYXRlZ29yeUNyZW'
    'F0ZRJCCg9jYXRlZ29yeV91cGRhdGUYDiABKAsyFy52ZXJkYW50LkNhdGVnb3J5VXBkYXRlSABS'
    'DmNhdGVnb3J5VXBkYXRlEkIKD2NhdGVnb3J5X2RlbGV0ZRgPIAEoCzIXLnZlcmRhbnQuQ2F0ZW'
    'dvcnlEZWxldGVIAFIOY2F0ZWdvcnlEZWxldGUSOQoMcmVhY3Rpb25fYWRkGBAgASgLMhQudmVy'
    'ZGFudC5SZWFjdGlvbkFkZEgAUgtyZWFjdGlvbkFkZBJCCg9yZWFjdGlvbl9yZW1vdmUYESABKA'
    'syFy52ZXJkYW50LlJlYWN0aW9uUmVtb3ZlSABSDnJlYWN0aW9uUmVtb3ZlEjYKC3JvbGVfY3Jl'
    'YXRlGBIgASgLMhMudmVyZGFudC5Sb2xlQ3JlYXRlSABSCnJvbGVDcmVhdGUSNgoLcm9sZV91cG'
    'RhdGUYEyABKAsyEy52ZXJkYW50LlJvbGVVcGRhdGVIAFIKcm9sZVVwZGF0ZRI2Cgtyb2xlX2Rl'
    'bGV0ZRgUIAEoCzITLnZlcmRhbnQuUm9sZURlbGV0ZUgAUgpyb2xlRGVsZXRlEkkKEm1lbWJlcl'
    '9yb2xlX3VwZGF0ZRgVIAEoCzIZLnZlcmRhbnQuTWVtYmVyUm9sZVVwZGF0ZUgAUhBtZW1iZXJS'
    'b2xlVXBkYXRlEjkKDGZvcmNlX3VwZGF0ZRgWIAEoCzIULnZlcmRhbnQuRm9yY2VVcGRhdGVIAF'
    'ILZm9yY2VVcGRhdGUSTwoUZmVhdHVyZV9mbGFnc191cGRhdGUYFyABKAsyGy52ZXJkYW50LkZl'
    'YXR1cmVGbGFnc1VwZGF0ZUgAUhJmZWF0dXJlRmxhZ3NVcGRhdGUSRQoQcmVsYXRpb25zaGlwX2'
    'FkZBgYIAEoCzIYLnZlcmRhbnQuUmVsYXRpb25zaGlwQWRkSABSD3JlbGF0aW9uc2hpcEFkZBJO'
    'ChNyZWxhdGlvbnNoaXBfcmVtb3ZlGBkgASgLMhsudmVyZGFudC5SZWxhdGlvbnNoaXBSZW1vdm'
    'VIAFIScmVsYXRpb25zaGlwUmVtb3ZlEkYKEWRtX2NoYW5uZWxfY3JlYXRlGBogASgLMhgudmVy'
    'ZGFudC5EbUNoYW5uZWxDcmVhdGVIAFIPZG1DaGFubmVsQ3JlYXRlEkkKEm1lc3NhZ2Vfc2VuZF'
    '9lcnJvchgbIAEoCzIZLnZlcmRhbnQuTWVzc2FnZVNlbmRFcnJvckgAUhBtZXNzYWdlU2VuZEVy'
    'cm9yEkUKEHVwZGF0ZV9hdmFpbGFibGUYHCABKAsyGC52ZXJkYW50LlVwZGF0ZUF2YWlsYWJsZU'
    'gAUg91cGRhdGVBdmFpbGFibGUSLQoId3NfZXJyb3IYHSABKAsyEC52ZXJkYW50LldzRXJyb3JI'
    'AFIHd3NFcnJvchI2CgttZXNzYWdlX3BpbhgeIAEoCzITLnZlcmRhbnQuTWVzc2FnZVBpbkgAUg'
    'ptZXNzYWdlUGluEjwKDW1lc3NhZ2VfdW5waW4YHyABKAsyFS52ZXJkYW50Lk1lc3NhZ2VVbnBp'
    'bkgAUgxtZXNzYWdlVW5waW4SNgoLbWVtYmVyX2pvaW4YICABKAsyEy52ZXJkYW50Lk1lbWJlck'
    'pvaW5IAFIKbWVtYmVySm9pbhJMChN1c2VyX3Byb2ZpbGVfdXBkYXRlGCEgASgLMhoudmVyZGFu'
    'dC5Vc2VyUHJvZmlsZVVwZGF0ZUgAUhF1c2VyUHJvZmlsZVVwZGF0ZRI8Cg1zZXJ2ZXJfdXBkYX'
    'RlGCIgASgLMhUudmVyZGFudC5TZXJ2ZXJVcGRhdGVIAFIMc2VydmVyVXBkYXRlEk8KFHNlcnZl'
    'cl9lbW9qaXNfdXBkYXRlGCMgASgLMhsudmVyZGFudC5TZXJ2ZXJFbW9qaXNVcGRhdGVIAFISc2'
    'VydmVyRW1vamlzVXBkYXRlEk0KFGRtX25hbWVfY29sb3JfdXBkYXRlGCQgASgLMhoudmVyZGFu'
    'dC5EbU5hbWVDb2xvclVwZGF0ZUgAUhFkbU5hbWVDb2xvclVwZGF0ZRJOChNhbm5vdW5jZW1lbn'
    'RfY3JlYXRlGCogASgLMhsudmVyZGFudC5Bbm5vdW5jZW1lbnRDcmVhdGVIAFISYW5ub3VuY2Vt'
    'ZW50Q3JlYXRlEk4KE2Fubm91bmNlbWVudF91cGRhdGUYKyABKAsyGy52ZXJkYW50LkFubm91bm'
    'NlbWVudFVwZGF0ZUgAUhJhbm5vdW5jZW1lbnRVcGRhdGUSTgoTYW5ub3VuY2VtZW50X2RlbGV0'
    'ZRgsIAEoCzIbLnZlcmRhbnQuQW5ub3VuY2VtZW50RGVsZXRlSABSEmFubm91bmNlbWVudERlbG'
    'V0ZRI2CgtmZWVkX2NyZWF0ZRgtIAEoCzITLnZlcmRhbnQuRmVlZENyZWF0ZUgAUgpmZWVkQ3Jl'
    'YXRlEjYKC2ZlZWRfdXBkYXRlGC4gASgLMhMudmVyZGFudC5GZWVkVXBkYXRlSABSCmZlZWRVcG'
    'RhdGUSNgoLZmVlZF9kZWxldGUYLyABKAsyEy52ZXJkYW50LkZlZWREZWxldGVIAFIKZmVlZERl'
    'bGV0ZRI2CgtyZWFkeV9kZWx0YRgwIAEoCzITLnZlcmRhbnQuUmVhZHlEZWx0YUgAUgpyZWFkeU'
    'RlbHRhEiYKBWJhdGNoGDEgASgLMg4udmVyZGFudC5CYXRjaEgAUgViYXRjaBJSChVjaGFubmVs'
    'X3VucmVhZF9zaWduYWwYPyABKAsyHC52ZXJkYW50LkNoYW5uZWxVbnJlYWRTaWduYWxIAFITY2'
    'hhbm5lbFVucmVhZFNpZ25hbBJYChdjaGFubmVsX2FjdGl2aXR5X3VwZGF0ZRhAIAEoCzIeLnZl'
    'cmRhbnQuQ2hhbm5lbEFjdGl2aXR5VXBkYXRlSABSFWNoYW5uZWxBY3Rpdml0eVVwZGF0ZRIjCg'
    'RwaW5nGCggASgLMg0udmVyZGFudC5QaW5nSABSBHBpbmcSIwoEcG9uZxgpIAEoCzINLnZlcmRh'
    'bnQuUG9uZ0gAUgRwb25nEi8KCGlkZW50aWZ5GDIgASgLMhEudmVyZGFudC5JZGVudGlmeUgAUg'
    'hpZGVudGlmeRJMChNjbGllbnRfdHlwaW5nX3N0YXJ0GDMgASgLMhoudmVyZGFudC5DbGllbnRU'
    'eXBpbmdTdGFydEgAUhFjbGllbnRUeXBpbmdTdGFydBJVChZjbGllbnRfcHJlc2VuY2VfdXBkYX'
    'RlGDQgASgLMh0udmVyZGFudC5DbGllbnRQcmVzZW5jZVVwZGF0ZUgAUhRjbGllbnRQcmVzZW5j'
    'ZVVwZGF0ZRJMChNjbGllbnRfbWVzc2FnZV9zZW5kGDUgASgLMhoudmVyZGFudC5DbGllbnRNZX'
    'NzYWdlU2VuZEgAUhFjbGllbnRNZXNzYWdlU2VuZBJMChNjbGllbnRfbWVzc2FnZV9lZGl0GDYg'
    'ASgLMhoudmVyZGFudC5DbGllbnRNZXNzYWdlRWRpdEgAUhFjbGllbnRNZXNzYWdlRWRpdBJSCh'
    'VjbGllbnRfbWVzc2FnZV9kZWxldGUYNyABKAsyHC52ZXJkYW50LkNsaWVudE1lc3NhZ2VEZWxl'
    'dGVIAFITY2xpZW50TWVzc2FnZURlbGV0ZRJMChNjbGllbnRfcmVhY3Rpb25fYWRkGDggASgLMh'
    'oudmVyZGFudC5DbGllbnRSZWFjdGlvbkFkZEgAUhFjbGllbnRSZWFjdGlvbkFkZBJVChZjbGll'
    'bnRfcmVhY3Rpb25fcmVtb3ZlGDkgASgLMh0udmVyZGFudC5DbGllbnRSZWFjdGlvblJlbW92ZU'
    'gAUhRjbGllbnRSZWFjdGlvblJlbW92ZRJJChJjbGllbnRfY2hhbm5lbF9hY2sYOiABKAsyGS52'
    'ZXJkYW50LkNsaWVudENoYW5uZWxBY2tIAFIQY2xpZW50Q2hhbm5lbEFjaxJJChJjbGllbnRfdm'
    '9pY2Vfc3RhdGUYOyABKAsyGS52ZXJkYW50LkNsaWVudFZvaWNlU3RhdGVIAFIQY2xpZW50Vm9p'
    'Y2VTdGF0ZRJJChJjbGllbnRfdm9pY2VfbGVhdmUYPCABKAsyGS52ZXJkYW50LkNsaWVudFZvaW'
    'NlTGVhdmVIAFIQY2xpZW50Vm9pY2VMZWF2ZRJMChNjbGllbnRfZm9jdXNfc2VydmVyGD0gASgL'
    'MhoudmVyZGFudC5DbGllbnRGb2N1c1NlcnZlckgAUhFjbGllbnRGb2N1c1NlcnZlchJVChZjbG'
    'llbnRfcmVxdWVzdF9tZW1iZXJzGD4gASgLMh0udmVyZGFudC5DbGllbnRSZXF1ZXN0TWVtYmVy'
    'c0gAUhRjbGllbnRSZXF1ZXN0TWVtYmVycxJPChRjbGllbnRfZm9jdXNfY2hhbm5lbBhBIAEoCz'
    'IbLnZlcmRhbnQuQ2xpZW50Rm9jdXNDaGFubmVsSABSEmNsaWVudEZvY3VzQ2hhbm5lbEIJCgdw'
    'YXlsb2Fk');

@$core.Deprecated('Use readyDescriptor instead')
const Ready$json = {
  '1': 'Ready',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'servers',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.verdant.Server',
      '10': 'servers'
    },
    {'1': 'server_order', '3': 4, '4': 3, '5': 9, '10': 'serverOrder'},
    {'1': 'favorite_order', '3': 5, '4': 3, '5': 9, '10': 'favoriteOrder'},
    {
      '1': 'categories',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.verdant.Category',
      '10': 'categories'
    },
    {
      '1': 'channels',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.verdant.Channel',
      '10': 'channels'
    },
    {
      '1': 'emojis',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.verdant.Emoji',
      '10': 'emojis'
    },
    {'1': 'dm_channel_ids', '3': 9, '4': 3, '5': 9, '10': 'dmChannelIds'},
    {
      '1': 'relationships',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.verdant.Relationship',
      '10': 'relationships'
    },
    {
      '1': 'dm_channels',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.verdant.DmChannel',
      '10': 'dmChannels'
    },
    {
      '1': 'voice_states',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.verdant.VoiceState',
      '10': 'voiceStates'
    },
    {
      '1': 'read_states',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.verdant.ChannelReadState',
      '10': 'readStates'
    },
    {
      '1': 'roles',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.verdant.Role',
      '10': 'roles'
    },
    {
      '1': 'member_role_ids',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.verdant.Ready.MemberRoleIdsEntry',
      '10': 'memberRoleIds'
    },
    {'1': 'server_version', '3': 16, '4': 1, '5': 9, '10': 'serverVersion'},
    {
      '1': 'min_client_version',
      '3': 17,
      '4': 1,
      '5': 9,
      '10': 'minClientVersion'
    },
    {
      '1': 'feature_flags',
      '3': 18,
      '4': 3,
      '5': 11,
      '6': '.verdant.Ready.FeatureFlagsEntry',
      '10': 'featureFlags'
    },
    {'1': 'username', '3': 19, '4': 1, '5': 9, '10': 'username'},
    {
      '1': 'display_name',
      '3': 20,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'displayName',
      '17': true
    },
    {
      '1': 'avatar_url',
      '3': 21,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'avatarUrl',
      '17': true
    },
    {
      '1': 'banner_url',
      '3': 22,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'bannerUrl',
      '17': true
    },
    {'1': 'user_status', '3': 23, '4': 1, '5': 9, '10': 'userStatus'},
    {
      '1': 'presences',
      '3': 24,
      '4': 3,
      '5': 11,
      '6': '.verdant.PresenceEntry',
      '10': 'presences'
    },
    {
      '1': 'preferences_json',
      '3': 25,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'preferencesJson',
      '17': true
    },
    {
      '1': 'subscription_json',
      '3': 26,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'subscriptionJson',
      '17': true
    },
    {
      '1': 'feeds',
      '3': 27,
      '4': 3,
      '5': 11,
      '6': '.verdant.Feed',
      '10': 'feeds'
    },
    {
      '1': 'entitlements_json',
      '3': 28,
      '4': 1,
      '5': 9,
      '9': 5,
      '10': 'entitlementsJson',
      '17': true
    },
    {
      '1': 'instance_json',
      '3': 29,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'instanceJson',
      '17': true
    },
    {
      '1': 'username_set',
      '3': 30,
      '4': 1,
      '5': 8,
      '9': 7,
      '10': 'usernameSet',
      '17': true
    },
  ],
  '3': [Ready_MemberRoleIdsEntry$json, Ready_FeatureFlagsEntry$json],
  '8': [
    {'1': '_display_name'},
    {'1': '_avatar_url'},
    {'1': '_banner_url'},
    {'1': '_preferences_json'},
    {'1': '_subscription_json'},
    {'1': '_entitlements_json'},
    {'1': '_instance_json'},
    {'1': '_username_set'},
  ],
};

@$core.Deprecated('Use readyDescriptor instead')
const Ready_MemberRoleIdsEntry$json = {
  '1': 'MemberRoleIdsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.verdant.MemberRoleIds',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use readyDescriptor instead')
const Ready_FeatureFlagsEntry$json = {
  '1': 'FeatureFlagsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Ready`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readyDescriptor = $convert.base64Decode(
    'CgVSZWFkeRIdCgpzZXNzaW9uX2lkGAEgASgJUglzZXNzaW9uSWQSFwoHdXNlcl9pZBgCIAEoCV'
    'IGdXNlcklkEikKB3NlcnZlcnMYAyADKAsyDy52ZXJkYW50LlNlcnZlclIHc2VydmVycxIhCgxz'
    'ZXJ2ZXJfb3JkZXIYBCADKAlSC3NlcnZlck9yZGVyEiUKDmZhdm9yaXRlX29yZGVyGAUgAygJUg'
    '1mYXZvcml0ZU9yZGVyEjEKCmNhdGVnb3JpZXMYBiADKAsyES52ZXJkYW50LkNhdGVnb3J5Ugpj'
    'YXRlZ29yaWVzEiwKCGNoYW5uZWxzGAcgAygLMhAudmVyZGFudC5DaGFubmVsUghjaGFubmVscx'
    'ImCgZlbW9qaXMYCCADKAsyDi52ZXJkYW50LkVtb2ppUgZlbW9qaXMSJAoOZG1fY2hhbm5lbF9p'
    'ZHMYCSADKAlSDGRtQ2hhbm5lbElkcxI7Cg1yZWxhdGlvbnNoaXBzGAogAygLMhUudmVyZGFudC'
    '5SZWxhdGlvbnNoaXBSDXJlbGF0aW9uc2hpcHMSMwoLZG1fY2hhbm5lbHMYCyADKAsyEi52ZXJk'
    'YW50LkRtQ2hhbm5lbFIKZG1DaGFubmVscxI2Cgx2b2ljZV9zdGF0ZXMYDCADKAsyEy52ZXJkYW'
    '50LlZvaWNlU3RhdGVSC3ZvaWNlU3RhdGVzEjoKC3JlYWRfc3RhdGVzGA0gAygLMhkudmVyZGFu'
    'dC5DaGFubmVsUmVhZFN0YXRlUgpyZWFkU3RhdGVzEiMKBXJvbGVzGA4gAygLMg0udmVyZGFudC'
    '5Sb2xlUgVyb2xlcxJJCg9tZW1iZXJfcm9sZV9pZHMYDyADKAsyIS52ZXJkYW50LlJlYWR5Lk1l'
    'bWJlclJvbGVJZHNFbnRyeVINbWVtYmVyUm9sZUlkcxIlCg5zZXJ2ZXJfdmVyc2lvbhgQIAEoCV'
    'INc2VydmVyVmVyc2lvbhIsChJtaW5fY2xpZW50X3ZlcnNpb24YESABKAlSEG1pbkNsaWVudFZl'
    'cnNpb24SRQoNZmVhdHVyZV9mbGFncxgSIAMoCzIgLnZlcmRhbnQuUmVhZHkuRmVhdHVyZUZsYW'
    'dzRW50cnlSDGZlYXR1cmVGbGFncxIaCgh1c2VybmFtZRgTIAEoCVIIdXNlcm5hbWUSJgoMZGlz'
    'cGxheV9uYW1lGBQgASgJSABSC2Rpc3BsYXlOYW1liAEBEiIKCmF2YXRhcl91cmwYFSABKAlIAV'
    'IJYXZhdGFyVXJsiAEBEiIKCmJhbm5lcl91cmwYFiABKAlIAlIJYmFubmVyVXJsiAEBEh8KC3Vz'
    'ZXJfc3RhdHVzGBcgASgJUgp1c2VyU3RhdHVzEjQKCXByZXNlbmNlcxgYIAMoCzIWLnZlcmRhbn'
    'QuUHJlc2VuY2VFbnRyeVIJcHJlc2VuY2VzEi4KEHByZWZlcmVuY2VzX2pzb24YGSABKAlIA1IP'
    'cHJlZmVyZW5jZXNKc29uiAEBEjAKEXN1YnNjcmlwdGlvbl9qc29uGBogASgJSARSEHN1YnNjcm'
    'lwdGlvbkpzb26IAQESIwoFZmVlZHMYGyADKAsyDS52ZXJkYW50LkZlZWRSBWZlZWRzEjAKEWVu'
    'dGl0bGVtZW50c19qc29uGBwgASgJSAVSEGVudGl0bGVtZW50c0pzb26IAQESKAoNaW5zdGFuY2'
    'VfanNvbhgdIAEoCUgGUgxpbnN0YW5jZUpzb26IAQESJgoMdXNlcm5hbWVfc2V0GB4gASgISAdS'
    'C3VzZXJuYW1lU2V0iAEBGlgKEk1lbWJlclJvbGVJZHNFbnRyeRIQCgNrZXkYASABKAlSA2tleR'
    'IsCgV2YWx1ZRgCIAEoCzIWLnZlcmRhbnQuTWVtYmVyUm9sZUlkc1IFdmFsdWU6AjgBGj8KEUZl'
    'YXR1cmVGbGFnc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgIUgV2YWx1ZT'
    'oCOAFCDwoNX2Rpc3BsYXlfbmFtZUINCgtfYXZhdGFyX3VybEINCgtfYmFubmVyX3VybEITChFf'
    'cHJlZmVyZW5jZXNfanNvbkIUChJfc3Vic2NyaXB0aW9uX2pzb25CFAoSX2VudGl0bGVtZW50c1'
    '9qc29uQhAKDl9pbnN0YW5jZV9qc29uQg8KDV91c2VybmFtZV9zZXQ=');

@$core.Deprecated('Use memberRoleIdsDescriptor instead')
const MemberRoleIds$json = {
  '1': 'MemberRoleIds',
  '2': [
    {'1': 'role_ids', '3': 1, '4': 3, '5': 9, '10': 'roleIds'},
  ],
};

/// Descriptor for `MemberRoleIds`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberRoleIdsDescriptor = $convert
    .base64Decode('Cg1NZW1iZXJSb2xlSWRzEhkKCHJvbGVfaWRzGAEgAygJUgdyb2xlSWRz');

@$core.Deprecated('Use readyDeltaDescriptor instead')
const ReadyDelta$json = {
  '1': 'ReadyDelta',
  '2': [
    {
      '1': 'updated_channels',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.verdant.Channel',
      '10': 'updatedChannels'
    },
    {
      '1': 'removed_channel_ids',
      '3': 2,
      '4': 3,
      '5': 9,
      '10': 'removedChannelIds'
    },
    {
      '1': 'updated_roles',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.verdant.Role',
      '10': 'updatedRoles'
    },
    {'1': 'removed_role_ids', '3': 4, '4': 3, '5': 9, '10': 'removedRoleIds'},
    {
      '1': 'read_states',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.verdant.ChannelReadState',
      '10': 'readStates'
    },
    {
      '1': 'presences',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.verdant.PresenceEntry',
      '10': 'presences'
    },
    {'1': 'server_version', '3': 7, '4': 1, '5': 9, '10': 'serverVersion'},
    {'1': 'session_id', '3': 8, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'feature_flags',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.verdant.ReadyDelta.FeatureFlagsEntry',
      '10': 'featureFlags'
    },
  ],
  '3': [ReadyDelta_FeatureFlagsEntry$json],
};

@$core.Deprecated('Use readyDeltaDescriptor instead')
const ReadyDelta_FeatureFlagsEntry$json = {
  '1': 'FeatureFlagsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ReadyDelta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readyDeltaDescriptor = $convert.base64Decode(
    'CgpSZWFkeURlbHRhEjsKEHVwZGF0ZWRfY2hhbm5lbHMYASADKAsyEC52ZXJkYW50LkNoYW5uZW'
    'xSD3VwZGF0ZWRDaGFubmVscxIuChNyZW1vdmVkX2NoYW5uZWxfaWRzGAIgAygJUhFyZW1vdmVk'
    'Q2hhbm5lbElkcxIyCg11cGRhdGVkX3JvbGVzGAMgAygLMg0udmVyZGFudC5Sb2xlUgx1cGRhdG'
    'VkUm9sZXMSKAoQcmVtb3ZlZF9yb2xlX2lkcxgEIAMoCVIOcmVtb3ZlZFJvbGVJZHMSOgoLcmVh'
    'ZF9zdGF0ZXMYBSADKAsyGS52ZXJkYW50LkNoYW5uZWxSZWFkU3RhdGVSCnJlYWRTdGF0ZXMSNA'
    'oJcHJlc2VuY2VzGAYgAygLMhYudmVyZGFudC5QcmVzZW5jZUVudHJ5UglwcmVzZW5jZXMSJQoO'
    'c2VydmVyX3ZlcnNpb24YByABKAlSDXNlcnZlclZlcnNpb24SHQoKc2Vzc2lvbl9pZBgIIAEoCV'
    'IJc2Vzc2lvbklkEkoKDWZlYXR1cmVfZmxhZ3MYCSADKAsyJS52ZXJkYW50LlJlYWR5RGVsdGEu'
    'RmVhdHVyZUZsYWdzRW50cnlSDGZlYXR1cmVGbGFncxo/ChFGZWF0dXJlRmxhZ3NFbnRyeRIQCg'
    'NrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCFIFdmFsdWU6AjgB');

@$core.Deprecated('Use presenceEntryDescriptor instead')
const PresenceEntry$json = {
  '1': 'PresenceEntry',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `PresenceEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceEntryDescriptor = $convert.base64Decode(
    'Cg1QcmVzZW5jZUVudHJ5EhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIWCgZzdGF0dXMYAiABKA'
    'lSBnN0YXR1cw==');

@$core.Deprecated('Use messageCreateDescriptor instead')
const MessageCreate$json = {
  '1': 'MessageCreate',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Message',
      '10': 'message'
    },
  ],
};

/// Descriptor for `MessageCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageCreateDescriptor = $convert.base64Decode(
    'Cg1NZXNzYWdlQ3JlYXRlEioKB21lc3NhZ2UYASABKAsyEC52ZXJkYW50Lk1lc3NhZ2VSB21lc3'
    'NhZ2U=');

@$core.Deprecated('Use messageUpdateDescriptor instead')
const MessageUpdate$json = {
  '1': 'MessageUpdate',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Message',
      '10': 'message'
    },
  ],
};

/// Descriptor for `MessageUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageUpdateDescriptor = $convert.base64Decode(
    'Cg1NZXNzYWdlVXBkYXRlEioKB21lc3NhZ2UYASABKAsyEC52ZXJkYW50Lk1lc3NhZ2VSB21lc3'
    'NhZ2U=');

@$core.Deprecated('Use messageDeleteDescriptor instead')
const MessageDelete$json = {
  '1': 'MessageDelete',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
  ],
};

/// Descriptor for `MessageDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDeleteDescriptor = $convert.base64Decode(
    'Cg1NZXNzYWdlRGVsZXRlEg4KAmlkGAEgASgJUgJpZBIdCgpjaGFubmVsX2lkGAIgASgJUgljaG'
    'FubmVsSWQ=');

@$core.Deprecated('Use channelUnreadSignalDescriptor instead')
const ChannelUnreadSignal$json = {
  '1': 'ChannelUnreadSignal',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {
      '1': 'server_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'serverId',
      '17': true
    },
    {'1': 'message_id', '3': 3, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'author_id', '3': 4, '4': 1, '5': 9, '10': 'authorId'},
    {'1': 'created_at', '3': 5, '4': 1, '5': 9, '10': 'createdAt'},
    {
      '1': 'mentions_current_user',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'mentionsCurrentUser'
    },
    {'1': 'dm', '3': 7, '4': 1, '5': 8, '10': 'dm'},
  ],
  '8': [
    {'1': '_server_id'},
  ],
};

/// Descriptor for `ChannelUnreadSignal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelUnreadSignalDescriptor = $convert.base64Decode(
    'ChNDaGFubmVsVW5yZWFkU2lnbmFsEh0KCmNoYW5uZWxfaWQYASABKAlSCWNoYW5uZWxJZBIgCg'
    'lzZXJ2ZXJfaWQYAiABKAlIAFIIc2VydmVySWSIAQESHQoKbWVzc2FnZV9pZBgDIAEoCVIJbWVz'
    'c2FnZUlkEhsKCWF1dGhvcl9pZBgEIAEoCVIIYXV0aG9ySWQSHQoKY3JlYXRlZF9hdBgFIAEoCV'
    'IJY3JlYXRlZEF0EjIKFW1lbnRpb25zX2N1cnJlbnRfdXNlchgGIAEoCFITbWVudGlvbnNDdXJy'
    'ZW50VXNlchIOCgJkbRgHIAEoCFICZG1CDAoKX3NlcnZlcl9pZA==');

@$core.Deprecated('Use channelActivityUpdateDescriptor instead')
const ChannelActivityUpdate$json = {
  '1': 'ChannelActivityUpdate',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'last_message_at', '3': 3, '4': 1, '5': 9, '10': 'lastMessageAt'},
    {
      '1': 'username',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'username',
      '17': true
    },
    {
      '1': 'display_name',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'displayName',
      '17': true
    },
    {
      '1': 'avatar_url',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'avatarUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_username'},
    {'1': '_display_name'},
    {'1': '_avatar_url'},
  ],
};

/// Descriptor for `ChannelActivityUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelActivityUpdateDescriptor = $convert.base64Decode(
    'ChVDaGFubmVsQWN0aXZpdHlVcGRhdGUSHQoKY2hhbm5lbF9pZBgBIAEoCVIJY2hhbm5lbElkEh'
    'cKB3VzZXJfaWQYAiABKAlSBnVzZXJJZBImCg9sYXN0X21lc3NhZ2VfYXQYAyABKAlSDWxhc3RN'
    'ZXNzYWdlQXQSHwoIdXNlcm5hbWUYBCABKAlIAFIIdXNlcm5hbWWIAQESJgoMZGlzcGxheV9uYW'
    '1lGAUgASgJSAFSC2Rpc3BsYXlOYW1liAEBEiIKCmF2YXRhcl91cmwYBiABKAlIAlIJYXZhdGFy'
    'VXJsiAEBQgsKCV91c2VybmFtZUIPCg1fZGlzcGxheV9uYW1lQg0KC19hdmF0YXJfdXJs');

@$core.Deprecated('Use typingStartDescriptor instead')
const TypingStart$json = {
  '1': 'TypingStart',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 9, '10': 'timestamp'},
  ],
};

/// Descriptor for `TypingStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typingStartDescriptor = $convert.base64Decode(
    'CgtUeXBpbmdTdGFydBIdCgpjaGFubmVsX2lkGAEgASgJUgljaGFubmVsSWQSFwoHdXNlcl9pZB'
    'gCIAEoCVIGdXNlcklkEhwKCXRpbWVzdGFtcBgDIAEoCVIJdGltZXN0YW1w');

@$core.Deprecated('Use presenceUpdateDescriptor instead')
const PresenceUpdate$json = {
  '1': 'PresenceUpdate',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.verdant.UserStatus',
      '10': 'status'
    },
  ],
};

/// Descriptor for `PresenceUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceUpdateDescriptor = $convert.base64Decode(
    'Cg5QcmVzZW5jZVVwZGF0ZRIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSKwoGc3RhdHVzGAIgAS'
    'gOMhMudmVyZGFudC5Vc2VyU3RhdHVzUgZzdGF0dXM=');

@$core.Deprecated('Use channelCreateDescriptor instead')
const ChannelCreate$json = {
  '1': 'ChannelCreate',
  '2': [
    {
      '1': 'channel',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Channel',
      '10': 'channel'
    },
  ],
};

/// Descriptor for `ChannelCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelCreateDescriptor = $convert.base64Decode(
    'Cg1DaGFubmVsQ3JlYXRlEioKB2NoYW5uZWwYASABKAsyEC52ZXJkYW50LkNoYW5uZWxSB2NoYW'
    '5uZWw=');

@$core.Deprecated('Use channelUpdateDescriptor instead')
const ChannelUpdate$json = {
  '1': 'ChannelUpdate',
  '2': [
    {
      '1': 'channel',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Channel',
      '10': 'channel'
    },
  ],
};

/// Descriptor for `ChannelUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelUpdateDescriptor = $convert.base64Decode(
    'Cg1DaGFubmVsVXBkYXRlEioKB2NoYW5uZWwYASABKAsyEC52ZXJkYW50LkNoYW5uZWxSB2NoYW'
    '5uZWw=');

@$core.Deprecated('Use channelDeleteDescriptor instead')
const ChannelDelete$json = {
  '1': 'ChannelDelete',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'server_id', '3': 2, '4': 1, '5': 9, '10': 'serverId'},
  ],
};

/// Descriptor for `ChannelDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelDeleteDescriptor = $convert.base64Decode(
    'Cg1DaGFubmVsRGVsZXRlEh0KCmNoYW5uZWxfaWQYASABKAlSCWNoYW5uZWxJZBIbCglzZXJ2ZX'
    'JfaWQYAiABKAlSCHNlcnZlcklk');

@$core.Deprecated('Use memberRemoveDescriptor instead')
const MemberRemove$json = {
  '1': 'MemberRemove',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `MemberRemove`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberRemoveDescriptor = $convert.base64Decode(
    'CgxNZW1iZXJSZW1vdmUSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZBIXCgd1c2VyX2lkGA'
    'IgASgJUgZ1c2VySWQ=');

@$core.Deprecated('Use serverDeleteDescriptor instead')
const ServerDelete$json = {
  '1': 'ServerDelete',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
  ],
};

/// Descriptor for `ServerDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverDeleteDescriptor = $convert.base64Decode(
    'CgxTZXJ2ZXJEZWxldGUSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZA==');

@$core.Deprecated('Use voiceStateUpdateDescriptor instead')
const VoiceStateUpdate$json = {
  '1': 'VoiceStateUpdate',
  '2': [
    {
      '1': 'voice_state',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.VoiceState',
      '10': 'voiceState'
    },
  ],
};

/// Descriptor for `VoiceStateUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List voiceStateUpdateDescriptor = $convert.base64Decode(
    'ChBWb2ljZVN0YXRlVXBkYXRlEjQKC3ZvaWNlX3N0YXRlGAEgASgLMhMudmVyZGFudC5Wb2ljZV'
    'N0YXRlUgp2b2ljZVN0YXRl');

@$core.Deprecated('Use categoryCreateDescriptor instead')
const CategoryCreate$json = {
  '1': 'CategoryCreate',
  '2': [
    {
      '1': 'category',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Category',
      '10': 'category'
    },
  ],
};

/// Descriptor for `CategoryCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoryCreateDescriptor = $convert.base64Decode(
    'Cg5DYXRlZ29yeUNyZWF0ZRItCghjYXRlZ29yeRgBIAEoCzIRLnZlcmRhbnQuQ2F0ZWdvcnlSCG'
    'NhdGVnb3J5');

@$core.Deprecated('Use categoryUpdateDescriptor instead')
const CategoryUpdate$json = {
  '1': 'CategoryUpdate',
  '2': [
    {
      '1': 'category',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Category',
      '10': 'category'
    },
  ],
};

/// Descriptor for `CategoryUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoryUpdateDescriptor = $convert.base64Decode(
    'Cg5DYXRlZ29yeVVwZGF0ZRItCghjYXRlZ29yeRgBIAEoCzIRLnZlcmRhbnQuQ2F0ZWdvcnlSCG'
    'NhdGVnb3J5');

@$core.Deprecated('Use categoryDeleteDescriptor instead')
const CategoryDelete$json = {
  '1': 'CategoryDelete',
  '2': [
    {'1': 'category_id', '3': 1, '4': 1, '5': 9, '10': 'categoryId'},
    {'1': 'server_id', '3': 2, '4': 1, '5': 9, '10': 'serverId'},
  ],
};

/// Descriptor for `CategoryDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoryDeleteDescriptor = $convert.base64Decode(
    'Cg5DYXRlZ29yeURlbGV0ZRIfCgtjYXRlZ29yeV9pZBgBIAEoCVIKY2F0ZWdvcnlJZBIbCglzZX'
    'J2ZXJfaWQYAiABKAlSCHNlcnZlcklk');

@$core.Deprecated('Use reactionAddDescriptor instead')
const ReactionAdd$json = {
  '1': 'ReactionAdd',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'user_id', '3': 3, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'emoji', '3': 4, '4': 1, '5': 9, '10': 'emoji'},
    {
      '1': 'emoji_id',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'emojiId',
      '17': true
    },
  ],
  '8': [
    {'1': '_emoji_id'},
  ],
};

/// Descriptor for `ReactionAdd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reactionAddDescriptor = $convert.base64Decode(
    'CgtSZWFjdGlvbkFkZBIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSHQoKY2hhbm5lbF'
    '9pZBgCIAEoCVIJY2hhbm5lbElkEhcKB3VzZXJfaWQYAyABKAlSBnVzZXJJZBIUCgVlbW9qaRgE'
    'IAEoCVIFZW1vamkSHgoIZW1vamlfaWQYBSABKAlIAFIHZW1vamlJZIgBAUILCglfZW1vamlfaW'
    'Q=');

@$core.Deprecated('Use reactionRemoveDescriptor instead')
const ReactionRemove$json = {
  '1': 'ReactionRemove',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'user_id', '3': 3, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'emoji', '3': 4, '4': 1, '5': 9, '10': 'emoji'},
  ],
};

/// Descriptor for `ReactionRemove`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reactionRemoveDescriptor = $convert.base64Decode(
    'Cg5SZWFjdGlvblJlbW92ZRIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSHQoKY2hhbm'
    '5lbF9pZBgCIAEoCVIJY2hhbm5lbElkEhcKB3VzZXJfaWQYAyABKAlSBnVzZXJJZBIUCgVlbW9q'
    'aRgEIAEoCVIFZW1vamk=');

@$core.Deprecated('Use roleCreateDescriptor instead')
const RoleCreate$json = {
  '1': 'RoleCreate',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'role', '3': 2, '4': 1, '5': 11, '6': '.verdant.Role', '10': 'role'},
  ],
};

/// Descriptor for `RoleCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleCreateDescriptor = $convert.base64Decode(
    'CgpSb2xlQ3JlYXRlEhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySWQSIQoEcm9sZRgCIAEoCz'
    'INLnZlcmRhbnQuUm9sZVIEcm9sZQ==');

@$core.Deprecated('Use roleUpdateDescriptor instead')
const RoleUpdate$json = {
  '1': 'RoleUpdate',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'role', '3': 2, '4': 1, '5': 11, '6': '.verdant.Role', '10': 'role'},
  ],
};

/// Descriptor for `RoleUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleUpdateDescriptor = $convert.base64Decode(
    'CgpSb2xlVXBkYXRlEhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySWQSIQoEcm9sZRgCIAEoCz'
    'INLnZlcmRhbnQuUm9sZVIEcm9sZQ==');

@$core.Deprecated('Use roleDeleteDescriptor instead')
const RoleDelete$json = {
  '1': 'RoleDelete',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'role_id', '3': 2, '4': 1, '5': 9, '10': 'roleId'},
  ],
};

/// Descriptor for `RoleDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleDeleteDescriptor = $convert.base64Decode(
    'CgpSb2xlRGVsZXRlEhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySWQSFwoHcm9sZV9pZBgCIA'
    'EoCVIGcm9sZUlk');

@$core.Deprecated('Use memberRoleUpdateDescriptor instead')
const MemberRoleUpdate$json = {
  '1': 'MemberRoleUpdate',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'role_ids', '3': 3, '4': 3, '5': 9, '10': 'roleIds'},
  ],
};

/// Descriptor for `MemberRoleUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberRoleUpdateDescriptor = $convert.base64Decode(
    'ChBNZW1iZXJSb2xlVXBkYXRlEhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySWQSFwoHdXNlcl'
    '9pZBgCIAEoCVIGdXNlcklkEhkKCHJvbGVfaWRzGAMgAygJUgdyb2xlSWRz');

@$core.Deprecated('Use forceUpdateDescriptor instead')
const ForceUpdate$json = {
  '1': 'ForceUpdate',
  '2': [
    {'1': 'min_version', '3': 1, '4': 1, '5': 9, '10': 'minVersion'},
    {'1': 'download_url', '3': 2, '4': 1, '5': 9, '10': 'downloadUrl'},
  ],
};

/// Descriptor for `ForceUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List forceUpdateDescriptor = $convert.base64Decode(
    'CgtGb3JjZVVwZGF0ZRIfCgttaW5fdmVyc2lvbhgBIAEoCVIKbWluVmVyc2lvbhIhCgxkb3dubG'
    '9hZF91cmwYAiABKAlSC2Rvd25sb2FkVXJs');

@$core.Deprecated('Use featureFlagsUpdateDescriptor instead')
const FeatureFlagsUpdate$json = {
  '1': 'FeatureFlagsUpdate',
  '2': [
    {
      '1': 'flags',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.verdant.FeatureFlagsUpdate.FlagsEntry',
      '10': 'flags'
    },
  ],
  '3': [FeatureFlagsUpdate_FlagsEntry$json],
};

@$core.Deprecated('Use featureFlagsUpdateDescriptor instead')
const FeatureFlagsUpdate_FlagsEntry$json = {
  '1': 'FlagsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `FeatureFlagsUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List featureFlagsUpdateDescriptor = $convert.base64Decode(
    'ChJGZWF0dXJlRmxhZ3NVcGRhdGUSPAoFZmxhZ3MYASADKAsyJi52ZXJkYW50LkZlYXR1cmVGbG'
    'Fnc1VwZGF0ZS5GbGFnc0VudHJ5UgVmbGFncxo4CgpGbGFnc0VudHJ5EhAKA2tleRgBIAEoCVID'
    'a2V5EhQKBXZhbHVlGAIgASgIUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use relationshipAddDescriptor instead')
const RelationshipAdd$json = {
  '1': 'RelationshipAdd',
  '2': [
    {
      '1': 'relationship',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Relationship',
      '10': 'relationship'
    },
  ],
};

/// Descriptor for `RelationshipAdd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relationshipAddDescriptor = $convert.base64Decode(
    'Cg9SZWxhdGlvbnNoaXBBZGQSOQoMcmVsYXRpb25zaGlwGAEgASgLMhUudmVyZGFudC5SZWxhdG'
    'lvbnNoaXBSDHJlbGF0aW9uc2hpcA==');

@$core.Deprecated('Use relationshipRemoveDescriptor instead')
const RelationshipRemove$json = {
  '1': 'RelationshipRemove',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `RelationshipRemove`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relationshipRemoveDescriptor =
    $convert.base64Decode(
        'ChJSZWxhdGlvbnNoaXBSZW1vdmUSFwoHdXNlcl9pZBgBIAEoCVIGdXNlcklk');

@$core.Deprecated('Use dmChannelCreateDescriptor instead')
const DmChannelCreate$json = {
  '1': 'DmChannelCreate',
  '2': [
    {
      '1': 'dm_channel',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.DmChannel',
      '10': 'dmChannel'
    },
  ],
};

/// Descriptor for `DmChannelCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dmChannelCreateDescriptor = $convert.base64Decode(
    'Cg9EbUNoYW5uZWxDcmVhdGUSMQoKZG1fY2hhbm5lbBgBIAEoCzISLnZlcmRhbnQuRG1DaGFubm'
    'VsUglkbUNoYW5uZWw=');

@$core.Deprecated('Use messageSendErrorDescriptor instead')
const MessageSendError$json = {
  '1': 'MessageSendError',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 9, '10': 'nonce'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'code', '3': 3, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `MessageSendError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageSendErrorDescriptor = $convert.base64Decode(
    'ChBNZXNzYWdlU2VuZEVycm9yEhQKBW5vbmNlGAEgASgJUgVub25jZRIUCgVlcnJvchgCIAEoCV'
    'IFZXJyb3ISEgoEY29kZRgDIAEoCVIEY29kZQ==');

@$core.Deprecated('Use updateAvailableDescriptor instead')
const UpdateAvailable$json = {
  '1': 'UpdateAvailable',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
    {'1': 'notes', '3': 2, '4': 1, '5': 9, '10': 'notes'},
  ],
};

/// Descriptor for `UpdateAvailable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateAvailableDescriptor = $convert.base64Decode(
    'Cg9VcGRhdGVBdmFpbGFibGUSGAoHdmVyc2lvbhgBIAEoCVIHdmVyc2lvbhIUCgVub3RlcxgCIA'
    'EoCVIFbm90ZXM=');

@$core.Deprecated('Use wsErrorDescriptor instead')
const WsError$json = {
  '1': 'WsError',
  '2': [
    {'1': 'origin_op', '3': 1, '4': 1, '5': 9, '10': 'originOp'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'code', '3': 3, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `WsError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wsErrorDescriptor = $convert.base64Decode(
    'CgdXc0Vycm9yEhsKCW9yaWdpbl9vcBgBIAEoCVIIb3JpZ2luT3ASFAoFZXJyb3IYAiABKAlSBW'
    'Vycm9yEhIKBGNvZGUYAyABKAlSBGNvZGU=');

@$core.Deprecated('Use messagePinDescriptor instead')
const MessagePin$json = {
  '1': 'MessagePin',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'pinned_by', '3': 3, '4': 1, '5': 9, '10': 'pinnedBy'},
  ],
};

/// Descriptor for `MessagePin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messagePinDescriptor = $convert.base64Decode(
    'CgpNZXNzYWdlUGluEh0KCm1lc3NhZ2VfaWQYASABKAlSCW1lc3NhZ2VJZBIdCgpjaGFubmVsX2'
    'lkGAIgASgJUgljaGFubmVsSWQSGwoJcGlubmVkX2J5GAMgASgJUghwaW5uZWRCeQ==');

@$core.Deprecated('Use messageUnpinDescriptor instead')
const MessageUnpin$json = {
  '1': 'MessageUnpin',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'channel_id', '3': 2, '4': 1, '5': 9, '10': 'channelId'},
  ],
};

/// Descriptor for `MessageUnpin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageUnpinDescriptor = $convert.base64Decode(
    'CgxNZXNzYWdlVW5waW4SHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEh0KCmNoYW5uZW'
    'xfaWQYAiABKAlSCWNoYW5uZWxJZA==');

@$core.Deprecated('Use memberJoinDescriptor instead')
const MemberJoin$json = {
  '1': 'MemberJoin',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'username', '3': 3, '4': 1, '5': 9, '10': 'username'},
    {
      '1': 'display_name',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'displayName',
      '17': true
    },
    {
      '1': 'avatar_url',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'avatarUrl',
      '17': true
    },
    {'1': 'joined_at', '3': 6, '4': 1, '5': 9, '10': 'joinedAt'},
  ],
  '8': [
    {'1': '_display_name'},
    {'1': '_avatar_url'},
  ],
};

/// Descriptor for `MemberJoin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberJoinDescriptor = $convert.base64Decode(
    'CgpNZW1iZXJKb2luEhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySWQSFwoHdXNlcl9pZBgCIA'
    'EoCVIGdXNlcklkEhoKCHVzZXJuYW1lGAMgASgJUgh1c2VybmFtZRImCgxkaXNwbGF5X25hbWUY'
    'BCABKAlIAFILZGlzcGxheU5hbWWIAQESIgoKYXZhdGFyX3VybBgFIAEoCUgBUglhdmF0YXJVcm'
    'yIAQESGwoJam9pbmVkX2F0GAYgASgJUghqb2luZWRBdEIPCg1fZGlzcGxheV9uYW1lQg0KC19h'
    'dmF0YXJfdXJs');

@$core.Deprecated('Use userProfileUpdateDescriptor instead')
const UserProfileUpdate$json = {
  '1': 'UserProfileUpdate',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'avatar_url',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'avatarUrl',
      '17': true
    },
    {
      '1': 'banner_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'bannerUrl',
      '17': true
    },
    {
      '1': 'display_name',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'displayName',
      '17': true
    },
    {'1': 'bio', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'bio', '17': true},
    {
      '1': 'banner_base_color',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'bannerBaseColor',
      '17': true
    },
  ],
  '8': [
    {'1': '_avatar_url'},
    {'1': '_banner_url'},
    {'1': '_display_name'},
    {'1': '_bio'},
    {'1': '_banner_base_color'},
  ],
};

/// Descriptor for `UserProfileUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userProfileUpdateDescriptor = $convert.base64Decode(
    'ChFVc2VyUHJvZmlsZVVwZGF0ZRIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSIgoKYXZhdGFyX3'
    'VybBgCIAEoCUgAUglhdmF0YXJVcmyIAQESIgoKYmFubmVyX3VybBgDIAEoCUgBUgliYW5uZXJV'
    'cmyIAQESJgoMZGlzcGxheV9uYW1lGAQgASgJSAJSC2Rpc3BsYXlOYW1liAEBEhUKA2JpbxgFIA'
    'EoCUgDUgNiaW+IAQESMAoRYmFubmVyX2Jhc2VfY29sb3IYBiABKAlIBFIPYmFubmVyQmFzZUNv'
    'bG9yiAEBQg0KC19hdmF0YXJfdXJsQg0KC19iYW5uZXJfdXJsQg8KDV9kaXNwbGF5X25hbWVCBg'
    'oEX2Jpb0IUChJfYmFubmVyX2Jhc2VfY29sb3I=');

@$core.Deprecated('Use identifyDescriptor instead')
const Identify$json = {
  '1': 'Identify',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'client_version',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'clientVersion',
      '17': true
    },
    {
      '1': 'resume_session_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'resumeSessionId',
      '17': true
    },
    {
      '1': 'last_ready_at',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'lastReadyAt',
      '17': true
    },
    {
      '1': 'initial_status',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.verdant.UserStatus',
      '10': 'initialStatus'
    },
    {'1': 'afk', '3': 6, '4': 1, '5': 8, '10': 'afk'},
  ],
  '8': [
    {'1': '_client_version'},
    {'1': '_resume_session_id'},
    {'1': '_last_ready_at'},
  ],
};

/// Descriptor for `Identify`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identifyDescriptor = $convert.base64Decode(
    'CghJZGVudGlmeRIUCgV0b2tlbhgBIAEoCVIFdG9rZW4SKgoOY2xpZW50X3ZlcnNpb24YAiABKA'
    'lIAFINY2xpZW50VmVyc2lvbogBARIvChFyZXN1bWVfc2Vzc2lvbl9pZBgDIAEoCUgBUg9yZXN1'
    'bWVTZXNzaW9uSWSIAQESJwoNbGFzdF9yZWFkeV9hdBgEIAEoCUgCUgtsYXN0UmVhZHlBdIgBAR'
    'I6Cg5pbml0aWFsX3N0YXR1cxgFIAEoDjITLnZlcmRhbnQuVXNlclN0YXR1c1INaW5pdGlhbFN0'
    'YXR1cxIQCgNhZmsYBiABKAhSA2Fma0IRCg9fY2xpZW50X3ZlcnNpb25CFAoSX3Jlc3VtZV9zZX'
    'NzaW9uX2lkQhAKDl9sYXN0X3JlYWR5X2F0');

@$core.Deprecated('Use clientTypingStartDescriptor instead')
const ClientTypingStart$json = {
  '1': 'ClientTypingStart',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
  ],
};

/// Descriptor for `ClientTypingStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientTypingStartDescriptor = $convert.base64Decode(
    'ChFDbGllbnRUeXBpbmdTdGFydBIdCgpjaGFubmVsX2lkGAEgASgJUgljaGFubmVsSWQ=');

@$core.Deprecated('Use clientPresenceUpdateDescriptor instead')
const ClientPresenceUpdate$json = {
  '1': 'ClientPresenceUpdate',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.verdant.UserStatus',
      '10': 'status'
    },
    {'1': 'afk', '3': 2, '4': 1, '5': 8, '10': 'afk'},
  ],
};

/// Descriptor for `ClientPresenceUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientPresenceUpdateDescriptor = $convert.base64Decode(
    'ChRDbGllbnRQcmVzZW5jZVVwZGF0ZRIrCgZzdGF0dXMYASABKA4yEy52ZXJkYW50LlVzZXJTdG'
    'F0dXNSBnN0YXR1cxIQCgNhZmsYAiABKAhSA2Fmaw==');

@$core.Deprecated('Use clientMessageSendDescriptor instead')
const ClientMessageSend$json = {
  '1': 'ClientMessageSend',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {'1': 'nonce', '3': 3, '4': 1, '5': 9, '10': 'nonce'},
    {
      '1': 'reply_to_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'replyToId',
      '17': true
    },
  ],
  '8': [
    {'1': '_reply_to_id'},
  ],
};

/// Descriptor for `ClientMessageSend`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientMessageSendDescriptor = $convert.base64Decode(
    'ChFDbGllbnRNZXNzYWdlU2VuZBIdCgpjaGFubmVsX2lkGAEgASgJUgljaGFubmVsSWQSGAoHY2'
    '9udGVudBgCIAEoCVIHY29udGVudBIUCgVub25jZRgDIAEoCVIFbm9uY2USIwoLcmVwbHlfdG9f'
    'aWQYBCABKAlIAFIJcmVwbHlUb0lkiAEBQg4KDF9yZXBseV90b19pZA==');

@$core.Deprecated('Use clientMessageEditDescriptor instead')
const ClientMessageEdit$json = {
  '1': 'ClientMessageEdit',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'content', '3': 3, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `ClientMessageEdit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientMessageEditDescriptor = $convert.base64Decode(
    'ChFDbGllbnRNZXNzYWdlRWRpdBIdCgpjaGFubmVsX2lkGAEgASgJUgljaGFubmVsSWQSHQoKbW'
    'Vzc2FnZV9pZBgCIAEoCVIJbWVzc2FnZUlkEhgKB2NvbnRlbnQYAyABKAlSB2NvbnRlbnQ=');

@$core.Deprecated('Use clientMessageDeleteDescriptor instead')
const ClientMessageDelete$json = {
  '1': 'ClientMessageDelete',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
  ],
};

/// Descriptor for `ClientMessageDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientMessageDeleteDescriptor = $convert.base64Decode(
    'ChNDbGllbnRNZXNzYWdlRGVsZXRlEh0KCmNoYW5uZWxfaWQYASABKAlSCWNoYW5uZWxJZBIdCg'
    'ptZXNzYWdlX2lkGAIgASgJUgltZXNzYWdlSWQ=');

@$core.Deprecated('Use clientReactionAddDescriptor instead')
const ClientReactionAdd$json = {
  '1': 'ClientReactionAdd',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'emoji', '3': 3, '4': 1, '5': 9, '10': 'emoji'},
    {
      '1': 'emoji_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'emojiId',
      '17': true
    },
  ],
  '8': [
    {'1': '_emoji_id'},
  ],
};

/// Descriptor for `ClientReactionAdd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientReactionAddDescriptor = $convert.base64Decode(
    'ChFDbGllbnRSZWFjdGlvbkFkZBIdCgpjaGFubmVsX2lkGAEgASgJUgljaGFubmVsSWQSHQoKbW'
    'Vzc2FnZV9pZBgCIAEoCVIJbWVzc2FnZUlkEhQKBWVtb2ppGAMgASgJUgVlbW9qaRIeCghlbW9q'
    'aV9pZBgEIAEoCUgAUgdlbW9qaUlkiAEBQgsKCV9lbW9qaV9pZA==');

@$core.Deprecated('Use clientReactionRemoveDescriptor instead')
const ClientReactionRemove$json = {
  '1': 'ClientReactionRemove',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'emoji', '3': 3, '4': 1, '5': 9, '10': 'emoji'},
  ],
};

/// Descriptor for `ClientReactionRemove`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientReactionRemoveDescriptor = $convert.base64Decode(
    'ChRDbGllbnRSZWFjdGlvblJlbW92ZRIdCgpjaGFubmVsX2lkGAEgASgJUgljaGFubmVsSWQSHQ'
    'oKbWVzc2FnZV9pZBgCIAEoCVIJbWVzc2FnZUlkEhQKBWVtb2ppGAMgASgJUgVlbW9qaQ==');

@$core.Deprecated('Use clientChannelAckDescriptor instead')
const ClientChannelAck$json = {
  '1': 'ClientChannelAck',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 9, '10': 'messageId'},
  ],
};

/// Descriptor for `ClientChannelAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientChannelAckDescriptor = $convert.base64Decode(
    'ChBDbGllbnRDaGFubmVsQWNrEh0KCmNoYW5uZWxfaWQYASABKAlSCWNoYW5uZWxJZBIdCgptZX'
    'NzYWdlX2lkGAIgASgJUgltZXNzYWdlSWQ=');

@$core.Deprecated('Use clientVoiceStateDescriptor instead')
const ClientVoiceState$json = {
  '1': 'ClientVoiceState',
  '2': [
    {
      '1': 'self_mute',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'selfMute',
      '17': true
    },
    {
      '1': 'self_deaf',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'selfDeaf',
      '17': true
    },
  ],
  '8': [
    {'1': '_self_mute'},
    {'1': '_self_deaf'},
  ],
};

/// Descriptor for `ClientVoiceState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientVoiceStateDescriptor = $convert.base64Decode(
    'ChBDbGllbnRWb2ljZVN0YXRlEiAKCXNlbGZfbXV0ZRgBIAEoCEgAUghzZWxmTXV0ZYgBARIgCg'
    'lzZWxmX2RlYWYYAiABKAhIAVIIc2VsZkRlYWaIAQFCDAoKX3NlbGZfbXV0ZUIMCgpfc2VsZl9k'
    'ZWFm');

@$core.Deprecated('Use clientVoiceLeaveDescriptor instead')
const ClientVoiceLeave$json = {
  '1': 'ClientVoiceLeave',
};

/// Descriptor for `ClientVoiceLeave`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientVoiceLeaveDescriptor =
    $convert.base64Decode('ChBDbGllbnRWb2ljZUxlYXZl');

@$core.Deprecated('Use serverUpdateDescriptor instead')
const ServerUpdate$json = {
  '1': 'ServerUpdate',
  '2': [
    {
      '1': 'server',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.verdant.Server',
      '10': 'server'
    },
  ],
};

/// Descriptor for `ServerUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverUpdateDescriptor = $convert.base64Decode(
    'CgxTZXJ2ZXJVcGRhdGUSJwoGc2VydmVyGAEgASgLMg8udmVyZGFudC5TZXJ2ZXJSBnNlcnZlcg'
    '==');

@$core.Deprecated('Use serverEmojisUpdateDescriptor instead')
const ServerEmojisUpdate$json = {
  '1': 'ServerEmojisUpdate',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'emoji_version', '3': 2, '4': 1, '5': 5, '10': 'emojiVersion'},
    {
      '1': 'emojis',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.verdant.Emoji',
      '10': 'emojis'
    },
  ],
};

/// Descriptor for `ServerEmojisUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverEmojisUpdateDescriptor = $convert.base64Decode(
    'ChJTZXJ2ZXJFbW9qaXNVcGRhdGUSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZBIjCg1lbW'
    '9qaV92ZXJzaW9uGAIgASgFUgxlbW9qaVZlcnNpb24SJgoGZW1vamlzGAMgAygLMg4udmVyZGFu'
    'dC5FbW9qaVIGZW1vamlz');

@$core.Deprecated('Use dmNameColorUpdateDescriptor instead')
const DmNameColorUpdate$json = {
  '1': 'DmNameColorUpdate',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'name_color',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'nameColor',
      '17': true
    },
  ],
  '8': [
    {'1': '_name_color'},
  ],
};

/// Descriptor for `DmNameColorUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dmNameColorUpdateDescriptor = $convert.base64Decode(
    'ChFEbU5hbWVDb2xvclVwZGF0ZRIdCgpjaGFubmVsX2lkGAEgASgJUgljaGFubmVsSWQSFwoHdX'
    'Nlcl9pZBgCIAEoCVIGdXNlcklkEiIKCm5hbWVfY29sb3IYAyABKAlIAFIJbmFtZUNvbG9yiAEB'
    'Qg0KC19uYW1lX2NvbG9y');

@$core.Deprecated('Use announcementCreateDescriptor instead')
const AnnouncementCreate$json = {
  '1': 'AnnouncementCreate',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'feed_id', '3': 2, '4': 1, '5': 9, '10': 'feedId'},
    {
      '1': 'announcement',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.verdant.Announcement',
      '10': 'announcement'
    },
  ],
};

/// Descriptor for `AnnouncementCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List announcementCreateDescriptor = $convert.base64Decode(
    'ChJBbm5vdW5jZW1lbnRDcmVhdGUSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZBIXCgdmZW'
    'VkX2lkGAIgASgJUgZmZWVkSWQSOQoMYW5ub3VuY2VtZW50GAMgASgLMhUudmVyZGFudC5Bbm5v'
    'dW5jZW1lbnRSDGFubm91bmNlbWVudA==');

@$core.Deprecated('Use announcementUpdateDescriptor instead')
const AnnouncementUpdate$json = {
  '1': 'AnnouncementUpdate',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'feed_id', '3': 2, '4': 1, '5': 9, '10': 'feedId'},
    {
      '1': 'announcement',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.verdant.Announcement',
      '10': 'announcement'
    },
  ],
};

/// Descriptor for `AnnouncementUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List announcementUpdateDescriptor = $convert.base64Decode(
    'ChJBbm5vdW5jZW1lbnRVcGRhdGUSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZBIXCgdmZW'
    'VkX2lkGAIgASgJUgZmZWVkSWQSOQoMYW5ub3VuY2VtZW50GAMgASgLMhUudmVyZGFudC5Bbm5v'
    'dW5jZW1lbnRSDGFubm91bmNlbWVudA==');

@$core.Deprecated('Use announcementDeleteDescriptor instead')
const AnnouncementDelete$json = {
  '1': 'AnnouncementDelete',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'feed_id', '3': 2, '4': 1, '5': 9, '10': 'feedId'},
    {'1': 'announcement_id', '3': 3, '4': 1, '5': 9, '10': 'announcementId'},
  ],
};

/// Descriptor for `AnnouncementDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List announcementDeleteDescriptor = $convert.base64Decode(
    'ChJBbm5vdW5jZW1lbnREZWxldGUSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZBIXCgdmZW'
    'VkX2lkGAIgASgJUgZmZWVkSWQSJwoPYW5ub3VuY2VtZW50X2lkGAMgASgJUg5hbm5vdW5jZW1l'
    'bnRJZA==');

@$core.Deprecated('Use feedCreateDescriptor instead')
const FeedCreate$json = {
  '1': 'FeedCreate',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'feed', '3': 2, '4': 1, '5': 11, '6': '.verdant.Feed', '10': 'feed'},
  ],
};

/// Descriptor for `FeedCreate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List feedCreateDescriptor = $convert.base64Decode(
    'CgpGZWVkQ3JlYXRlEhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySWQSIQoEZmVlZBgCIAEoCz'
    'INLnZlcmRhbnQuRmVlZFIEZmVlZA==');

@$core.Deprecated('Use feedUpdateDescriptor instead')
const FeedUpdate$json = {
  '1': 'FeedUpdate',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'feed', '3': 2, '4': 1, '5': 11, '6': '.verdant.Feed', '10': 'feed'},
  ],
};

/// Descriptor for `FeedUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List feedUpdateDescriptor = $convert.base64Decode(
    'CgpGZWVkVXBkYXRlEhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySWQSIQoEZmVlZBgCIAEoCz'
    'INLnZlcmRhbnQuRmVlZFIEZmVlZA==');

@$core.Deprecated('Use feedDeleteDescriptor instead')
const FeedDelete$json = {
  '1': 'FeedDelete',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'feed_id', '3': 2, '4': 1, '5': 9, '10': 'feedId'},
  ],
};

/// Descriptor for `FeedDelete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List feedDeleteDescriptor = $convert.base64Decode(
    'CgpGZWVkRGVsZXRlEhsKCXNlcnZlcl9pZBgBIAEoCVIIc2VydmVySWQSFwoHZmVlZF9pZBgCIA'
    'EoCVIGZmVlZElk');

@$core.Deprecated('Use clientFocusServerDescriptor instead')
const ClientFocusServer$json = {
  '1': 'ClientFocusServer',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
  ],
};

/// Descriptor for `ClientFocusServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientFocusServerDescriptor = $convert.base64Decode(
    'ChFDbGllbnRGb2N1c1NlcnZlchIbCglzZXJ2ZXJfaWQYASABKAlSCHNlcnZlcklk');

@$core.Deprecated('Use clientFocusChannelDescriptor instead')
const ClientFocusChannel$json = {
  '1': 'ClientFocusChannel',
  '2': [
    {
      '1': 'channel_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'channelId',
      '17': true
    },
  ],
  '8': [
    {'1': '_channel_id'},
  ],
};

/// Descriptor for `ClientFocusChannel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientFocusChannelDescriptor = $convert.base64Decode(
    'ChJDbGllbnRGb2N1c0NoYW5uZWwSIgoKY2hhbm5lbF9pZBgBIAEoCUgAUgljaGFubmVsSWSIAQ'
    'FCDQoLX2NoYW5uZWxfaWQ=');

@$core.Deprecated('Use clientRequestMembersDescriptor instead')
const ClientRequestMembers$json = {
  '1': 'ClientRequestMembers',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'query', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'query', '17': true},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
  '8': [
    {'1': '_query'},
  ],
};

/// Descriptor for `ClientRequestMembers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientRequestMembersDescriptor = $convert.base64Decode(
    'ChRDbGllbnRSZXF1ZXN0TWVtYmVycxIbCglzZXJ2ZXJfaWQYASABKAlSCHNlcnZlcklkEhkKBX'
    'F1ZXJ5GAIgASgJSABSBXF1ZXJ5iAEBEhQKBWxpbWl0GAMgASgFUgVsaW1pdEIICgZfcXVlcnk=');

@$core.Deprecated('Use pingDescriptor instead')
const Ping$json = {
  '1': 'Ping',
};

/// Descriptor for `Ping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingDescriptor = $convert.base64Decode('CgRQaW5n');

@$core.Deprecated('Use pongDescriptor instead')
const Pong$json = {
  '1': 'Pong',
};

/// Descriptor for `Pong`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pongDescriptor = $convert.base64Decode('CgRQb25n');

@$core.Deprecated('Use batchDescriptor instead')
const Batch$json = {
  '1': 'Batch',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.verdant.WsMessage',
      '10': 'messages'
    },
  ],
};

/// Descriptor for `Batch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchDescriptor = $convert.base64Decode(
    'CgVCYXRjaBIuCghtZXNzYWdlcxgBIAMoCzISLnZlcmRhbnQuV3NNZXNzYWdlUghtZXNzYWdlcw'
    '==');
