// This is a generated file - do not edit.
//
// Generated from verdant/ws.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'models.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum WsMessage_Payload {
  ready,
  messageCreate,
  messageUpdate,
  messageDelete,
  typingStart,
  presenceUpdate,
  channelCreate,
  channelUpdate,
  channelDelete,
  memberRemove,
  serverDelete,
  voiceStateUpdate,
  categoryCreate,
  categoryUpdate,
  categoryDelete,
  reactionAdd,
  reactionRemove,
  roleCreate,
  roleUpdate,
  roleDelete,
  memberRoleUpdate,
  forceUpdate,
  featureFlagsUpdate,
  relationshipAdd,
  relationshipRemove,
  dmChannelCreate,
  messageSendError,
  updateAvailable,
  wsError,
  messagePin,
  messageUnpin,
  memberJoin,
  userProfileUpdate,
  serverUpdate,
  serverEmojisUpdate,
  dmNameColorUpdate,
  ping,
  pong,
  announcementCreate,
  announcementUpdate,
  announcementDelete,
  feedCreate,
  feedUpdate,
  feedDelete,
  readyDelta,
  batch,
  identify,
  clientTypingStart,
  clientPresenceUpdate,
  clientMessageSend,
  clientMessageEdit,
  clientMessageDelete,
  clientReactionAdd,
  clientReactionRemove,
  clientChannelAck,
  clientVoiceState,
  clientVoiceLeave,
  clientFocusServer,
  clientRequestMembers,
  channelUnreadSignal,
  channelActivityUpdate,
  clientFocusChannel,
  notSet
}

class WsMessage extends $pb.GeneratedMessage {
  factory WsMessage({
    Ready? ready,
    MessageCreate? messageCreate,
    MessageUpdate? messageUpdate,
    MessageDelete? messageDelete,
    TypingStart? typingStart,
    PresenceUpdate? presenceUpdate,
    ChannelCreate? channelCreate,
    ChannelUpdate? channelUpdate,
    ChannelDelete? channelDelete,
    MemberRemove? memberRemove,
    ServerDelete? serverDelete,
    VoiceStateUpdate? voiceStateUpdate,
    CategoryCreate? categoryCreate,
    CategoryUpdate? categoryUpdate,
    CategoryDelete? categoryDelete,
    ReactionAdd? reactionAdd,
    ReactionRemove? reactionRemove,
    RoleCreate? roleCreate,
    RoleUpdate? roleUpdate,
    RoleDelete? roleDelete,
    MemberRoleUpdate? memberRoleUpdate,
    ForceUpdate? forceUpdate,
    FeatureFlagsUpdate? featureFlagsUpdate,
    RelationshipAdd? relationshipAdd,
    RelationshipRemove? relationshipRemove,
    DmChannelCreate? dmChannelCreate,
    MessageSendError? messageSendError,
    UpdateAvailable? updateAvailable,
    WsError? wsError,
    MessagePin? messagePin,
    MessageUnpin? messageUnpin,
    MemberJoin? memberJoin,
    UserProfileUpdate? userProfileUpdate,
    ServerUpdate? serverUpdate,
    ServerEmojisUpdate? serverEmojisUpdate,
    DmNameColorUpdate? dmNameColorUpdate,
    Ping? ping,
    Pong? pong,
    AnnouncementCreate? announcementCreate,
    AnnouncementUpdate? announcementUpdate,
    AnnouncementDelete? announcementDelete,
    FeedCreate? feedCreate,
    FeedUpdate? feedUpdate,
    FeedDelete? feedDelete,
    ReadyDelta? readyDelta,
    Batch? batch,
    Identify? identify,
    ClientTypingStart? clientTypingStart,
    ClientPresenceUpdate? clientPresenceUpdate,
    ClientMessageSend? clientMessageSend,
    ClientMessageEdit? clientMessageEdit,
    ClientMessageDelete? clientMessageDelete,
    ClientReactionAdd? clientReactionAdd,
    ClientReactionRemove? clientReactionRemove,
    ClientChannelAck? clientChannelAck,
    ClientVoiceState? clientVoiceState,
    ClientVoiceLeave? clientVoiceLeave,
    ClientFocusServer? clientFocusServer,
    ClientRequestMembers? clientRequestMembers,
    ChannelUnreadSignal? channelUnreadSignal,
    ChannelActivityUpdate? channelActivityUpdate,
    ClientFocusChannel? clientFocusChannel,
  }) {
    final result = create();
    if (ready != null) result.ready = ready;
    if (messageCreate != null) result.messageCreate = messageCreate;
    if (messageUpdate != null) result.messageUpdate = messageUpdate;
    if (messageDelete != null) result.messageDelete = messageDelete;
    if (typingStart != null) result.typingStart = typingStart;
    if (presenceUpdate != null) result.presenceUpdate = presenceUpdate;
    if (channelCreate != null) result.channelCreate = channelCreate;
    if (channelUpdate != null) result.channelUpdate = channelUpdate;
    if (channelDelete != null) result.channelDelete = channelDelete;
    if (memberRemove != null) result.memberRemove = memberRemove;
    if (serverDelete != null) result.serverDelete = serverDelete;
    if (voiceStateUpdate != null) result.voiceStateUpdate = voiceStateUpdate;
    if (categoryCreate != null) result.categoryCreate = categoryCreate;
    if (categoryUpdate != null) result.categoryUpdate = categoryUpdate;
    if (categoryDelete != null) result.categoryDelete = categoryDelete;
    if (reactionAdd != null) result.reactionAdd = reactionAdd;
    if (reactionRemove != null) result.reactionRemove = reactionRemove;
    if (roleCreate != null) result.roleCreate = roleCreate;
    if (roleUpdate != null) result.roleUpdate = roleUpdate;
    if (roleDelete != null) result.roleDelete = roleDelete;
    if (memberRoleUpdate != null) result.memberRoleUpdate = memberRoleUpdate;
    if (forceUpdate != null) result.forceUpdate = forceUpdate;
    if (featureFlagsUpdate != null)
      result.featureFlagsUpdate = featureFlagsUpdate;
    if (relationshipAdd != null) result.relationshipAdd = relationshipAdd;
    if (relationshipRemove != null)
      result.relationshipRemove = relationshipRemove;
    if (dmChannelCreate != null) result.dmChannelCreate = dmChannelCreate;
    if (messageSendError != null) result.messageSendError = messageSendError;
    if (updateAvailable != null) result.updateAvailable = updateAvailable;
    if (wsError != null) result.wsError = wsError;
    if (messagePin != null) result.messagePin = messagePin;
    if (messageUnpin != null) result.messageUnpin = messageUnpin;
    if (memberJoin != null) result.memberJoin = memberJoin;
    if (userProfileUpdate != null) result.userProfileUpdate = userProfileUpdate;
    if (serverUpdate != null) result.serverUpdate = serverUpdate;
    if (serverEmojisUpdate != null)
      result.serverEmojisUpdate = serverEmojisUpdate;
    if (dmNameColorUpdate != null) result.dmNameColorUpdate = dmNameColorUpdate;
    if (ping != null) result.ping = ping;
    if (pong != null) result.pong = pong;
    if (announcementCreate != null)
      result.announcementCreate = announcementCreate;
    if (announcementUpdate != null)
      result.announcementUpdate = announcementUpdate;
    if (announcementDelete != null)
      result.announcementDelete = announcementDelete;
    if (feedCreate != null) result.feedCreate = feedCreate;
    if (feedUpdate != null) result.feedUpdate = feedUpdate;
    if (feedDelete != null) result.feedDelete = feedDelete;
    if (readyDelta != null) result.readyDelta = readyDelta;
    if (batch != null) result.batch = batch;
    if (identify != null) result.identify = identify;
    if (clientTypingStart != null) result.clientTypingStart = clientTypingStart;
    if (clientPresenceUpdate != null)
      result.clientPresenceUpdate = clientPresenceUpdate;
    if (clientMessageSend != null) result.clientMessageSend = clientMessageSend;
    if (clientMessageEdit != null) result.clientMessageEdit = clientMessageEdit;
    if (clientMessageDelete != null)
      result.clientMessageDelete = clientMessageDelete;
    if (clientReactionAdd != null) result.clientReactionAdd = clientReactionAdd;
    if (clientReactionRemove != null)
      result.clientReactionRemove = clientReactionRemove;
    if (clientChannelAck != null) result.clientChannelAck = clientChannelAck;
    if (clientVoiceState != null) result.clientVoiceState = clientVoiceState;
    if (clientVoiceLeave != null) result.clientVoiceLeave = clientVoiceLeave;
    if (clientFocusServer != null) result.clientFocusServer = clientFocusServer;
    if (clientRequestMembers != null)
      result.clientRequestMembers = clientRequestMembers;
    if (channelUnreadSignal != null)
      result.channelUnreadSignal = channelUnreadSignal;
    if (channelActivityUpdate != null)
      result.channelActivityUpdate = channelActivityUpdate;
    if (clientFocusChannel != null)
      result.clientFocusChannel = clientFocusChannel;
    return result;
  }

  WsMessage._();

  factory WsMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WsMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, WsMessage_Payload> _WsMessage_PayloadByTag =
      {
    1: WsMessage_Payload.ready,
    2: WsMessage_Payload.messageCreate,
    3: WsMessage_Payload.messageUpdate,
    4: WsMessage_Payload.messageDelete,
    5: WsMessage_Payload.typingStart,
    6: WsMessage_Payload.presenceUpdate,
    7: WsMessage_Payload.channelCreate,
    8: WsMessage_Payload.channelUpdate,
    9: WsMessage_Payload.channelDelete,
    10: WsMessage_Payload.memberRemove,
    11: WsMessage_Payload.serverDelete,
    12: WsMessage_Payload.voiceStateUpdate,
    13: WsMessage_Payload.categoryCreate,
    14: WsMessage_Payload.categoryUpdate,
    15: WsMessage_Payload.categoryDelete,
    16: WsMessage_Payload.reactionAdd,
    17: WsMessage_Payload.reactionRemove,
    18: WsMessage_Payload.roleCreate,
    19: WsMessage_Payload.roleUpdate,
    20: WsMessage_Payload.roleDelete,
    21: WsMessage_Payload.memberRoleUpdate,
    22: WsMessage_Payload.forceUpdate,
    23: WsMessage_Payload.featureFlagsUpdate,
    24: WsMessage_Payload.relationshipAdd,
    25: WsMessage_Payload.relationshipRemove,
    26: WsMessage_Payload.dmChannelCreate,
    27: WsMessage_Payload.messageSendError,
    28: WsMessage_Payload.updateAvailable,
    29: WsMessage_Payload.wsError,
    30: WsMessage_Payload.messagePin,
    31: WsMessage_Payload.messageUnpin,
    32: WsMessage_Payload.memberJoin,
    33: WsMessage_Payload.userProfileUpdate,
    34: WsMessage_Payload.serverUpdate,
    35: WsMessage_Payload.serverEmojisUpdate,
    36: WsMessage_Payload.dmNameColorUpdate,
    40: WsMessage_Payload.ping,
    41: WsMessage_Payload.pong,
    42: WsMessage_Payload.announcementCreate,
    43: WsMessage_Payload.announcementUpdate,
    44: WsMessage_Payload.announcementDelete,
    45: WsMessage_Payload.feedCreate,
    46: WsMessage_Payload.feedUpdate,
    47: WsMessage_Payload.feedDelete,
    48: WsMessage_Payload.readyDelta,
    49: WsMessage_Payload.batch,
    50: WsMessage_Payload.identify,
    51: WsMessage_Payload.clientTypingStart,
    52: WsMessage_Payload.clientPresenceUpdate,
    53: WsMessage_Payload.clientMessageSend,
    54: WsMessage_Payload.clientMessageEdit,
    55: WsMessage_Payload.clientMessageDelete,
    56: WsMessage_Payload.clientReactionAdd,
    57: WsMessage_Payload.clientReactionRemove,
    58: WsMessage_Payload.clientChannelAck,
    59: WsMessage_Payload.clientVoiceState,
    60: WsMessage_Payload.clientVoiceLeave,
    61: WsMessage_Payload.clientFocusServer,
    62: WsMessage_Payload.clientRequestMembers,
    63: WsMessage_Payload.channelUnreadSignal,
    64: WsMessage_Payload.channelActivityUpdate,
    65: WsMessage_Payload.clientFocusChannel,
    0: WsMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WsMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..oo(0, [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      53,
      54,
      55,
      56,
      57,
      58,
      59,
      60,
      61,
      62,
      63,
      64,
      65
    ])
    ..aOM<Ready>(1, _omitFieldNames ? '' : 'ready', subBuilder: Ready.create)
    ..aOM<MessageCreate>(2, _omitFieldNames ? '' : 'messageCreate',
        subBuilder: MessageCreate.create)
    ..aOM<MessageUpdate>(3, _omitFieldNames ? '' : 'messageUpdate',
        subBuilder: MessageUpdate.create)
    ..aOM<MessageDelete>(4, _omitFieldNames ? '' : 'messageDelete',
        subBuilder: MessageDelete.create)
    ..aOM<TypingStart>(5, _omitFieldNames ? '' : 'typingStart',
        subBuilder: TypingStart.create)
    ..aOM<PresenceUpdate>(6, _omitFieldNames ? '' : 'presenceUpdate',
        subBuilder: PresenceUpdate.create)
    ..aOM<ChannelCreate>(7, _omitFieldNames ? '' : 'channelCreate',
        subBuilder: ChannelCreate.create)
    ..aOM<ChannelUpdate>(8, _omitFieldNames ? '' : 'channelUpdate',
        subBuilder: ChannelUpdate.create)
    ..aOM<ChannelDelete>(9, _omitFieldNames ? '' : 'channelDelete',
        subBuilder: ChannelDelete.create)
    ..aOM<MemberRemove>(10, _omitFieldNames ? '' : 'memberRemove',
        subBuilder: MemberRemove.create)
    ..aOM<ServerDelete>(11, _omitFieldNames ? '' : 'serverDelete',
        subBuilder: ServerDelete.create)
    ..aOM<VoiceStateUpdate>(12, _omitFieldNames ? '' : 'voiceStateUpdate',
        subBuilder: VoiceStateUpdate.create)
    ..aOM<CategoryCreate>(13, _omitFieldNames ? '' : 'categoryCreate',
        subBuilder: CategoryCreate.create)
    ..aOM<CategoryUpdate>(14, _omitFieldNames ? '' : 'categoryUpdate',
        subBuilder: CategoryUpdate.create)
    ..aOM<CategoryDelete>(15, _omitFieldNames ? '' : 'categoryDelete',
        subBuilder: CategoryDelete.create)
    ..aOM<ReactionAdd>(16, _omitFieldNames ? '' : 'reactionAdd',
        subBuilder: ReactionAdd.create)
    ..aOM<ReactionRemove>(17, _omitFieldNames ? '' : 'reactionRemove',
        subBuilder: ReactionRemove.create)
    ..aOM<RoleCreate>(18, _omitFieldNames ? '' : 'roleCreate',
        subBuilder: RoleCreate.create)
    ..aOM<RoleUpdate>(19, _omitFieldNames ? '' : 'roleUpdate',
        subBuilder: RoleUpdate.create)
    ..aOM<RoleDelete>(20, _omitFieldNames ? '' : 'roleDelete',
        subBuilder: RoleDelete.create)
    ..aOM<MemberRoleUpdate>(21, _omitFieldNames ? '' : 'memberRoleUpdate',
        subBuilder: MemberRoleUpdate.create)
    ..aOM<ForceUpdate>(22, _omitFieldNames ? '' : 'forceUpdate',
        subBuilder: ForceUpdate.create)
    ..aOM<FeatureFlagsUpdate>(23, _omitFieldNames ? '' : 'featureFlagsUpdate',
        subBuilder: FeatureFlagsUpdate.create)
    ..aOM<RelationshipAdd>(24, _omitFieldNames ? '' : 'relationshipAdd',
        subBuilder: RelationshipAdd.create)
    ..aOM<RelationshipRemove>(25, _omitFieldNames ? '' : 'relationshipRemove',
        subBuilder: RelationshipRemove.create)
    ..aOM<DmChannelCreate>(26, _omitFieldNames ? '' : 'dmChannelCreate',
        subBuilder: DmChannelCreate.create)
    ..aOM<MessageSendError>(27, _omitFieldNames ? '' : 'messageSendError',
        subBuilder: MessageSendError.create)
    ..aOM<UpdateAvailable>(28, _omitFieldNames ? '' : 'updateAvailable',
        subBuilder: UpdateAvailable.create)
    ..aOM<WsError>(29, _omitFieldNames ? '' : 'wsError',
        subBuilder: WsError.create)
    ..aOM<MessagePin>(30, _omitFieldNames ? '' : 'messagePin',
        subBuilder: MessagePin.create)
    ..aOM<MessageUnpin>(31, _omitFieldNames ? '' : 'messageUnpin',
        subBuilder: MessageUnpin.create)
    ..aOM<MemberJoin>(32, _omitFieldNames ? '' : 'memberJoin',
        subBuilder: MemberJoin.create)
    ..aOM<UserProfileUpdate>(33, _omitFieldNames ? '' : 'userProfileUpdate',
        subBuilder: UserProfileUpdate.create)
    ..aOM<ServerUpdate>(34, _omitFieldNames ? '' : 'serverUpdate',
        subBuilder: ServerUpdate.create)
    ..aOM<ServerEmojisUpdate>(35, _omitFieldNames ? '' : 'serverEmojisUpdate',
        subBuilder: ServerEmojisUpdate.create)
    ..aOM<DmNameColorUpdate>(36, _omitFieldNames ? '' : 'dmNameColorUpdate',
        subBuilder: DmNameColorUpdate.create)
    ..aOM<Ping>(40, _omitFieldNames ? '' : 'ping', subBuilder: Ping.create)
    ..aOM<Pong>(41, _omitFieldNames ? '' : 'pong', subBuilder: Pong.create)
    ..aOM<AnnouncementCreate>(42, _omitFieldNames ? '' : 'announcementCreate',
        subBuilder: AnnouncementCreate.create)
    ..aOM<AnnouncementUpdate>(43, _omitFieldNames ? '' : 'announcementUpdate',
        subBuilder: AnnouncementUpdate.create)
    ..aOM<AnnouncementDelete>(44, _omitFieldNames ? '' : 'announcementDelete',
        subBuilder: AnnouncementDelete.create)
    ..aOM<FeedCreate>(45, _omitFieldNames ? '' : 'feedCreate',
        subBuilder: FeedCreate.create)
    ..aOM<FeedUpdate>(46, _omitFieldNames ? '' : 'feedUpdate',
        subBuilder: FeedUpdate.create)
    ..aOM<FeedDelete>(47, _omitFieldNames ? '' : 'feedDelete',
        subBuilder: FeedDelete.create)
    ..aOM<ReadyDelta>(48, _omitFieldNames ? '' : 'readyDelta',
        subBuilder: ReadyDelta.create)
    ..aOM<Batch>(49, _omitFieldNames ? '' : 'batch', subBuilder: Batch.create)
    ..aOM<Identify>(50, _omitFieldNames ? '' : 'identify',
        subBuilder: Identify.create)
    ..aOM<ClientTypingStart>(51, _omitFieldNames ? '' : 'clientTypingStart',
        subBuilder: ClientTypingStart.create)
    ..aOM<ClientPresenceUpdate>(
        52, _omitFieldNames ? '' : 'clientPresenceUpdate',
        subBuilder: ClientPresenceUpdate.create)
    ..aOM<ClientMessageSend>(53, _omitFieldNames ? '' : 'clientMessageSend',
        subBuilder: ClientMessageSend.create)
    ..aOM<ClientMessageEdit>(54, _omitFieldNames ? '' : 'clientMessageEdit',
        subBuilder: ClientMessageEdit.create)
    ..aOM<ClientMessageDelete>(55, _omitFieldNames ? '' : 'clientMessageDelete',
        subBuilder: ClientMessageDelete.create)
    ..aOM<ClientReactionAdd>(56, _omitFieldNames ? '' : 'clientReactionAdd',
        subBuilder: ClientReactionAdd.create)
    ..aOM<ClientReactionRemove>(
        57, _omitFieldNames ? '' : 'clientReactionRemove',
        subBuilder: ClientReactionRemove.create)
    ..aOM<ClientChannelAck>(58, _omitFieldNames ? '' : 'clientChannelAck',
        subBuilder: ClientChannelAck.create)
    ..aOM<ClientVoiceState>(59, _omitFieldNames ? '' : 'clientVoiceState',
        subBuilder: ClientVoiceState.create)
    ..aOM<ClientVoiceLeave>(60, _omitFieldNames ? '' : 'clientVoiceLeave',
        subBuilder: ClientVoiceLeave.create)
    ..aOM<ClientFocusServer>(61, _omitFieldNames ? '' : 'clientFocusServer',
        subBuilder: ClientFocusServer.create)
    ..aOM<ClientRequestMembers>(
        62, _omitFieldNames ? '' : 'clientRequestMembers',
        subBuilder: ClientRequestMembers.create)
    ..aOM<ChannelUnreadSignal>(63, _omitFieldNames ? '' : 'channelUnreadSignal',
        subBuilder: ChannelUnreadSignal.create)
    ..aOM<ChannelActivityUpdate>(
        64, _omitFieldNames ? '' : 'channelActivityUpdate',
        subBuilder: ChannelActivityUpdate.create)
    ..aOM<ClientFocusChannel>(65, _omitFieldNames ? '' : 'clientFocusChannel',
        subBuilder: ClientFocusChannel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsMessage copyWith(void Function(WsMessage) updates) =>
      super.copyWith((message) => updates(message as WsMessage)) as WsMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WsMessage create() => WsMessage._();
  @$core.override
  WsMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WsMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WsMessage>(create);
  static WsMessage? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  @$pb.TagNumber(35)
  @$pb.TagNumber(36)
  @$pb.TagNumber(40)
  @$pb.TagNumber(41)
  @$pb.TagNumber(42)
  @$pb.TagNumber(43)
  @$pb.TagNumber(44)
  @$pb.TagNumber(45)
  @$pb.TagNumber(46)
  @$pb.TagNumber(47)
  @$pb.TagNumber(48)
  @$pb.TagNumber(49)
  @$pb.TagNumber(50)
  @$pb.TagNumber(51)
  @$pb.TagNumber(52)
  @$pb.TagNumber(53)
  @$pb.TagNumber(54)
  @$pb.TagNumber(55)
  @$pb.TagNumber(56)
  @$pb.TagNumber(57)
  @$pb.TagNumber(58)
  @$pb.TagNumber(59)
  @$pb.TagNumber(60)
  @$pb.TagNumber(61)
  @$pb.TagNumber(62)
  @$pb.TagNumber(63)
  @$pb.TagNumber(64)
  @$pb.TagNumber(65)
  WsMessage_Payload whichPayload() => _WsMessage_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  @$pb.TagNumber(35)
  @$pb.TagNumber(36)
  @$pb.TagNumber(40)
  @$pb.TagNumber(41)
  @$pb.TagNumber(42)
  @$pb.TagNumber(43)
  @$pb.TagNumber(44)
  @$pb.TagNumber(45)
  @$pb.TagNumber(46)
  @$pb.TagNumber(47)
  @$pb.TagNumber(48)
  @$pb.TagNumber(49)
  @$pb.TagNumber(50)
  @$pb.TagNumber(51)
  @$pb.TagNumber(52)
  @$pb.TagNumber(53)
  @$pb.TagNumber(54)
  @$pb.TagNumber(55)
  @$pb.TagNumber(56)
  @$pb.TagNumber(57)
  @$pb.TagNumber(58)
  @$pb.TagNumber(59)
  @$pb.TagNumber(60)
  @$pb.TagNumber(61)
  @$pb.TagNumber(62)
  @$pb.TagNumber(63)
  @$pb.TagNumber(64)
  @$pb.TagNumber(65)
  void clearPayload() => $_clearField($_whichOneof(0));

  /// ─── Server → Client (1–30) ───────────────────────────────────
  @$pb.TagNumber(1)
  Ready get ready => $_getN(0);
  @$pb.TagNumber(1)
  set ready(Ready value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReady() => $_has(0);
  @$pb.TagNumber(1)
  void clearReady() => $_clearField(1);
  @$pb.TagNumber(1)
  Ready ensureReady() => $_ensure(0);

  @$pb.TagNumber(2)
  MessageCreate get messageCreate => $_getN(1);
  @$pb.TagNumber(2)
  set messageCreate(MessageCreate value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageCreate() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageCreate() => $_clearField(2);
  @$pb.TagNumber(2)
  MessageCreate ensureMessageCreate() => $_ensure(1);

  @$pb.TagNumber(3)
  MessageUpdate get messageUpdate => $_getN(2);
  @$pb.TagNumber(3)
  set messageUpdate(MessageUpdate value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMessageUpdate() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessageUpdate() => $_clearField(3);
  @$pb.TagNumber(3)
  MessageUpdate ensureMessageUpdate() => $_ensure(2);

  @$pb.TagNumber(4)
  MessageDelete get messageDelete => $_getN(3);
  @$pb.TagNumber(4)
  set messageDelete(MessageDelete value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMessageDelete() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessageDelete() => $_clearField(4);
  @$pb.TagNumber(4)
  MessageDelete ensureMessageDelete() => $_ensure(3);

  @$pb.TagNumber(5)
  TypingStart get typingStart => $_getN(4);
  @$pb.TagNumber(5)
  set typingStart(TypingStart value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTypingStart() => $_has(4);
  @$pb.TagNumber(5)
  void clearTypingStart() => $_clearField(5);
  @$pb.TagNumber(5)
  TypingStart ensureTypingStart() => $_ensure(4);

  @$pb.TagNumber(6)
  PresenceUpdate get presenceUpdate => $_getN(5);
  @$pb.TagNumber(6)
  set presenceUpdate(PresenceUpdate value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPresenceUpdate() => $_has(5);
  @$pb.TagNumber(6)
  void clearPresenceUpdate() => $_clearField(6);
  @$pb.TagNumber(6)
  PresenceUpdate ensurePresenceUpdate() => $_ensure(5);

  @$pb.TagNumber(7)
  ChannelCreate get channelCreate => $_getN(6);
  @$pb.TagNumber(7)
  set channelCreate(ChannelCreate value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasChannelCreate() => $_has(6);
  @$pb.TagNumber(7)
  void clearChannelCreate() => $_clearField(7);
  @$pb.TagNumber(7)
  ChannelCreate ensureChannelCreate() => $_ensure(6);

  @$pb.TagNumber(8)
  ChannelUpdate get channelUpdate => $_getN(7);
  @$pb.TagNumber(8)
  set channelUpdate(ChannelUpdate value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasChannelUpdate() => $_has(7);
  @$pb.TagNumber(8)
  void clearChannelUpdate() => $_clearField(8);
  @$pb.TagNumber(8)
  ChannelUpdate ensureChannelUpdate() => $_ensure(7);

  @$pb.TagNumber(9)
  ChannelDelete get channelDelete => $_getN(8);
  @$pb.TagNumber(9)
  set channelDelete(ChannelDelete value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasChannelDelete() => $_has(8);
  @$pb.TagNumber(9)
  void clearChannelDelete() => $_clearField(9);
  @$pb.TagNumber(9)
  ChannelDelete ensureChannelDelete() => $_ensure(8);

  @$pb.TagNumber(10)
  MemberRemove get memberRemove => $_getN(9);
  @$pb.TagNumber(10)
  set memberRemove(MemberRemove value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMemberRemove() => $_has(9);
  @$pb.TagNumber(10)
  void clearMemberRemove() => $_clearField(10);
  @$pb.TagNumber(10)
  MemberRemove ensureMemberRemove() => $_ensure(9);

  @$pb.TagNumber(11)
  ServerDelete get serverDelete => $_getN(10);
  @$pb.TagNumber(11)
  set serverDelete(ServerDelete value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasServerDelete() => $_has(10);
  @$pb.TagNumber(11)
  void clearServerDelete() => $_clearField(11);
  @$pb.TagNumber(11)
  ServerDelete ensureServerDelete() => $_ensure(10);

  @$pb.TagNumber(12)
  VoiceStateUpdate get voiceStateUpdate => $_getN(11);
  @$pb.TagNumber(12)
  set voiceStateUpdate(VoiceStateUpdate value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasVoiceStateUpdate() => $_has(11);
  @$pb.TagNumber(12)
  void clearVoiceStateUpdate() => $_clearField(12);
  @$pb.TagNumber(12)
  VoiceStateUpdate ensureVoiceStateUpdate() => $_ensure(11);

  @$pb.TagNumber(13)
  CategoryCreate get categoryCreate => $_getN(12);
  @$pb.TagNumber(13)
  set categoryCreate(CategoryCreate value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasCategoryCreate() => $_has(12);
  @$pb.TagNumber(13)
  void clearCategoryCreate() => $_clearField(13);
  @$pb.TagNumber(13)
  CategoryCreate ensureCategoryCreate() => $_ensure(12);

  @$pb.TagNumber(14)
  CategoryUpdate get categoryUpdate => $_getN(13);
  @$pb.TagNumber(14)
  set categoryUpdate(CategoryUpdate value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasCategoryUpdate() => $_has(13);
  @$pb.TagNumber(14)
  void clearCategoryUpdate() => $_clearField(14);
  @$pb.TagNumber(14)
  CategoryUpdate ensureCategoryUpdate() => $_ensure(13);

  @$pb.TagNumber(15)
  CategoryDelete get categoryDelete => $_getN(14);
  @$pb.TagNumber(15)
  set categoryDelete(CategoryDelete value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasCategoryDelete() => $_has(14);
  @$pb.TagNumber(15)
  void clearCategoryDelete() => $_clearField(15);
  @$pb.TagNumber(15)
  CategoryDelete ensureCategoryDelete() => $_ensure(14);

  @$pb.TagNumber(16)
  ReactionAdd get reactionAdd => $_getN(15);
  @$pb.TagNumber(16)
  set reactionAdd(ReactionAdd value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasReactionAdd() => $_has(15);
  @$pb.TagNumber(16)
  void clearReactionAdd() => $_clearField(16);
  @$pb.TagNumber(16)
  ReactionAdd ensureReactionAdd() => $_ensure(15);

  @$pb.TagNumber(17)
  ReactionRemove get reactionRemove => $_getN(16);
  @$pb.TagNumber(17)
  set reactionRemove(ReactionRemove value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasReactionRemove() => $_has(16);
  @$pb.TagNumber(17)
  void clearReactionRemove() => $_clearField(17);
  @$pb.TagNumber(17)
  ReactionRemove ensureReactionRemove() => $_ensure(16);

  @$pb.TagNumber(18)
  RoleCreate get roleCreate => $_getN(17);
  @$pb.TagNumber(18)
  set roleCreate(RoleCreate value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasRoleCreate() => $_has(17);
  @$pb.TagNumber(18)
  void clearRoleCreate() => $_clearField(18);
  @$pb.TagNumber(18)
  RoleCreate ensureRoleCreate() => $_ensure(17);

  @$pb.TagNumber(19)
  RoleUpdate get roleUpdate => $_getN(18);
  @$pb.TagNumber(19)
  set roleUpdate(RoleUpdate value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasRoleUpdate() => $_has(18);
  @$pb.TagNumber(19)
  void clearRoleUpdate() => $_clearField(19);
  @$pb.TagNumber(19)
  RoleUpdate ensureRoleUpdate() => $_ensure(18);

  @$pb.TagNumber(20)
  RoleDelete get roleDelete => $_getN(19);
  @$pb.TagNumber(20)
  set roleDelete(RoleDelete value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasRoleDelete() => $_has(19);
  @$pb.TagNumber(20)
  void clearRoleDelete() => $_clearField(20);
  @$pb.TagNumber(20)
  RoleDelete ensureRoleDelete() => $_ensure(19);

  @$pb.TagNumber(21)
  MemberRoleUpdate get memberRoleUpdate => $_getN(20);
  @$pb.TagNumber(21)
  set memberRoleUpdate(MemberRoleUpdate value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasMemberRoleUpdate() => $_has(20);
  @$pb.TagNumber(21)
  void clearMemberRoleUpdate() => $_clearField(21);
  @$pb.TagNumber(21)
  MemberRoleUpdate ensureMemberRoleUpdate() => $_ensure(20);

  @$pb.TagNumber(22)
  ForceUpdate get forceUpdate => $_getN(21);
  @$pb.TagNumber(22)
  set forceUpdate(ForceUpdate value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasForceUpdate() => $_has(21);
  @$pb.TagNumber(22)
  void clearForceUpdate() => $_clearField(22);
  @$pb.TagNumber(22)
  ForceUpdate ensureForceUpdate() => $_ensure(21);

  @$pb.TagNumber(23)
  FeatureFlagsUpdate get featureFlagsUpdate => $_getN(22);
  @$pb.TagNumber(23)
  set featureFlagsUpdate(FeatureFlagsUpdate value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasFeatureFlagsUpdate() => $_has(22);
  @$pb.TagNumber(23)
  void clearFeatureFlagsUpdate() => $_clearField(23);
  @$pb.TagNumber(23)
  FeatureFlagsUpdate ensureFeatureFlagsUpdate() => $_ensure(22);

  @$pb.TagNumber(24)
  RelationshipAdd get relationshipAdd => $_getN(23);
  @$pb.TagNumber(24)
  set relationshipAdd(RelationshipAdd value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasRelationshipAdd() => $_has(23);
  @$pb.TagNumber(24)
  void clearRelationshipAdd() => $_clearField(24);
  @$pb.TagNumber(24)
  RelationshipAdd ensureRelationshipAdd() => $_ensure(23);

  @$pb.TagNumber(25)
  RelationshipRemove get relationshipRemove => $_getN(24);
  @$pb.TagNumber(25)
  set relationshipRemove(RelationshipRemove value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasRelationshipRemove() => $_has(24);
  @$pb.TagNumber(25)
  void clearRelationshipRemove() => $_clearField(25);
  @$pb.TagNumber(25)
  RelationshipRemove ensureRelationshipRemove() => $_ensure(24);

  @$pb.TagNumber(26)
  DmChannelCreate get dmChannelCreate => $_getN(25);
  @$pb.TagNumber(26)
  set dmChannelCreate(DmChannelCreate value) => $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasDmChannelCreate() => $_has(25);
  @$pb.TagNumber(26)
  void clearDmChannelCreate() => $_clearField(26);
  @$pb.TagNumber(26)
  DmChannelCreate ensureDmChannelCreate() => $_ensure(25);

  @$pb.TagNumber(27)
  MessageSendError get messageSendError => $_getN(26);
  @$pb.TagNumber(27)
  set messageSendError(MessageSendError value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasMessageSendError() => $_has(26);
  @$pb.TagNumber(27)
  void clearMessageSendError() => $_clearField(27);
  @$pb.TagNumber(27)
  MessageSendError ensureMessageSendError() => $_ensure(26);

  @$pb.TagNumber(28)
  UpdateAvailable get updateAvailable => $_getN(27);
  @$pb.TagNumber(28)
  set updateAvailable(UpdateAvailable value) => $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasUpdateAvailable() => $_has(27);
  @$pb.TagNumber(28)
  void clearUpdateAvailable() => $_clearField(28);
  @$pb.TagNumber(28)
  UpdateAvailable ensureUpdateAvailable() => $_ensure(27);

  @$pb.TagNumber(29)
  WsError get wsError => $_getN(28);
  @$pb.TagNumber(29)
  set wsError(WsError value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasWsError() => $_has(28);
  @$pb.TagNumber(29)
  void clearWsError() => $_clearField(29);
  @$pb.TagNumber(29)
  WsError ensureWsError() => $_ensure(28);

  @$pb.TagNumber(30)
  MessagePin get messagePin => $_getN(29);
  @$pb.TagNumber(30)
  set messagePin(MessagePin value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasMessagePin() => $_has(29);
  @$pb.TagNumber(30)
  void clearMessagePin() => $_clearField(30);
  @$pb.TagNumber(30)
  MessagePin ensureMessagePin() => $_ensure(29);

  @$pb.TagNumber(31)
  MessageUnpin get messageUnpin => $_getN(30);
  @$pb.TagNumber(31)
  set messageUnpin(MessageUnpin value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasMessageUnpin() => $_has(30);
  @$pb.TagNumber(31)
  void clearMessageUnpin() => $_clearField(31);
  @$pb.TagNumber(31)
  MessageUnpin ensureMessageUnpin() => $_ensure(30);

  @$pb.TagNumber(32)
  MemberJoin get memberJoin => $_getN(31);
  @$pb.TagNumber(32)
  set memberJoin(MemberJoin value) => $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasMemberJoin() => $_has(31);
  @$pb.TagNumber(32)
  void clearMemberJoin() => $_clearField(32);
  @$pb.TagNumber(32)
  MemberJoin ensureMemberJoin() => $_ensure(31);

  @$pb.TagNumber(33)
  UserProfileUpdate get userProfileUpdate => $_getN(32);
  @$pb.TagNumber(33)
  set userProfileUpdate(UserProfileUpdate value) => $_setField(33, value);
  @$pb.TagNumber(33)
  $core.bool hasUserProfileUpdate() => $_has(32);
  @$pb.TagNumber(33)
  void clearUserProfileUpdate() => $_clearField(33);
  @$pb.TagNumber(33)
  UserProfileUpdate ensureUserProfileUpdate() => $_ensure(32);

  @$pb.TagNumber(34)
  ServerUpdate get serverUpdate => $_getN(33);
  @$pb.TagNumber(34)
  set serverUpdate(ServerUpdate value) => $_setField(34, value);
  @$pb.TagNumber(34)
  $core.bool hasServerUpdate() => $_has(33);
  @$pb.TagNumber(34)
  void clearServerUpdate() => $_clearField(34);
  @$pb.TagNumber(34)
  ServerUpdate ensureServerUpdate() => $_ensure(33);

  @$pb.TagNumber(35)
  ServerEmojisUpdate get serverEmojisUpdate => $_getN(34);
  @$pb.TagNumber(35)
  set serverEmojisUpdate(ServerEmojisUpdate value) => $_setField(35, value);
  @$pb.TagNumber(35)
  $core.bool hasServerEmojisUpdate() => $_has(34);
  @$pb.TagNumber(35)
  void clearServerEmojisUpdate() => $_clearField(35);
  @$pb.TagNumber(35)
  ServerEmojisUpdate ensureServerEmojisUpdate() => $_ensure(34);

  @$pb.TagNumber(36)
  DmNameColorUpdate get dmNameColorUpdate => $_getN(35);
  @$pb.TagNumber(36)
  set dmNameColorUpdate(DmNameColorUpdate value) => $_setField(36, value);
  @$pb.TagNumber(36)
  $core.bool hasDmNameColorUpdate() => $_has(35);
  @$pb.TagNumber(36)
  void clearDmNameColorUpdate() => $_clearField(36);
  @$pb.TagNumber(36)
  DmNameColorUpdate ensureDmNameColorUpdate() => $_ensure(35);

  /// ─── Bidirectional (37–38) ─────────────────────────────────────
  @$pb.TagNumber(40)
  Ping get ping => $_getN(36);
  @$pb.TagNumber(40)
  set ping(Ping value) => $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasPing() => $_has(36);
  @$pb.TagNumber(40)
  void clearPing() => $_clearField(40);
  @$pb.TagNumber(40)
  Ping ensurePing() => $_ensure(36);

  @$pb.TagNumber(41)
  Pong get pong => $_getN(37);
  @$pb.TagNumber(41)
  set pong(Pong value) => $_setField(41, value);
  @$pb.TagNumber(41)
  $core.bool hasPong() => $_has(37);
  @$pb.TagNumber(41)
  void clearPong() => $_clearField(41);
  @$pb.TagNumber(41)
  Pong ensurePong() => $_ensure(37);

  @$pb.TagNumber(42)
  AnnouncementCreate get announcementCreate => $_getN(38);
  @$pb.TagNumber(42)
  set announcementCreate(AnnouncementCreate value) => $_setField(42, value);
  @$pb.TagNumber(42)
  $core.bool hasAnnouncementCreate() => $_has(38);
  @$pb.TagNumber(42)
  void clearAnnouncementCreate() => $_clearField(42);
  @$pb.TagNumber(42)
  AnnouncementCreate ensureAnnouncementCreate() => $_ensure(38);

  @$pb.TagNumber(43)
  AnnouncementUpdate get announcementUpdate => $_getN(39);
  @$pb.TagNumber(43)
  set announcementUpdate(AnnouncementUpdate value) => $_setField(43, value);
  @$pb.TagNumber(43)
  $core.bool hasAnnouncementUpdate() => $_has(39);
  @$pb.TagNumber(43)
  void clearAnnouncementUpdate() => $_clearField(43);
  @$pb.TagNumber(43)
  AnnouncementUpdate ensureAnnouncementUpdate() => $_ensure(39);

  @$pb.TagNumber(44)
  AnnouncementDelete get announcementDelete => $_getN(40);
  @$pb.TagNumber(44)
  set announcementDelete(AnnouncementDelete value) => $_setField(44, value);
  @$pb.TagNumber(44)
  $core.bool hasAnnouncementDelete() => $_has(40);
  @$pb.TagNumber(44)
  void clearAnnouncementDelete() => $_clearField(44);
  @$pb.TagNumber(44)
  AnnouncementDelete ensureAnnouncementDelete() => $_ensure(40);

  @$pb.TagNumber(45)
  FeedCreate get feedCreate => $_getN(41);
  @$pb.TagNumber(45)
  set feedCreate(FeedCreate value) => $_setField(45, value);
  @$pb.TagNumber(45)
  $core.bool hasFeedCreate() => $_has(41);
  @$pb.TagNumber(45)
  void clearFeedCreate() => $_clearField(45);
  @$pb.TagNumber(45)
  FeedCreate ensureFeedCreate() => $_ensure(41);

  @$pb.TagNumber(46)
  FeedUpdate get feedUpdate => $_getN(42);
  @$pb.TagNumber(46)
  set feedUpdate(FeedUpdate value) => $_setField(46, value);
  @$pb.TagNumber(46)
  $core.bool hasFeedUpdate() => $_has(42);
  @$pb.TagNumber(46)
  void clearFeedUpdate() => $_clearField(46);
  @$pb.TagNumber(46)
  FeedUpdate ensureFeedUpdate() => $_ensure(42);

  @$pb.TagNumber(47)
  FeedDelete get feedDelete => $_getN(43);
  @$pb.TagNumber(47)
  set feedDelete(FeedDelete value) => $_setField(47, value);
  @$pb.TagNumber(47)
  $core.bool hasFeedDelete() => $_has(43);
  @$pb.TagNumber(47)
  void clearFeedDelete() => $_clearField(47);
  @$pb.TagNumber(47)
  FeedDelete ensureFeedDelete() => $_ensure(43);

  @$pb.TagNumber(48)
  ReadyDelta get readyDelta => $_getN(44);
  @$pb.TagNumber(48)
  set readyDelta(ReadyDelta value) => $_setField(48, value);
  @$pb.TagNumber(48)
  $core.bool hasReadyDelta() => $_has(44);
  @$pb.TagNumber(48)
  void clearReadyDelta() => $_clearField(48);
  @$pb.TagNumber(48)
  ReadyDelta ensureReadyDelta() => $_ensure(44);

  @$pb.TagNumber(49)
  Batch get batch => $_getN(45);
  @$pb.TagNumber(49)
  set batch(Batch value) => $_setField(49, value);
  @$pb.TagNumber(49)
  $core.bool hasBatch() => $_has(45);
  @$pb.TagNumber(49)
  void clearBatch() => $_clearField(49);
  @$pb.TagNumber(49)
  Batch ensureBatch() => $_ensure(45);

  /// ─── Client → Server (50–65) ──────────────────────────────────
  @$pb.TagNumber(50)
  Identify get identify => $_getN(46);
  @$pb.TagNumber(50)
  set identify(Identify value) => $_setField(50, value);
  @$pb.TagNumber(50)
  $core.bool hasIdentify() => $_has(46);
  @$pb.TagNumber(50)
  void clearIdentify() => $_clearField(50);
  @$pb.TagNumber(50)
  Identify ensureIdentify() => $_ensure(46);

  @$pb.TagNumber(51)
  ClientTypingStart get clientTypingStart => $_getN(47);
  @$pb.TagNumber(51)
  set clientTypingStart(ClientTypingStart value) => $_setField(51, value);
  @$pb.TagNumber(51)
  $core.bool hasClientTypingStart() => $_has(47);
  @$pb.TagNumber(51)
  void clearClientTypingStart() => $_clearField(51);
  @$pb.TagNumber(51)
  ClientTypingStart ensureClientTypingStart() => $_ensure(47);

  @$pb.TagNumber(52)
  ClientPresenceUpdate get clientPresenceUpdate => $_getN(48);
  @$pb.TagNumber(52)
  set clientPresenceUpdate(ClientPresenceUpdate value) => $_setField(52, value);
  @$pb.TagNumber(52)
  $core.bool hasClientPresenceUpdate() => $_has(48);
  @$pb.TagNumber(52)
  void clearClientPresenceUpdate() => $_clearField(52);
  @$pb.TagNumber(52)
  ClientPresenceUpdate ensureClientPresenceUpdate() => $_ensure(48);

  @$pb.TagNumber(53)
  ClientMessageSend get clientMessageSend => $_getN(49);
  @$pb.TagNumber(53)
  set clientMessageSend(ClientMessageSend value) => $_setField(53, value);
  @$pb.TagNumber(53)
  $core.bool hasClientMessageSend() => $_has(49);
  @$pb.TagNumber(53)
  void clearClientMessageSend() => $_clearField(53);
  @$pb.TagNumber(53)
  ClientMessageSend ensureClientMessageSend() => $_ensure(49);

  @$pb.TagNumber(54)
  ClientMessageEdit get clientMessageEdit => $_getN(50);
  @$pb.TagNumber(54)
  set clientMessageEdit(ClientMessageEdit value) => $_setField(54, value);
  @$pb.TagNumber(54)
  $core.bool hasClientMessageEdit() => $_has(50);
  @$pb.TagNumber(54)
  void clearClientMessageEdit() => $_clearField(54);
  @$pb.TagNumber(54)
  ClientMessageEdit ensureClientMessageEdit() => $_ensure(50);

  @$pb.TagNumber(55)
  ClientMessageDelete get clientMessageDelete => $_getN(51);
  @$pb.TagNumber(55)
  set clientMessageDelete(ClientMessageDelete value) => $_setField(55, value);
  @$pb.TagNumber(55)
  $core.bool hasClientMessageDelete() => $_has(51);
  @$pb.TagNumber(55)
  void clearClientMessageDelete() => $_clearField(55);
  @$pb.TagNumber(55)
  ClientMessageDelete ensureClientMessageDelete() => $_ensure(51);

  @$pb.TagNumber(56)
  ClientReactionAdd get clientReactionAdd => $_getN(52);
  @$pb.TagNumber(56)
  set clientReactionAdd(ClientReactionAdd value) => $_setField(56, value);
  @$pb.TagNumber(56)
  $core.bool hasClientReactionAdd() => $_has(52);
  @$pb.TagNumber(56)
  void clearClientReactionAdd() => $_clearField(56);
  @$pb.TagNumber(56)
  ClientReactionAdd ensureClientReactionAdd() => $_ensure(52);

  @$pb.TagNumber(57)
  ClientReactionRemove get clientReactionRemove => $_getN(53);
  @$pb.TagNumber(57)
  set clientReactionRemove(ClientReactionRemove value) => $_setField(57, value);
  @$pb.TagNumber(57)
  $core.bool hasClientReactionRemove() => $_has(53);
  @$pb.TagNumber(57)
  void clearClientReactionRemove() => $_clearField(57);
  @$pb.TagNumber(57)
  ClientReactionRemove ensureClientReactionRemove() => $_ensure(53);

  @$pb.TagNumber(58)
  ClientChannelAck get clientChannelAck => $_getN(54);
  @$pb.TagNumber(58)
  set clientChannelAck(ClientChannelAck value) => $_setField(58, value);
  @$pb.TagNumber(58)
  $core.bool hasClientChannelAck() => $_has(54);
  @$pb.TagNumber(58)
  void clearClientChannelAck() => $_clearField(58);
  @$pb.TagNumber(58)
  ClientChannelAck ensureClientChannelAck() => $_ensure(54);

  @$pb.TagNumber(59)
  ClientVoiceState get clientVoiceState => $_getN(55);
  @$pb.TagNumber(59)
  set clientVoiceState(ClientVoiceState value) => $_setField(59, value);
  @$pb.TagNumber(59)
  $core.bool hasClientVoiceState() => $_has(55);
  @$pb.TagNumber(59)
  void clearClientVoiceState() => $_clearField(59);
  @$pb.TagNumber(59)
  ClientVoiceState ensureClientVoiceState() => $_ensure(55);

  @$pb.TagNumber(60)
  ClientVoiceLeave get clientVoiceLeave => $_getN(56);
  @$pb.TagNumber(60)
  set clientVoiceLeave(ClientVoiceLeave value) => $_setField(60, value);
  @$pb.TagNumber(60)
  $core.bool hasClientVoiceLeave() => $_has(56);
  @$pb.TagNumber(60)
  void clearClientVoiceLeave() => $_clearField(60);
  @$pb.TagNumber(60)
  ClientVoiceLeave ensureClientVoiceLeave() => $_ensure(56);

  @$pb.TagNumber(61)
  ClientFocusServer get clientFocusServer => $_getN(57);
  @$pb.TagNumber(61)
  set clientFocusServer(ClientFocusServer value) => $_setField(61, value);
  @$pb.TagNumber(61)
  $core.bool hasClientFocusServer() => $_has(57);
  @$pb.TagNumber(61)
  void clearClientFocusServer() => $_clearField(61);
  @$pb.TagNumber(61)
  ClientFocusServer ensureClientFocusServer() => $_ensure(57);

  @$pb.TagNumber(62)
  ClientRequestMembers get clientRequestMembers => $_getN(58);
  @$pb.TagNumber(62)
  set clientRequestMembers(ClientRequestMembers value) => $_setField(62, value);
  @$pb.TagNumber(62)
  $core.bool hasClientRequestMembers() => $_has(58);
  @$pb.TagNumber(62)
  void clearClientRequestMembers() => $_clearField(62);
  @$pb.TagNumber(62)
  ClientRequestMembers ensureClientRequestMembers() => $_ensure(58);

  @$pb.TagNumber(63)
  ChannelUnreadSignal get channelUnreadSignal => $_getN(59);
  @$pb.TagNumber(63)
  set channelUnreadSignal(ChannelUnreadSignal value) => $_setField(63, value);
  @$pb.TagNumber(63)
  $core.bool hasChannelUnreadSignal() => $_has(59);
  @$pb.TagNumber(63)
  void clearChannelUnreadSignal() => $_clearField(63);
  @$pb.TagNumber(63)
  ChannelUnreadSignal ensureChannelUnreadSignal() => $_ensure(59);

  @$pb.TagNumber(64)
  ChannelActivityUpdate get channelActivityUpdate => $_getN(60);
  @$pb.TagNumber(64)
  set channelActivityUpdate(ChannelActivityUpdate value) =>
      $_setField(64, value);
  @$pb.TagNumber(64)
  $core.bool hasChannelActivityUpdate() => $_has(60);
  @$pb.TagNumber(64)
  void clearChannelActivityUpdate() => $_clearField(64);
  @$pb.TagNumber(64)
  ChannelActivityUpdate ensureChannelActivityUpdate() => $_ensure(60);

  @$pb.TagNumber(65)
  ClientFocusChannel get clientFocusChannel => $_getN(61);
  @$pb.TagNumber(65)
  set clientFocusChannel(ClientFocusChannel value) => $_setField(65, value);
  @$pb.TagNumber(65)
  $core.bool hasClientFocusChannel() => $_has(61);
  @$pb.TagNumber(65)
  void clearClientFocusChannel() => $_clearField(65);
  @$pb.TagNumber(65)
  ClientFocusChannel ensureClientFocusChannel() => $_ensure(61);
}

class Ready extends $pb.GeneratedMessage {
  factory Ready({
    $core.String? sessionId,
    $core.String? userId,
    $core.Iterable<$0.Server>? servers,
    $core.Iterable<$core.String>? serverOrder,
    $core.Iterable<$core.String>? favoriteOrder,
    $core.Iterable<$0.Category>? categories,
    $core.Iterable<$0.Channel>? channels,
    $core.Iterable<$0.Emoji>? emojis,
    $core.Iterable<$core.String>? dmChannelIds,
    $core.Iterable<$0.Relationship>? relationships,
    $core.Iterable<$0.DmChannel>? dmChannels,
    $core.Iterable<$0.VoiceState>? voiceStates,
    $core.Iterable<$0.ChannelReadState>? readStates,
    $core.Iterable<$0.Role>? roles,
    $core.Iterable<$core.MapEntry<$core.String, MemberRoleIds>>? memberRoleIds,
    $core.String? serverVersion,
    $core.String? minClientVersion,
    $core.Iterable<$core.MapEntry<$core.String, $core.bool>>? featureFlags,
    $core.String? username,
    $core.String? displayName,
    $core.String? avatarUrl,
    $core.String? bannerUrl,
    $core.String? userStatus,
    $core.Iterable<PresenceEntry>? presences,
    $core.String? preferencesJson,
    $core.String? subscriptionJson,
    $core.Iterable<$0.Feed>? feeds,
    $core.String? entitlementsJson,
    $core.String? instanceJson,
    $core.bool? usernameSet,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (userId != null) result.userId = userId;
    if (servers != null) result.servers.addAll(servers);
    if (serverOrder != null) result.serverOrder.addAll(serverOrder);
    if (favoriteOrder != null) result.favoriteOrder.addAll(favoriteOrder);
    if (categories != null) result.categories.addAll(categories);
    if (channels != null) result.channels.addAll(channels);
    if (emojis != null) result.emojis.addAll(emojis);
    if (dmChannelIds != null) result.dmChannelIds.addAll(dmChannelIds);
    if (relationships != null) result.relationships.addAll(relationships);
    if (dmChannels != null) result.dmChannels.addAll(dmChannels);
    if (voiceStates != null) result.voiceStates.addAll(voiceStates);
    if (readStates != null) result.readStates.addAll(readStates);
    if (roles != null) result.roles.addAll(roles);
    if (memberRoleIds != null) result.memberRoleIds.addEntries(memberRoleIds);
    if (serverVersion != null) result.serverVersion = serverVersion;
    if (minClientVersion != null) result.minClientVersion = minClientVersion;
    if (featureFlags != null) result.featureFlags.addEntries(featureFlags);
    if (username != null) result.username = username;
    if (displayName != null) result.displayName = displayName;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (bannerUrl != null) result.bannerUrl = bannerUrl;
    if (userStatus != null) result.userStatus = userStatus;
    if (presences != null) result.presences.addAll(presences);
    if (preferencesJson != null) result.preferencesJson = preferencesJson;
    if (subscriptionJson != null) result.subscriptionJson = subscriptionJson;
    if (feeds != null) result.feeds.addAll(feeds);
    if (entitlementsJson != null) result.entitlementsJson = entitlementsJson;
    if (instanceJson != null) result.instanceJson = instanceJson;
    if (usernameSet != null) result.usernameSet = usernameSet;
    return result;
  }

  Ready._();

  factory Ready.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Ready.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ready',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..pPM<$0.Server>(3, _omitFieldNames ? '' : 'servers',
        subBuilder: $0.Server.create)
    ..pPS(4, _omitFieldNames ? '' : 'serverOrder')
    ..pPS(5, _omitFieldNames ? '' : 'favoriteOrder')
    ..pPM<$0.Category>(6, _omitFieldNames ? '' : 'categories',
        subBuilder: $0.Category.create)
    ..pPM<$0.Channel>(7, _omitFieldNames ? '' : 'channels',
        subBuilder: $0.Channel.create)
    ..pPM<$0.Emoji>(8, _omitFieldNames ? '' : 'emojis',
        subBuilder: $0.Emoji.create)
    ..pPS(9, _omitFieldNames ? '' : 'dmChannelIds')
    ..pPM<$0.Relationship>(10, _omitFieldNames ? '' : 'relationships',
        subBuilder: $0.Relationship.create)
    ..pPM<$0.DmChannel>(11, _omitFieldNames ? '' : 'dmChannels',
        subBuilder: $0.DmChannel.create)
    ..pPM<$0.VoiceState>(12, _omitFieldNames ? '' : 'voiceStates',
        subBuilder: $0.VoiceState.create)
    ..pPM<$0.ChannelReadState>(13, _omitFieldNames ? '' : 'readStates',
        subBuilder: $0.ChannelReadState.create)
    ..pPM<$0.Role>(14, _omitFieldNames ? '' : 'roles',
        subBuilder: $0.Role.create)
    ..m<$core.String, MemberRoleIds>(15, _omitFieldNames ? '' : 'memberRoleIds',
        entryClassName: 'Ready.MemberRoleIdsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: MemberRoleIds.create,
        valueDefaultOrMaker: MemberRoleIds.getDefault,
        packageName: const $pb.PackageName('verdant'))
    ..aOS(16, _omitFieldNames ? '' : 'serverVersion')
    ..aOS(17, _omitFieldNames ? '' : 'minClientVersion')
    ..m<$core.String, $core.bool>(18, _omitFieldNames ? '' : 'featureFlags',
        entryClassName: 'Ready.FeatureFlagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('verdant'))
    ..aOS(19, _omitFieldNames ? '' : 'username')
    ..aOS(20, _omitFieldNames ? '' : 'displayName')
    ..aOS(21, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(22, _omitFieldNames ? '' : 'bannerUrl')
    ..aOS(23, _omitFieldNames ? '' : 'userStatus')
    ..pPM<PresenceEntry>(24, _omitFieldNames ? '' : 'presences',
        subBuilder: PresenceEntry.create)
    ..aOS(25, _omitFieldNames ? '' : 'preferencesJson')
    ..aOS(26, _omitFieldNames ? '' : 'subscriptionJson')
    ..pPM<$0.Feed>(27, _omitFieldNames ? '' : 'feeds',
        subBuilder: $0.Feed.create)
    ..aOS(28, _omitFieldNames ? '' : 'entitlementsJson')
    ..aOS(29, _omitFieldNames ? '' : 'instanceJson')
    ..aOB(30, _omitFieldNames ? '' : 'usernameSet')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ready clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ready copyWith(void Function(Ready) updates) =>
      super.copyWith((message) => updates(message as Ready)) as Ready;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Ready create() => Ready._();
  @$core.override
  Ready createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Ready getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ready>(create);
  static Ready? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$0.Server> get servers => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get serverOrder => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get favoriteOrder => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$0.Category> get categories => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$0.Channel> get channels => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<$0.Emoji> get emojis => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get dmChannelIds => $_getList(8);

  @$pb.TagNumber(10)
  $pb.PbList<$0.Relationship> get relationships => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbList<$0.DmChannel> get dmChannels => $_getList(10);

  @$pb.TagNumber(12)
  $pb.PbList<$0.VoiceState> get voiceStates => $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<$0.ChannelReadState> get readStates => $_getList(12);

  @$pb.TagNumber(14)
  $pb.PbList<$0.Role> get roles => $_getList(13);

  @$pb.TagNumber(15)
  $pb.PbMap<$core.String, MemberRoleIds> get memberRoleIds => $_getMap(14);

  @$pb.TagNumber(16)
  $core.String get serverVersion => $_getSZ(15);
  @$pb.TagNumber(16)
  set serverVersion($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasServerVersion() => $_has(15);
  @$pb.TagNumber(16)
  void clearServerVersion() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get minClientVersion => $_getSZ(16);
  @$pb.TagNumber(17)
  set minClientVersion($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasMinClientVersion() => $_has(16);
  @$pb.TagNumber(17)
  void clearMinClientVersion() => $_clearField(17);

  @$pb.TagNumber(18)
  $pb.PbMap<$core.String, $core.bool> get featureFlags => $_getMap(17);

  /// Fields 19–26: added to match JSON READY so proto READY can go binary.
  @$pb.TagNumber(19)
  $core.String get username => $_getSZ(18);
  @$pb.TagNumber(19)
  set username($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasUsername() => $_has(18);
  @$pb.TagNumber(19)
  void clearUsername() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get displayName => $_getSZ(19);
  @$pb.TagNumber(20)
  set displayName($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasDisplayName() => $_has(19);
  @$pb.TagNumber(20)
  void clearDisplayName() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get avatarUrl => $_getSZ(20);
  @$pb.TagNumber(21)
  set avatarUrl($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasAvatarUrl() => $_has(20);
  @$pb.TagNumber(21)
  void clearAvatarUrl() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get bannerUrl => $_getSZ(21);
  @$pb.TagNumber(22)
  set bannerUrl($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasBannerUrl() => $_has(21);
  @$pb.TagNumber(22)
  void clearBannerUrl() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get userStatus => $_getSZ(22);
  @$pb.TagNumber(23)
  set userStatus($core.String value) => $_setString(22, value);
  @$pb.TagNumber(23)
  $core.bool hasUserStatus() => $_has(22);
  @$pb.TagNumber(23)
  void clearUserStatus() => $_clearField(23);

  @$pb.TagNumber(24)
  $pb.PbList<PresenceEntry> get presences => $_getList(23);

  @$pb.TagNumber(25)
  $core.String get preferencesJson => $_getSZ(24);
  @$pb.TagNumber(25)
  set preferencesJson($core.String value) => $_setString(24, value);
  @$pb.TagNumber(25)
  $core.bool hasPreferencesJson() => $_has(24);
  @$pb.TagNumber(25)
  void clearPreferencesJson() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.String get subscriptionJson => $_getSZ(25);
  @$pb.TagNumber(26)
  set subscriptionJson($core.String value) => $_setString(25, value);
  @$pb.TagNumber(26)
  $core.bool hasSubscriptionJson() => $_has(25);
  @$pb.TagNumber(26)
  void clearSubscriptionJson() => $_clearField(26);

  @$pb.TagNumber(27)
  $pb.PbList<$0.Feed> get feeds => $_getList(26);

  @$pb.TagNumber(28)
  $core.String get entitlementsJson => $_getSZ(27);
  @$pb.TagNumber(28)
  set entitlementsJson($core.String value) => $_setString(27, value);
  @$pb.TagNumber(28)
  $core.bool hasEntitlementsJson() => $_has(27);
  @$pb.TagNumber(28)
  void clearEntitlementsJson() => $_clearField(28);

  @$pb.TagNumber(29)
  $core.String get instanceJson => $_getSZ(28);
  @$pb.TagNumber(29)
  set instanceJson($core.String value) => $_setString(28, value);
  @$pb.TagNumber(29)
  $core.bool hasInstanceJson() => $_has(28);
  @$pb.TagNumber(29)
  void clearInstanceJson() => $_clearField(29);

  @$pb.TagNumber(30)
  $core.bool get usernameSet => $_getBF(29);
  @$pb.TagNumber(30)
  set usernameSet($core.bool value) => $_setBool(29, value);
  @$pb.TagNumber(30)
  $core.bool hasUsernameSet() => $_has(29);
  @$pb.TagNumber(30)
  void clearUsernameSet() => $_clearField(30);
}

/// Helper for the member_role_ids map value
class MemberRoleIds extends $pb.GeneratedMessage {
  factory MemberRoleIds({
    $core.Iterable<$core.String>? roleIds,
  }) {
    final result = create();
    if (roleIds != null) result.roleIds.addAll(roleIds);
    return result;
  }

  MemberRoleIds._();

  factory MemberRoleIds.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MemberRoleIds.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemberRoleIds',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'roleIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberRoleIds clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberRoleIds copyWith(void Function(MemberRoleIds) updates) =>
      super.copyWith((message) => updates(message as MemberRoleIds))
          as MemberRoleIds;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MemberRoleIds create() => MemberRoleIds._();
  @$core.override
  MemberRoleIds createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MemberRoleIds getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemberRoleIds>(create);
  static MemberRoleIds? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get roleIds => $_getList(0);
}

/// Delta READY — sent on reconnect instead of full READY when possible.
/// Only populated fields represent "changes since last READY".
class ReadyDelta extends $pb.GeneratedMessage {
  factory ReadyDelta({
    $core.Iterable<$0.Channel>? updatedChannels,
    $core.Iterable<$core.String>? removedChannelIds,
    $core.Iterable<$0.Role>? updatedRoles,
    $core.Iterable<$core.String>? removedRoleIds,
    $core.Iterable<$0.ChannelReadState>? readStates,
    $core.Iterable<PresenceEntry>? presences,
    $core.String? serverVersion,
    $core.String? sessionId,
    $core.Iterable<$core.MapEntry<$core.String, $core.bool>>? featureFlags,
  }) {
    final result = create();
    if (updatedChannels != null) result.updatedChannels.addAll(updatedChannels);
    if (removedChannelIds != null)
      result.removedChannelIds.addAll(removedChannelIds);
    if (updatedRoles != null) result.updatedRoles.addAll(updatedRoles);
    if (removedRoleIds != null) result.removedRoleIds.addAll(removedRoleIds);
    if (readStates != null) result.readStates.addAll(readStates);
    if (presences != null) result.presences.addAll(presences);
    if (serverVersion != null) result.serverVersion = serverVersion;
    if (sessionId != null) result.sessionId = sessionId;
    if (featureFlags != null) result.featureFlags.addEntries(featureFlags);
    return result;
  }

  ReadyDelta._();

  factory ReadyDelta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadyDelta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadyDelta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..pPM<$0.Channel>(1, _omitFieldNames ? '' : 'updatedChannels',
        subBuilder: $0.Channel.create)
    ..pPS(2, _omitFieldNames ? '' : 'removedChannelIds')
    ..pPM<$0.Role>(3, _omitFieldNames ? '' : 'updatedRoles',
        subBuilder: $0.Role.create)
    ..pPS(4, _omitFieldNames ? '' : 'removedRoleIds')
    ..pPM<$0.ChannelReadState>(5, _omitFieldNames ? '' : 'readStates',
        subBuilder: $0.ChannelReadState.create)
    ..pPM<PresenceEntry>(6, _omitFieldNames ? '' : 'presences',
        subBuilder: PresenceEntry.create)
    ..aOS(7, _omitFieldNames ? '' : 'serverVersion')
    ..aOS(8, _omitFieldNames ? '' : 'sessionId')
    ..m<$core.String, $core.bool>(9, _omitFieldNames ? '' : 'featureFlags',
        entryClassName: 'ReadyDelta.FeatureFlagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('verdant'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadyDelta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadyDelta copyWith(void Function(ReadyDelta) updates) =>
      super.copyWith((message) => updates(message as ReadyDelta)) as ReadyDelta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadyDelta create() => ReadyDelta._();
  @$core.override
  ReadyDelta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadyDelta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadyDelta>(create);
  static ReadyDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.Channel> get updatedChannels => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get removedChannelIds => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$0.Role> get updatedRoles => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get removedRoleIds => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$0.ChannelReadState> get readStates => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<PresenceEntry> get presences => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get serverVersion => $_getSZ(6);
  @$pb.TagNumber(7)
  set serverVersion($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasServerVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearServerVersion() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get sessionId => $_getSZ(7);
  @$pb.TagNumber(8)
  set sessionId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSessionId() => $_has(7);
  @$pb.TagNumber(8)
  void clearSessionId() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbMap<$core.String, $core.bool> get featureFlags => $_getMap(8);
}

class PresenceEntry extends $pb.GeneratedMessage {
  factory PresenceEntry({
    $core.String? userId,
    $core.String? status,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (status != null) result.status = status;
    return result;
  }

  PresenceEntry._();

  factory PresenceEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PresenceEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PresenceEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceEntry copyWith(void Function(PresenceEntry) updates) =>
      super.copyWith((message) => updates(message as PresenceEntry))
          as PresenceEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PresenceEntry create() => PresenceEntry._();
  @$core.override
  PresenceEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PresenceEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PresenceEntry>(create);
  static PresenceEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

class MessageCreate extends $pb.GeneratedMessage {
  factory MessageCreate({
    $0.Message? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  MessageCreate._();

  factory MessageCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: $0.Message.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageCreate copyWith(void Function(MessageCreate) updates) =>
      super.copyWith((message) => updates(message as MessageCreate))
          as MessageCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageCreate create() => MessageCreate._();
  @$core.override
  MessageCreate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MessageCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageCreate>(create);
  static MessageCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message($0.Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Message ensureMessage() => $_ensure(0);
}

class MessageUpdate extends $pb.GeneratedMessage {
  factory MessageUpdate({
    $0.Message? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  MessageUpdate._();

  factory MessageUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.Message>(1, _omitFieldNames ? '' : 'message',
        subBuilder: $0.Message.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageUpdate copyWith(void Function(MessageUpdate) updates) =>
      super.copyWith((message) => updates(message as MessageUpdate))
          as MessageUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageUpdate create() => MessageUpdate._();
  @$core.override
  MessageUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MessageUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageUpdate>(create);
  static MessageUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Message get message => $_getN(0);
  @$pb.TagNumber(1)
  set message($0.Message value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Message ensureMessage() => $_ensure(0);
}

class MessageDelete extends $pb.GeneratedMessage {
  factory MessageDelete({
    $core.String? id,
    $core.String? channelId,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  MessageDelete._();

  factory MessageDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageDelete copyWith(void Function(MessageDelete) updates) =>
      super.copyWith((message) => updates(message as MessageDelete))
          as MessageDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageDelete create() => MessageDelete._();
  @$core.override
  MessageDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MessageDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageDelete>(create);
  static MessageDelete? _defaultInstance;

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
}

class ChannelUnreadSignal extends $pb.GeneratedMessage {
  factory ChannelUnreadSignal({
    $core.String? channelId,
    $core.String? serverId,
    $core.String? messageId,
    $core.String? authorId,
    $core.String? createdAt,
    $core.bool? mentionsCurrentUser,
    $core.bool? dm,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (serverId != null) result.serverId = serverId;
    if (messageId != null) result.messageId = messageId;
    if (authorId != null) result.authorId = authorId;
    if (createdAt != null) result.createdAt = createdAt;
    if (mentionsCurrentUser != null)
      result.mentionsCurrentUser = mentionsCurrentUser;
    if (dm != null) result.dm = dm;
    return result;
  }

  ChannelUnreadSignal._();

  factory ChannelUnreadSignal.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelUnreadSignal.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelUnreadSignal',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..aOS(3, _omitFieldNames ? '' : 'messageId')
    ..aOS(4, _omitFieldNames ? '' : 'authorId')
    ..aOS(5, _omitFieldNames ? '' : 'createdAt')
    ..aOB(6, _omitFieldNames ? '' : 'mentionsCurrentUser')
    ..aOB(7, _omitFieldNames ? '' : 'dm')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelUnreadSignal clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelUnreadSignal copyWith(void Function(ChannelUnreadSignal) updates) =>
      super.copyWith((message) => updates(message as ChannelUnreadSignal))
          as ChannelUnreadSignal;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelUnreadSignal create() => ChannelUnreadSignal._();
  @$core.override
  ChannelUnreadSignal createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChannelUnreadSignal getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelUnreadSignal>(create);
  static ChannelUnreadSignal? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get messageId => $_getSZ(2);
  @$pb.TagNumber(3)
  set messageId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessageId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessageId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get authorId => $_getSZ(3);
  @$pb.TagNumber(4)
  set authorId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthorId() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthorId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get createdAt => $_getSZ(4);
  @$pb.TagNumber(5)
  set createdAt($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get mentionsCurrentUser => $_getBF(5);
  @$pb.TagNumber(6)
  set mentionsCurrentUser($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMentionsCurrentUser() => $_has(5);
  @$pb.TagNumber(6)
  void clearMentionsCurrentUser() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get dm => $_getBF(6);
  @$pb.TagNumber(7)
  set dm($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDm() => $_has(6);
  @$pb.TagNumber(7)
  void clearDm() => $_clearField(7);
}

class ChannelActivityUpdate extends $pb.GeneratedMessage {
  factory ChannelActivityUpdate({
    $core.String? channelId,
    $core.String? userId,
    $core.String? lastMessageAt,
    $core.String? username,
    $core.String? displayName,
    $core.String? avatarUrl,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (lastMessageAt != null) result.lastMessageAt = lastMessageAt;
    if (username != null) result.username = username;
    if (displayName != null) result.displayName = displayName;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    return result;
  }

  ChannelActivityUpdate._();

  factory ChannelActivityUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelActivityUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelActivityUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'lastMessageAt')
    ..aOS(4, _omitFieldNames ? '' : 'username')
    ..aOS(5, _omitFieldNames ? '' : 'displayName')
    ..aOS(6, _omitFieldNames ? '' : 'avatarUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelActivityUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelActivityUpdate copyWith(
          void Function(ChannelActivityUpdate) updates) =>
      super.copyWith((message) => updates(message as ChannelActivityUpdate))
          as ChannelActivityUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelActivityUpdate create() => ChannelActivityUpdate._();
  @$core.override
  ChannelActivityUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChannelActivityUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelActivityUpdate>(create);
  static ChannelActivityUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get lastMessageAt => $_getSZ(2);
  @$pb.TagNumber(3)
  set lastMessageAt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLastMessageAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastMessageAt() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get username => $_getSZ(3);
  @$pb.TagNumber(4)
  set username($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUsername() => $_has(3);
  @$pb.TagNumber(4)
  void clearUsername() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get displayName => $_getSZ(4);
  @$pb.TagNumber(5)
  set displayName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplayName() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplayName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get avatarUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set avatarUrl($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAvatarUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearAvatarUrl() => $_clearField(6);
}

class TypingStart extends $pb.GeneratedMessage {
  factory TypingStart({
    $core.String? channelId,
    $core.String? userId,
    $core.String? timestamp,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  TypingStart._();

  factory TypingStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TypingStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TypingStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypingStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypingStart copyWith(void Function(TypingStart) updates) =>
      super.copyWith((message) => updates(message as TypingStart))
          as TypingStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TypingStart create() => TypingStart._();
  @$core.override
  TypingStart createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TypingStart getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TypingStart>(create);
  static TypingStart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get timestamp => $_getSZ(2);
  @$pb.TagNumber(3)
  set timestamp($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => $_clearField(3);
}

class PresenceUpdate extends $pb.GeneratedMessage {
  factory PresenceUpdate({
    $core.String? userId,
    $0.UserStatus? status,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (status != null) result.status = status;
    return result;
  }

  PresenceUpdate._();

  factory PresenceUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PresenceUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PresenceUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aE<$0.UserStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: $0.UserStatus.values)
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
  static PresenceUpdate create() => PresenceUpdate._();
  @$core.override
  PresenceUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PresenceUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PresenceUpdate>(create);
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
  $0.UserStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status($0.UserStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

class ChannelCreate extends $pb.GeneratedMessage {
  factory ChannelCreate({
    $0.Channel? channel,
  }) {
    final result = create();
    if (channel != null) result.channel = channel;
    return result;
  }

  ChannelCreate._();

  factory ChannelCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.Channel>(1, _omitFieldNames ? '' : 'channel',
        subBuilder: $0.Channel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelCreate copyWith(void Function(ChannelCreate) updates) =>
      super.copyWith((message) => updates(message as ChannelCreate))
          as ChannelCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelCreate create() => ChannelCreate._();
  @$core.override
  ChannelCreate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChannelCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelCreate>(create);
  static ChannelCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Channel get channel => $_getN(0);
  @$pb.TagNumber(1)
  set channel($0.Channel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannel() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Channel ensureChannel() => $_ensure(0);
}

class ChannelUpdate extends $pb.GeneratedMessage {
  factory ChannelUpdate({
    $0.Channel? channel,
  }) {
    final result = create();
    if (channel != null) result.channel = channel;
    return result;
  }

  ChannelUpdate._();

  factory ChannelUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.Channel>(1, _omitFieldNames ? '' : 'channel',
        subBuilder: $0.Channel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelUpdate copyWith(void Function(ChannelUpdate) updates) =>
      super.copyWith((message) => updates(message as ChannelUpdate))
          as ChannelUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelUpdate create() => ChannelUpdate._();
  @$core.override
  ChannelUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChannelUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelUpdate>(create);
  static ChannelUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Channel get channel => $_getN(0);
  @$pb.TagNumber(1)
  set channel($0.Channel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannel() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Channel ensureChannel() => $_ensure(0);
}

class ChannelDelete extends $pb.GeneratedMessage {
  factory ChannelDelete({
    $core.String? channelId,
    $core.String? serverId,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  ChannelDelete._();

  factory ChannelDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelDelete copyWith(void Function(ChannelDelete) updates) =>
      super.copyWith((message) => updates(message as ChannelDelete))
          as ChannelDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelDelete create() => ChannelDelete._();
  @$core.override
  ChannelDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChannelDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelDelete>(create);
  static ChannelDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);
}

class MemberRemove extends $pb.GeneratedMessage {
  factory MemberRemove({
    $core.String? serverId,
    $core.String? userId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (userId != null) result.userId = userId;
    return result;
  }

  MemberRemove._();

  factory MemberRemove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MemberRemove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemberRemove',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberRemove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberRemove copyWith(void Function(MemberRemove) updates) =>
      super.copyWith((message) => updates(message as MemberRemove))
          as MemberRemove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MemberRemove create() => MemberRemove._();
  @$core.override
  MemberRemove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MemberRemove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemberRemove>(create);
  static MemberRemove? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);
}

class ServerDelete extends $pb.GeneratedMessage {
  factory ServerDelete({
    $core.String? serverId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  ServerDelete._();

  factory ServerDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerDelete copyWith(void Function(ServerDelete) updates) =>
      super.copyWith((message) => updates(message as ServerDelete))
          as ServerDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerDelete create() => ServerDelete._();
  @$core.override
  ServerDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerDelete>(create);
  static ServerDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);
}

class VoiceStateUpdate extends $pb.GeneratedMessage {
  factory VoiceStateUpdate({
    $0.VoiceState? voiceState,
  }) {
    final result = create();
    if (voiceState != null) result.voiceState = voiceState;
    return result;
  }

  VoiceStateUpdate._();

  factory VoiceStateUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VoiceStateUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VoiceStateUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.VoiceState>(1, _omitFieldNames ? '' : 'voiceState',
        subBuilder: $0.VoiceState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoiceStateUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoiceStateUpdate copyWith(void Function(VoiceStateUpdate) updates) =>
      super.copyWith((message) => updates(message as VoiceStateUpdate))
          as VoiceStateUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VoiceStateUpdate create() => VoiceStateUpdate._();
  @$core.override
  VoiceStateUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VoiceStateUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VoiceStateUpdate>(create);
  static VoiceStateUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.VoiceState get voiceState => $_getN(0);
  @$pb.TagNumber(1)
  set voiceState($0.VoiceState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVoiceState() => $_has(0);
  @$pb.TagNumber(1)
  void clearVoiceState() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.VoiceState ensureVoiceState() => $_ensure(0);
}

class CategoryCreate extends $pb.GeneratedMessage {
  factory CategoryCreate({
    $0.Category? category,
  }) {
    final result = create();
    if (category != null) result.category = category;
    return result;
  }

  CategoryCreate._();

  factory CategoryCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CategoryCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CategoryCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.Category>(1, _omitFieldNames ? '' : 'category',
        subBuilder: $0.Category.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryCreate copyWith(void Function(CategoryCreate) updates) =>
      super.copyWith((message) => updates(message as CategoryCreate))
          as CategoryCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CategoryCreate create() => CategoryCreate._();
  @$core.override
  CategoryCreate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CategoryCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CategoryCreate>(create);
  static CategoryCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Category get category => $_getN(0);
  @$pb.TagNumber(1)
  set category($0.Category value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCategory() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategory() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Category ensureCategory() => $_ensure(0);
}

class CategoryUpdate extends $pb.GeneratedMessage {
  factory CategoryUpdate({
    $0.Category? category,
  }) {
    final result = create();
    if (category != null) result.category = category;
    return result;
  }

  CategoryUpdate._();

  factory CategoryUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CategoryUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CategoryUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.Category>(1, _omitFieldNames ? '' : 'category',
        subBuilder: $0.Category.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryUpdate copyWith(void Function(CategoryUpdate) updates) =>
      super.copyWith((message) => updates(message as CategoryUpdate))
          as CategoryUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CategoryUpdate create() => CategoryUpdate._();
  @$core.override
  CategoryUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CategoryUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CategoryUpdate>(create);
  static CategoryUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Category get category => $_getN(0);
  @$pb.TagNumber(1)
  set category($0.Category value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCategory() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategory() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Category ensureCategory() => $_ensure(0);
}

class CategoryDelete extends $pb.GeneratedMessage {
  factory CategoryDelete({
    $core.String? categoryId,
    $core.String? serverId,
  }) {
    final result = create();
    if (categoryId != null) result.categoryId = categoryId;
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  CategoryDelete._();

  factory CategoryDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CategoryDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CategoryDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'categoryId')
    ..aOS(2, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryDelete copyWith(void Function(CategoryDelete) updates) =>
      super.copyWith((message) => updates(message as CategoryDelete))
          as CategoryDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CategoryDelete create() => CategoryDelete._();
  @$core.override
  CategoryDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CategoryDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CategoryDelete>(create);
  static CategoryDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get categoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set categoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCategoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverId => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerId() => $_clearField(2);
}

class ReactionAdd extends $pb.GeneratedMessage {
  factory ReactionAdd({
    $core.String? messageId,
    $core.String? channelId,
    $core.String? userId,
    $core.String? emoji,
    $core.String? emojiId,
  }) {
    final result = create();
    if (messageId != null) result.messageId = messageId;
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (emoji != null) result.emoji = emoji;
    if (emojiId != null) result.emojiId = emojiId;
    return result;
  }

  ReactionAdd._();

  factory ReactionAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReactionAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReactionAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aOS(3, _omitFieldNames ? '' : 'userId')
    ..aOS(4, _omitFieldNames ? '' : 'emoji')
    ..aOS(5, _omitFieldNames ? '' : 'emojiId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReactionAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReactionAdd copyWith(void Function(ReactionAdd) updates) =>
      super.copyWith((message) => updates(message as ReactionAdd))
          as ReactionAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReactionAdd create() => ReactionAdd._();
  @$core.override
  ReactionAdd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReactionAdd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReactionAdd>(create);
  static ReactionAdd? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get userId => $_getSZ(2);
  @$pb.TagNumber(3)
  set userId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get emoji => $_getSZ(3);
  @$pb.TagNumber(4)
  set emoji($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmoji() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmoji() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get emojiId => $_getSZ(4);
  @$pb.TagNumber(5)
  set emojiId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEmojiId() => $_has(4);
  @$pb.TagNumber(5)
  void clearEmojiId() => $_clearField(5);
}

class ReactionRemove extends $pb.GeneratedMessage {
  factory ReactionRemove({
    $core.String? messageId,
    $core.String? channelId,
    $core.String? userId,
    $core.String? emoji,
  }) {
    final result = create();
    if (messageId != null) result.messageId = messageId;
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (emoji != null) result.emoji = emoji;
    return result;
  }

  ReactionRemove._();

  factory ReactionRemove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReactionRemove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReactionRemove',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aOS(3, _omitFieldNames ? '' : 'userId')
    ..aOS(4, _omitFieldNames ? '' : 'emoji')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReactionRemove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReactionRemove copyWith(void Function(ReactionRemove) updates) =>
      super.copyWith((message) => updates(message as ReactionRemove))
          as ReactionRemove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReactionRemove create() => ReactionRemove._();
  @$core.override
  ReactionRemove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReactionRemove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReactionRemove>(create);
  static ReactionRemove? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get userId => $_getSZ(2);
  @$pb.TagNumber(3)
  set userId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get emoji => $_getSZ(3);
  @$pb.TagNumber(4)
  set emoji($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmoji() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmoji() => $_clearField(4);
}

class RoleCreate extends $pb.GeneratedMessage {
  factory RoleCreate({
    $core.String? serverId,
    $0.Role? role,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (role != null) result.role = role;
    return result;
  }

  RoleCreate._();

  factory RoleCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoleCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoleCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOM<$0.Role>(2, _omitFieldNames ? '' : 'role', subBuilder: $0.Role.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleCreate copyWith(void Function(RoleCreate) updates) =>
      super.copyWith((message) => updates(message as RoleCreate)) as RoleCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoleCreate create() => RoleCreate._();
  @$core.override
  RoleCreate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RoleCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoleCreate>(create);
  static RoleCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Role get role => $_getN(1);
  @$pb.TagNumber(2)
  set role($0.Role value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Role ensureRole() => $_ensure(1);
}

class RoleUpdate extends $pb.GeneratedMessage {
  factory RoleUpdate({
    $core.String? serverId,
    $0.Role? role,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (role != null) result.role = role;
    return result;
  }

  RoleUpdate._();

  factory RoleUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoleUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoleUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOM<$0.Role>(2, _omitFieldNames ? '' : 'role', subBuilder: $0.Role.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleUpdate copyWith(void Function(RoleUpdate) updates) =>
      super.copyWith((message) => updates(message as RoleUpdate)) as RoleUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoleUpdate create() => RoleUpdate._();
  @$core.override
  RoleUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RoleUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoleUpdate>(create);
  static RoleUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Role get role => $_getN(1);
  @$pb.TagNumber(2)
  set role($0.Role value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Role ensureRole() => $_ensure(1);
}

class RoleDelete extends $pb.GeneratedMessage {
  factory RoleDelete({
    $core.String? serverId,
    $core.String? roleId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (roleId != null) result.roleId = roleId;
    return result;
  }

  RoleDelete._();

  factory RoleDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoleDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoleDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'roleId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleDelete copyWith(void Function(RoleDelete) updates) =>
      super.copyWith((message) => updates(message as RoleDelete)) as RoleDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoleDelete create() => RoleDelete._();
  @$core.override
  RoleDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RoleDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoleDelete>(create);
  static RoleDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get roleId => $_getSZ(1);
  @$pb.TagNumber(2)
  set roleId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoleId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoleId() => $_clearField(2);
}

class MemberRoleUpdate extends $pb.GeneratedMessage {
  factory MemberRoleUpdate({
    $core.String? serverId,
    $core.String? userId,
    $core.Iterable<$core.String>? roleIds,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (userId != null) result.userId = userId;
    if (roleIds != null) result.roleIds.addAll(roleIds);
    return result;
  }

  MemberRoleUpdate._();

  factory MemberRoleUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MemberRoleUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemberRoleUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..pPS(3, _omitFieldNames ? '' : 'roleIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberRoleUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberRoleUpdate copyWith(void Function(MemberRoleUpdate) updates) =>
      super.copyWith((message) => updates(message as MemberRoleUpdate))
          as MemberRoleUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MemberRoleUpdate create() => MemberRoleUpdate._();
  @$core.override
  MemberRoleUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MemberRoleUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemberRoleUpdate>(create);
  static MemberRoleUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get roleIds => $_getList(2);
}

class ForceUpdate extends $pb.GeneratedMessage {
  factory ForceUpdate({
    $core.String? minVersion,
    $core.String? downloadUrl,
  }) {
    final result = create();
    if (minVersion != null) result.minVersion = minVersion;
    if (downloadUrl != null) result.downloadUrl = downloadUrl;
    return result;
  }

  ForceUpdate._();

  factory ForceUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ForceUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ForceUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'minVersion')
    ..aOS(2, _omitFieldNames ? '' : 'downloadUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForceUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForceUpdate copyWith(void Function(ForceUpdate) updates) =>
      super.copyWith((message) => updates(message as ForceUpdate))
          as ForceUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ForceUpdate create() => ForceUpdate._();
  @$core.override
  ForceUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ForceUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ForceUpdate>(create);
  static ForceUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get minVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set minVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMinVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearMinVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get downloadUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set downloadUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDownloadUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearDownloadUrl() => $_clearField(2);
}

class FeatureFlagsUpdate extends $pb.GeneratedMessage {
  factory FeatureFlagsUpdate({
    $core.Iterable<$core.MapEntry<$core.String, $core.bool>>? flags,
  }) {
    final result = create();
    if (flags != null) result.flags.addEntries(flags);
    return result;
  }

  FeatureFlagsUpdate._();

  factory FeatureFlagsUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FeatureFlagsUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeatureFlagsUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..m<$core.String, $core.bool>(1, _omitFieldNames ? '' : 'flags',
        entryClassName: 'FeatureFlagsUpdate.FlagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('verdant'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeatureFlagsUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeatureFlagsUpdate copyWith(void Function(FeatureFlagsUpdate) updates) =>
      super.copyWith((message) => updates(message as FeatureFlagsUpdate))
          as FeatureFlagsUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeatureFlagsUpdate create() => FeatureFlagsUpdate._();
  @$core.override
  FeatureFlagsUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FeatureFlagsUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FeatureFlagsUpdate>(create);
  static FeatureFlagsUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $core.bool> get flags => $_getMap(0);
}

class RelationshipAdd extends $pb.GeneratedMessage {
  factory RelationshipAdd({
    $0.Relationship? relationship,
  }) {
    final result = create();
    if (relationship != null) result.relationship = relationship;
    return result;
  }

  RelationshipAdd._();

  factory RelationshipAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelationshipAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelationshipAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.Relationship>(1, _omitFieldNames ? '' : 'relationship',
        subBuilder: $0.Relationship.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelationshipAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelationshipAdd copyWith(void Function(RelationshipAdd) updates) =>
      super.copyWith((message) => updates(message as RelationshipAdd))
          as RelationshipAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelationshipAdd create() => RelationshipAdd._();
  @$core.override
  RelationshipAdd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelationshipAdd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelationshipAdd>(create);
  static RelationshipAdd? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Relationship get relationship => $_getN(0);
  @$pb.TagNumber(1)
  set relationship($0.Relationship value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRelationship() => $_has(0);
  @$pb.TagNumber(1)
  void clearRelationship() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Relationship ensureRelationship() => $_ensure(0);
}

class RelationshipRemove extends $pb.GeneratedMessage {
  factory RelationshipRemove({
    $core.String? userId,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    return result;
  }

  RelationshipRemove._();

  factory RelationshipRemove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RelationshipRemove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RelationshipRemove',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelationshipRemove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RelationshipRemove copyWith(void Function(RelationshipRemove) updates) =>
      super.copyWith((message) => updates(message as RelationshipRemove))
          as RelationshipRemove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RelationshipRemove create() => RelationshipRemove._();
  @$core.override
  RelationshipRemove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RelationshipRemove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RelationshipRemove>(create);
  static RelationshipRemove? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);
}

class DmChannelCreate extends $pb.GeneratedMessage {
  factory DmChannelCreate({
    $0.DmChannel? dmChannel,
  }) {
    final result = create();
    if (dmChannel != null) result.dmChannel = dmChannel;
    return result;
  }

  DmChannelCreate._();

  factory DmChannelCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DmChannelCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DmChannelCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.DmChannel>(1, _omitFieldNames ? '' : 'dmChannel',
        subBuilder: $0.DmChannel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DmChannelCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DmChannelCreate copyWith(void Function(DmChannelCreate) updates) =>
      super.copyWith((message) => updates(message as DmChannelCreate))
          as DmChannelCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DmChannelCreate create() => DmChannelCreate._();
  @$core.override
  DmChannelCreate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DmChannelCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DmChannelCreate>(create);
  static DmChannelCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.DmChannel get dmChannel => $_getN(0);
  @$pb.TagNumber(1)
  set dmChannel($0.DmChannel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDmChannel() => $_has(0);
  @$pb.TagNumber(1)
  void clearDmChannel() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.DmChannel ensureDmChannel() => $_ensure(0);
}

class MessageSendError extends $pb.GeneratedMessage {
  factory MessageSendError({
    $core.String? nonce,
    $core.String? error,
    $core.String? code,
  }) {
    final result = create();
    if (nonce != null) result.nonce = nonce;
    if (error != null) result.error = error;
    if (code != null) result.code = code;
    return result;
  }

  MessageSendError._();

  factory MessageSendError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageSendError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageSendError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nonce')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aOS(3, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageSendError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageSendError copyWith(void Function(MessageSendError) updates) =>
      super.copyWith((message) => updates(message as MessageSendError))
          as MessageSendError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageSendError create() => MessageSendError._();
  @$core.override
  MessageSendError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MessageSendError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageSendError>(create);
  static MessageSendError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nonce => $_getSZ(0);
  @$pb.TagNumber(1)
  set nonce($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearNonce() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get code => $_getSZ(2);
  @$pb.TagNumber(3)
  set code($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCode() => $_clearField(3);
}

class UpdateAvailable extends $pb.GeneratedMessage {
  factory UpdateAvailable({
    $core.String? version,
    $core.String? notes,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (notes != null) result.notes = notes;
    return result;
  }

  UpdateAvailable._();

  factory UpdateAvailable.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateAvailable.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateAvailable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..aOS(2, _omitFieldNames ? '' : 'notes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateAvailable clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateAvailable copyWith(void Function(UpdateAvailable) updates) =>
      super.copyWith((message) => updates(message as UpdateAvailable))
          as UpdateAvailable;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateAvailable create() => UpdateAvailable._();
  @$core.override
  UpdateAvailable createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateAvailable getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateAvailable>(create);
  static UpdateAvailable? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get notes => $_getSZ(1);
  @$pb.TagNumber(2)
  set notes($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNotes() => $_has(1);
  @$pb.TagNumber(2)
  void clearNotes() => $_clearField(2);
}

class WsError extends $pb.GeneratedMessage {
  factory WsError({
    $core.String? originOp,
    $core.String? error,
    $core.String? code,
  }) {
    final result = create();
    if (originOp != null) result.originOp = originOp;
    if (error != null) result.error = error;
    if (code != null) result.code = code;
    return result;
  }

  WsError._();

  factory WsError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WsError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WsError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'originOp')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aOS(3, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsError copyWith(void Function(WsError) updates) =>
      super.copyWith((message) => updates(message as WsError)) as WsError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WsError create() => WsError._();
  @$core.override
  WsError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WsError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WsError>(create);
  static WsError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get originOp => $_getSZ(0);
  @$pb.TagNumber(1)
  set originOp($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOriginOp() => $_has(0);
  @$pb.TagNumber(1)
  void clearOriginOp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get code => $_getSZ(2);
  @$pb.TagNumber(3)
  set code($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCode() => $_clearField(3);
}

class MessagePin extends $pb.GeneratedMessage {
  factory MessagePin({
    $core.String? messageId,
    $core.String? channelId,
    $core.String? pinnedBy,
  }) {
    final result = create();
    if (messageId != null) result.messageId = messageId;
    if (channelId != null) result.channelId = channelId;
    if (pinnedBy != null) result.pinnedBy = pinnedBy;
    return result;
  }

  MessagePin._();

  factory MessagePin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessagePin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessagePin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aOS(3, _omitFieldNames ? '' : 'pinnedBy')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagePin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagePin copyWith(void Function(MessagePin) updates) =>
      super.copyWith((message) => updates(message as MessagePin)) as MessagePin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessagePin create() => MessagePin._();
  @$core.override
  MessagePin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MessagePin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessagePin>(create);
  static MessagePin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get pinnedBy => $_getSZ(2);
  @$pb.TagNumber(3)
  set pinnedBy($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPinnedBy() => $_has(2);
  @$pb.TagNumber(3)
  void clearPinnedBy() => $_clearField(3);
}

class MessageUnpin extends $pb.GeneratedMessage {
  factory MessageUnpin({
    $core.String? messageId,
    $core.String? channelId,
  }) {
    final result = create();
    if (messageId != null) result.messageId = messageId;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  MessageUnpin._();

  factory MessageUnpin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageUnpin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageUnpin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageUnpin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageUnpin copyWith(void Function(MessageUnpin) updates) =>
      super.copyWith((message) => updates(message as MessageUnpin))
          as MessageUnpin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageUnpin create() => MessageUnpin._();
  @$core.override
  MessageUnpin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MessageUnpin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageUnpin>(create);
  static MessageUnpin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);
}

class MemberJoin extends $pb.GeneratedMessage {
  factory MemberJoin({
    $core.String? serverId,
    $core.String? userId,
    $core.String? username,
    $core.String? displayName,
    $core.String? avatarUrl,
    $core.String? joinedAt,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (displayName != null) result.displayName = displayName;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (joinedAt != null) result.joinedAt = joinedAt;
    return result;
  }

  MemberJoin._();

  factory MemberJoin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MemberJoin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemberJoin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'username')
    ..aOS(4, _omitFieldNames ? '' : 'displayName')
    ..aOS(5, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(6, _omitFieldNames ? '' : 'joinedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberJoin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberJoin copyWith(void Function(MemberJoin) updates) =>
      super.copyWith((message) => updates(message as MemberJoin)) as MemberJoin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MemberJoin create() => MemberJoin._();
  @$core.override
  MemberJoin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MemberJoin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemberJoin>(create);
  static MemberJoin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get username => $_getSZ(2);
  @$pb.TagNumber(3)
  set username($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsername() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get avatarUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set avatarUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAvatarUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvatarUrl() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get joinedAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set joinedAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasJoinedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearJoinedAt() => $_clearField(6);
}

class UserProfileUpdate extends $pb.GeneratedMessage {
  factory UserProfileUpdate({
    $core.String? userId,
    $core.String? avatarUrl,
    $core.String? bannerUrl,
    $core.String? displayName,
    $core.String? bio,
    $core.String? bannerBaseColor,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (bannerUrl != null) result.bannerUrl = bannerUrl;
    if (displayName != null) result.displayName = displayName;
    if (bio != null) result.bio = bio;
    if (bannerBaseColor != null) result.bannerBaseColor = bannerBaseColor;
    return result;
  }

  UserProfileUpdate._();

  factory UserProfileUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserProfileUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserProfileUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(3, _omitFieldNames ? '' : 'bannerUrl')
    ..aOS(4, _omitFieldNames ? '' : 'displayName')
    ..aOS(5, _omitFieldNames ? '' : 'bio')
    ..aOS(6, _omitFieldNames ? '' : 'bannerBaseColor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserProfileUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserProfileUpdate copyWith(void Function(UserProfileUpdate) updates) =>
      super.copyWith((message) => updates(message as UserProfileUpdate))
          as UserProfileUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserProfileUpdate create() => UserProfileUpdate._();
  @$core.override
  UserProfileUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserProfileUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserProfileUpdate>(create);
  static UserProfileUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get avatarUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set avatarUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAvatarUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvatarUrl() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get bannerUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set bannerUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBannerUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearBannerUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get bio => $_getSZ(4);
  @$pb.TagNumber(5)
  set bio($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBio() => $_has(4);
  @$pb.TagNumber(5)
  void clearBio() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get bannerBaseColor => $_getSZ(5);
  @$pb.TagNumber(6)
  set bannerBaseColor($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBannerBaseColor() => $_has(5);
  @$pb.TagNumber(6)
  void clearBannerBaseColor() => $_clearField(6);
}

class Identify extends $pb.GeneratedMessage {
  factory Identify({
    $core.String? token,
    $core.String? clientVersion,
    $core.String? resumeSessionId,
    $core.String? lastReadyAt,
    $0.UserStatus? initialStatus,
    $core.bool? afk,
  }) {
    final result = create();
    if (token != null) result.token = token;
    if (clientVersion != null) result.clientVersion = clientVersion;
    if (resumeSessionId != null) result.resumeSessionId = resumeSessionId;
    if (lastReadyAt != null) result.lastReadyAt = lastReadyAt;
    if (initialStatus != null) result.initialStatus = initialStatus;
    if (afk != null) result.afk = afk;
    return result;
  }

  Identify._();

  factory Identify.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Identify.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Identify',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOS(2, _omitFieldNames ? '' : 'clientVersion')
    ..aOS(3, _omitFieldNames ? '' : 'resumeSessionId')
    ..aOS(4, _omitFieldNames ? '' : 'lastReadyAt')
    ..aE<$0.UserStatus>(5, _omitFieldNames ? '' : 'initialStatus',
        enumValues: $0.UserStatus.values)
    ..aOB(6, _omitFieldNames ? '' : 'afk')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Identify clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Identify copyWith(void Function(Identify) updates) =>
      super.copyWith((message) => updates(message as Identify)) as Identify;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Identify create() => Identify._();
  @$core.override
  Identify createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Identify getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Identify>(create);
  static Identify? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get clientVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set clientVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get resumeSessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set resumeSessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasResumeSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearResumeSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get lastReadyAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set lastReadyAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastReadyAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastReadyAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $0.UserStatus get initialStatus => $_getN(4);
  @$pb.TagNumber(5)
  set initialStatus($0.UserStatus value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasInitialStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearInitialStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get afk => $_getBF(5);
  @$pb.TagNumber(6)
  set afk($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAfk() => $_has(5);
  @$pb.TagNumber(6)
  void clearAfk() => $_clearField(6);
}

class ClientTypingStart extends $pb.GeneratedMessage {
  factory ClientTypingStart({
    $core.String? channelId,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ClientTypingStart._();

  factory ClientTypingStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientTypingStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientTypingStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientTypingStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientTypingStart copyWith(void Function(ClientTypingStart) updates) =>
      super.copyWith((message) => updates(message as ClientTypingStart))
          as ClientTypingStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientTypingStart create() => ClientTypingStart._();
  @$core.override
  ClientTypingStart createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientTypingStart getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientTypingStart>(create);
  static ClientTypingStart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

class ClientPresenceUpdate extends $pb.GeneratedMessage {
  factory ClientPresenceUpdate({
    $0.UserStatus? status,
    $core.bool? afk,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (afk != null) result.afk = afk;
    return result;
  }

  ClientPresenceUpdate._();

  factory ClientPresenceUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientPresenceUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientPresenceUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aE<$0.UserStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: $0.UserStatus.values)
    ..aOB(2, _omitFieldNames ? '' : 'afk')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientPresenceUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientPresenceUpdate copyWith(void Function(ClientPresenceUpdate) updates) =>
      super.copyWith((message) => updates(message as ClientPresenceUpdate))
          as ClientPresenceUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientPresenceUpdate create() => ClientPresenceUpdate._();
  @$core.override
  ClientPresenceUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientPresenceUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientPresenceUpdate>(create);
  static ClientPresenceUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.UserStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status($0.UserStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  /// true = client is auto-idled (afk). Server will NOT persist to preferred_status.
  /// false = user manually chose this status → persist to preferred_status in VDB.
  @$pb.TagNumber(2)
  $core.bool get afk => $_getBF(1);
  @$pb.TagNumber(2)
  set afk($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAfk() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfk() => $_clearField(2);
}

class ClientMessageSend extends $pb.GeneratedMessage {
  factory ClientMessageSend({
    $core.String? channelId,
    $core.String? content,
    $core.String? nonce,
    $core.String? replyToId,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (content != null) result.content = content;
    if (nonce != null) result.nonce = nonce;
    if (replyToId != null) result.replyToId = replyToId;
    return result;
  }

  ClientMessageSend._();

  factory ClientMessageSend.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientMessageSend.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientMessageSend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..aOS(3, _omitFieldNames ? '' : 'nonce')
    ..aOS(4, _omitFieldNames ? '' : 'replyToId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessageSend clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessageSend copyWith(void Function(ClientMessageSend) updates) =>
      super.copyWith((message) => updates(message as ClientMessageSend))
          as ClientMessageSend;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientMessageSend create() => ClientMessageSend._();
  @$core.override
  ClientMessageSend createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientMessageSend getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientMessageSend>(create);
  static ClientMessageSend? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nonce => $_getSZ(2);
  @$pb.TagNumber(3)
  set nonce($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNonce() => $_has(2);
  @$pb.TagNumber(3)
  void clearNonce() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get replyToId => $_getSZ(3);
  @$pb.TagNumber(4)
  set replyToId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReplyToId() => $_has(3);
  @$pb.TagNumber(4)
  void clearReplyToId() => $_clearField(4);
}

class ClientMessageEdit extends $pb.GeneratedMessage {
  factory ClientMessageEdit({
    $core.String? channelId,
    $core.String? messageId,
    $core.String? content,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (messageId != null) result.messageId = messageId;
    if (content != null) result.content = content;
    return result;
  }

  ClientMessageEdit._();

  factory ClientMessageEdit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientMessageEdit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientMessageEdit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'content')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessageEdit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessageEdit copyWith(void Function(ClientMessageEdit) updates) =>
      super.copyWith((message) => updates(message as ClientMessageEdit))
          as ClientMessageEdit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientMessageEdit create() => ClientMessageEdit._();
  @$core.override
  ClientMessageEdit createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientMessageEdit getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientMessageEdit>(create);
  static ClientMessageEdit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get content => $_getSZ(2);
  @$pb.TagNumber(3)
  set content($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearContent() => $_clearField(3);
}

class ClientMessageDelete extends $pb.GeneratedMessage {
  factory ClientMessageDelete({
    $core.String? channelId,
    $core.String? messageId,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (messageId != null) result.messageId = messageId;
    return result;
  }

  ClientMessageDelete._();

  factory ClientMessageDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientMessageDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientMessageDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessageDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessageDelete copyWith(void Function(ClientMessageDelete) updates) =>
      super.copyWith((message) => updates(message as ClientMessageDelete))
          as ClientMessageDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientMessageDelete create() => ClientMessageDelete._();
  @$core.override
  ClientMessageDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientMessageDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientMessageDelete>(create);
  static ClientMessageDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);
}

class ClientReactionAdd extends $pb.GeneratedMessage {
  factory ClientReactionAdd({
    $core.String? channelId,
    $core.String? messageId,
    $core.String? emoji,
    $core.String? emojiId,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (messageId != null) result.messageId = messageId;
    if (emoji != null) result.emoji = emoji;
    if (emojiId != null) result.emojiId = emojiId;
    return result;
  }

  ClientReactionAdd._();

  factory ClientReactionAdd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientReactionAdd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientReactionAdd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'emoji')
    ..aOS(4, _omitFieldNames ? '' : 'emojiId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientReactionAdd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientReactionAdd copyWith(void Function(ClientReactionAdd) updates) =>
      super.copyWith((message) => updates(message as ClientReactionAdd))
          as ClientReactionAdd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientReactionAdd create() => ClientReactionAdd._();
  @$core.override
  ClientReactionAdd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientReactionAdd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientReactionAdd>(create);
  static ClientReactionAdd? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get emoji => $_getSZ(2);
  @$pb.TagNumber(3)
  set emoji($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmoji() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmoji() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get emojiId => $_getSZ(3);
  @$pb.TagNumber(4)
  set emojiId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmojiId() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmojiId() => $_clearField(4);
}

class ClientReactionRemove extends $pb.GeneratedMessage {
  factory ClientReactionRemove({
    $core.String? channelId,
    $core.String? messageId,
    $core.String? emoji,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (messageId != null) result.messageId = messageId;
    if (emoji != null) result.emoji = emoji;
    return result;
  }

  ClientReactionRemove._();

  factory ClientReactionRemove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientReactionRemove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientReactionRemove',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'emoji')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientReactionRemove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientReactionRemove copyWith(void Function(ClientReactionRemove) updates) =>
      super.copyWith((message) => updates(message as ClientReactionRemove))
          as ClientReactionRemove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientReactionRemove create() => ClientReactionRemove._();
  @$core.override
  ClientReactionRemove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientReactionRemove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientReactionRemove>(create);
  static ClientReactionRemove? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get emoji => $_getSZ(2);
  @$pb.TagNumber(3)
  set emoji($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmoji() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmoji() => $_clearField(3);
}

class ClientChannelAck extends $pb.GeneratedMessage {
  factory ClientChannelAck({
    $core.String? channelId,
    $core.String? messageId,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (messageId != null) result.messageId = messageId;
    return result;
  }

  ClientChannelAck._();

  factory ClientChannelAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientChannelAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientChannelAck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientChannelAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientChannelAck copyWith(void Function(ClientChannelAck) updates) =>
      super.copyWith((message) => updates(message as ClientChannelAck))
          as ClientChannelAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientChannelAck create() => ClientChannelAck._();
  @$core.override
  ClientChannelAck createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientChannelAck getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientChannelAck>(create);
  static ClientChannelAck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);
}

class ClientVoiceState extends $pb.GeneratedMessage {
  factory ClientVoiceState({
    $core.bool? selfMute,
    $core.bool? selfDeaf,
  }) {
    final result = create();
    if (selfMute != null) result.selfMute = selfMute;
    if (selfDeaf != null) result.selfDeaf = selfDeaf;
    return result;
  }

  ClientVoiceState._();

  factory ClientVoiceState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientVoiceState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientVoiceState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'selfMute')
    ..aOB(2, _omitFieldNames ? '' : 'selfDeaf')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientVoiceState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientVoiceState copyWith(void Function(ClientVoiceState) updates) =>
      super.copyWith((message) => updates(message as ClientVoiceState))
          as ClientVoiceState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientVoiceState create() => ClientVoiceState._();
  @$core.override
  ClientVoiceState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientVoiceState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientVoiceState>(create);
  static ClientVoiceState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get selfMute => $_getBF(0);
  @$pb.TagNumber(1)
  set selfMute($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSelfMute() => $_has(0);
  @$pb.TagNumber(1)
  void clearSelfMute() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get selfDeaf => $_getBF(1);
  @$pb.TagNumber(2)
  set selfDeaf($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSelfDeaf() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelfDeaf() => $_clearField(2);
}

class ClientVoiceLeave extends $pb.GeneratedMessage {
  factory ClientVoiceLeave() => create();

  ClientVoiceLeave._();

  factory ClientVoiceLeave.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientVoiceLeave.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientVoiceLeave',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientVoiceLeave clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientVoiceLeave copyWith(void Function(ClientVoiceLeave) updates) =>
      super.copyWith((message) => updates(message as ClientVoiceLeave))
          as ClientVoiceLeave;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientVoiceLeave create() => ClientVoiceLeave._();
  @$core.override
  ClientVoiceLeave createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientVoiceLeave getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientVoiceLeave>(create);
  static ClientVoiceLeave? _defaultInstance;
}

class ServerUpdate extends $pb.GeneratedMessage {
  factory ServerUpdate({
    $0.Server? server,
  }) {
    final result = create();
    if (server != null) result.server = server;
    return result;
  }

  ServerUpdate._();

  factory ServerUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOM<$0.Server>(1, _omitFieldNames ? '' : 'server',
        subBuilder: $0.Server.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerUpdate copyWith(void Function(ServerUpdate) updates) =>
      super.copyWith((message) => updates(message as ServerUpdate))
          as ServerUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerUpdate create() => ServerUpdate._();
  @$core.override
  ServerUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerUpdate>(create);
  static ServerUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Server get server => $_getN(0);
  @$pb.TagNumber(1)
  set server($0.Server value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Server ensureServer() => $_ensure(0);
}

class ServerEmojisUpdate extends $pb.GeneratedMessage {
  factory ServerEmojisUpdate({
    $core.String? serverId,
    $core.int? emojiVersion,
    $core.Iterable<$0.Emoji>? emojis,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (emojiVersion != null) result.emojiVersion = emojiVersion;
    if (emojis != null) result.emojis.addAll(emojis);
    return result;
  }

  ServerEmojisUpdate._();

  factory ServerEmojisUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerEmojisUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerEmojisUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aI(2, _omitFieldNames ? '' : 'emojiVersion')
    ..pPM<$0.Emoji>(3, _omitFieldNames ? '' : 'emojis',
        subBuilder: $0.Emoji.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerEmojisUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerEmojisUpdate copyWith(void Function(ServerEmojisUpdate) updates) =>
      super.copyWith((message) => updates(message as ServerEmojisUpdate))
          as ServerEmojisUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerEmojisUpdate create() => ServerEmojisUpdate._();
  @$core.override
  ServerEmojisUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerEmojisUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerEmojisUpdate>(create);
  static ServerEmojisUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get emojiVersion => $_getIZ(1);
  @$pb.TagNumber(2)
  set emojiVersion($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEmojiVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmojiVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$0.Emoji> get emojis => $_getList(2);
}

class DmNameColorUpdate extends $pb.GeneratedMessage {
  factory DmNameColorUpdate({
    $core.String? channelId,
    $core.String? userId,
    $core.String? nameColor,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (nameColor != null) result.nameColor = nameColor;
    return result;
  }

  DmNameColorUpdate._();

  factory DmNameColorUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DmNameColorUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DmNameColorUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'nameColor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DmNameColorUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DmNameColorUpdate copyWith(void Function(DmNameColorUpdate) updates) =>
      super.copyWith((message) => updates(message as DmNameColorUpdate))
          as DmNameColorUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DmNameColorUpdate create() => DmNameColorUpdate._();
  @$core.override
  DmNameColorUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DmNameColorUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DmNameColorUpdate>(create);
  static DmNameColorUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nameColor => $_getSZ(2);
  @$pb.TagNumber(3)
  set nameColor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNameColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearNameColor() => $_clearField(3);
}

class AnnouncementCreate extends $pb.GeneratedMessage {
  factory AnnouncementCreate({
    $core.String? serverId,
    $core.String? feedId,
    $0.Announcement? announcement,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (feedId != null) result.feedId = feedId;
    if (announcement != null) result.announcement = announcement;
    return result;
  }

  AnnouncementCreate._();

  factory AnnouncementCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AnnouncementCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnnouncementCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'feedId')
    ..aOM<$0.Announcement>(3, _omitFieldNames ? '' : 'announcement',
        subBuilder: $0.Announcement.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnouncementCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnouncementCreate copyWith(void Function(AnnouncementCreate) updates) =>
      super.copyWith((message) => updates(message as AnnouncementCreate))
          as AnnouncementCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnnouncementCreate create() => AnnouncementCreate._();
  @$core.override
  AnnouncementCreate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AnnouncementCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnnouncementCreate>(create);
  static AnnouncementCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get feedId => $_getSZ(1);
  @$pb.TagNumber(2)
  set feedId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFeedId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeedId() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Announcement get announcement => $_getN(2);
  @$pb.TagNumber(3)
  set announcement($0.Announcement value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAnnouncement() => $_has(2);
  @$pb.TagNumber(3)
  void clearAnnouncement() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Announcement ensureAnnouncement() => $_ensure(2);
}

class AnnouncementUpdate extends $pb.GeneratedMessage {
  factory AnnouncementUpdate({
    $core.String? serverId,
    $core.String? feedId,
    $0.Announcement? announcement,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (feedId != null) result.feedId = feedId;
    if (announcement != null) result.announcement = announcement;
    return result;
  }

  AnnouncementUpdate._();

  factory AnnouncementUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AnnouncementUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnnouncementUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'feedId')
    ..aOM<$0.Announcement>(3, _omitFieldNames ? '' : 'announcement',
        subBuilder: $0.Announcement.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnouncementUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnouncementUpdate copyWith(void Function(AnnouncementUpdate) updates) =>
      super.copyWith((message) => updates(message as AnnouncementUpdate))
          as AnnouncementUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnnouncementUpdate create() => AnnouncementUpdate._();
  @$core.override
  AnnouncementUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AnnouncementUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnnouncementUpdate>(create);
  static AnnouncementUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get feedId => $_getSZ(1);
  @$pb.TagNumber(2)
  set feedId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFeedId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeedId() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Announcement get announcement => $_getN(2);
  @$pb.TagNumber(3)
  set announcement($0.Announcement value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAnnouncement() => $_has(2);
  @$pb.TagNumber(3)
  void clearAnnouncement() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Announcement ensureAnnouncement() => $_ensure(2);
}

class AnnouncementDelete extends $pb.GeneratedMessage {
  factory AnnouncementDelete({
    $core.String? serverId,
    $core.String? feedId,
    $core.String? announcementId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (feedId != null) result.feedId = feedId;
    if (announcementId != null) result.announcementId = announcementId;
    return result;
  }

  AnnouncementDelete._();

  factory AnnouncementDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AnnouncementDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnnouncementDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'feedId')
    ..aOS(3, _omitFieldNames ? '' : 'announcementId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnouncementDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnnouncementDelete copyWith(void Function(AnnouncementDelete) updates) =>
      super.copyWith((message) => updates(message as AnnouncementDelete))
          as AnnouncementDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnnouncementDelete create() => AnnouncementDelete._();
  @$core.override
  AnnouncementDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AnnouncementDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnnouncementDelete>(create);
  static AnnouncementDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get feedId => $_getSZ(1);
  @$pb.TagNumber(2)
  set feedId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFeedId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeedId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get announcementId => $_getSZ(2);
  @$pb.TagNumber(3)
  set announcementId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAnnouncementId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAnnouncementId() => $_clearField(3);
}

class FeedCreate extends $pb.GeneratedMessage {
  factory FeedCreate({
    $core.String? serverId,
    $0.Feed? feed,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (feed != null) result.feed = feed;
    return result;
  }

  FeedCreate._();

  factory FeedCreate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FeedCreate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeedCreate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOM<$0.Feed>(2, _omitFieldNames ? '' : 'feed', subBuilder: $0.Feed.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedCreate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedCreate copyWith(void Function(FeedCreate) updates) =>
      super.copyWith((message) => updates(message as FeedCreate)) as FeedCreate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeedCreate create() => FeedCreate._();
  @$core.override
  FeedCreate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FeedCreate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FeedCreate>(create);
  static FeedCreate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Feed get feed => $_getN(1);
  @$pb.TagNumber(2)
  set feed($0.Feed value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFeed() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeed() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Feed ensureFeed() => $_ensure(1);
}

class FeedUpdate extends $pb.GeneratedMessage {
  factory FeedUpdate({
    $core.String? serverId,
    $0.Feed? feed,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (feed != null) result.feed = feed;
    return result;
  }

  FeedUpdate._();

  factory FeedUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FeedUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeedUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOM<$0.Feed>(2, _omitFieldNames ? '' : 'feed', subBuilder: $0.Feed.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedUpdate copyWith(void Function(FeedUpdate) updates) =>
      super.copyWith((message) => updates(message as FeedUpdate)) as FeedUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeedUpdate create() => FeedUpdate._();
  @$core.override
  FeedUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FeedUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FeedUpdate>(create);
  static FeedUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Feed get feed => $_getN(1);
  @$pb.TagNumber(2)
  set feed($0.Feed value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFeed() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeed() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Feed ensureFeed() => $_ensure(1);
}

class FeedDelete extends $pb.GeneratedMessage {
  factory FeedDelete({
    $core.String? serverId,
    $core.String? feedId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (feedId != null) result.feedId = feedId;
    return result;
  }

  FeedDelete._();

  factory FeedDelete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FeedDelete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FeedDelete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'feedId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedDelete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FeedDelete copyWith(void Function(FeedDelete) updates) =>
      super.copyWith((message) => updates(message as FeedDelete)) as FeedDelete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FeedDelete create() => FeedDelete._();
  @$core.override
  FeedDelete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FeedDelete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FeedDelete>(create);
  static FeedDelete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get feedId => $_getSZ(1);
  @$pb.TagNumber(2)
  set feedId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFeedId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeedId() => $_clearField(2);
}

class ClientFocusServer extends $pb.GeneratedMessage {
  factory ClientFocusServer({
    $core.String? serverId,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  ClientFocusServer._();

  factory ClientFocusServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientFocusServer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientFocusServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientFocusServer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientFocusServer copyWith(void Function(ClientFocusServer) updates) =>
      super.copyWith((message) => updates(message as ClientFocusServer))
          as ClientFocusServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientFocusServer create() => ClientFocusServer._();
  @$core.override
  ClientFocusServer createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientFocusServer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientFocusServer>(create);
  static ClientFocusServer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);
}

class ClientFocusChannel extends $pb.GeneratedMessage {
  factory ClientFocusChannel({
    $core.String? channelId,
  }) {
    final result = create();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ClientFocusChannel._();

  factory ClientFocusChannel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientFocusChannel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientFocusChannel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientFocusChannel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientFocusChannel copyWith(void Function(ClientFocusChannel) updates) =>
      super.copyWith((message) => updates(message as ClientFocusChannel))
          as ClientFocusChannel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientFocusChannel create() => ClientFocusChannel._();
  @$core.override
  ClientFocusChannel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientFocusChannel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientFocusChannel>(create);
  static ClientFocusChannel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

class ClientRequestMembers extends $pb.GeneratedMessage {
  factory ClientRequestMembers({
    $core.String? serverId,
    $core.String? query,
    $core.int? limit,
  }) {
    final result = create();
    if (serverId != null) result.serverId = serverId;
    if (query != null) result.query = query;
    if (limit != null) result.limit = limit;
    return result;
  }

  ClientRequestMembers._();

  factory ClientRequestMembers.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientRequestMembers.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientRequestMembers',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOS(2, _omitFieldNames ? '' : 'query')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientRequestMembers clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientRequestMembers copyWith(void Function(ClientRequestMembers) updates) =>
      super.copyWith((message) => updates(message as ClientRequestMembers))
          as ClientRequestMembers;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientRequestMembers create() => ClientRequestMembers._();
  @$core.override
  ClientRequestMembers createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientRequestMembers getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientRequestMembers>(create);
  static ClientRequestMembers? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class Ping extends $pb.GeneratedMessage {
  factory Ping() => create();

  Ping._();

  factory Ping.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Ping.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ping',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ping clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ping copyWith(void Function(Ping) updates) =>
      super.copyWith((message) => updates(message as Ping)) as Ping;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Ping create() => Ping._();
  @$core.override
  Ping createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Ping getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ping>(create);
  static Ping? _defaultInstance;
}

class Pong extends $pb.GeneratedMessage {
  factory Pong() => create();

  Pong._();

  factory Pong.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Pong.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Pong',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pong clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pong copyWith(void Function(Pong) updates) =>
      super.copyWith((message) => updates(message as Pong)) as Pong;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Pong create() => Pong._();
  @$core.override
  Pong createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Pong getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Pong>(create);
  static Pong? _defaultInstance;
}

/// ═══════════════════════════════════════════════════════════════════════
/// Batch envelope — packs multiple WsMessage frames into a single frame
/// so the server can send N coalesced events with one WebSocket write.
///
/// Clients must advertise `capabilities.batch_frames = true` in IDENTIFY
/// to opt in. Servers fall back to individual frames for legacy clients.
///
/// Unpacking: on receipt, iterate `messages` in order and dispatch each
/// as if it had arrived on its own — ordering is preserved.
/// ═══════════════════════════════════════════════════════════════════════
class Batch extends $pb.GeneratedMessage {
  factory Batch({
    $core.Iterable<WsMessage>? messages,
  }) {
    final result = create();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  Batch._();

  factory Batch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Batch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Batch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..pPM<WsMessage>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: WsMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Batch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Batch copyWith(void Function(Batch) updates) =>
      super.copyWith((message) => updates(message as Batch)) as Batch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Batch create() => Batch._();
  @$core.override
  Batch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Batch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Batch>(create);
  static Batch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<WsMessage> get messages => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
