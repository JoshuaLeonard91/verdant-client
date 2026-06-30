import '../auth/auth_models.dart';
import 'direct_messages_workspace/direct_messages_models.dart';
import 'server_settings_workspace/server_settings_models.dart';
import 'shared/workspace_entitlements.dart';
import 'workspace_seed.dart';

final class WorkspaceState {
  const WorkspaceState({
    this.isLoading = true,
    this.error,
    this.isAuthExpired = false,
    this.servers = const [],
    this.activeServer,
    this.settings,
    this.currentUser,
    this.currentUserMedia,
    this.activeChannelId,
    this.activeFeedId,
    this.pendingChannelId,
    this.isChannelTransitionLoading = false,
    this.activeChannelMembers = const [],
    this.activeTypingMembers = const [],
    this.hasChannelActivityData = false,
    this.isChannelActivityLoading = false,
    this.serverMessages = const [],
    this.isServerMessagesLoading = false,
    this.isLoadingOlderServerMessages = false,
    this.hasMoreServerMessages = false,
    this.serverMessagesError,
    this.directMessages,
    this.entitlements = const WorkspaceEntitlements.disabled(),
    this.activeDmConversation,
    this.dmMessages,
    this.isDmMessagesLoading = false,
    this.isLoadingOlderDmMessages = false,
    this.hasMoreDmMessages = false,
    this.dmMessagesError,
  });

  final bool isLoading;
  final String? error;
  final bool isAuthExpired;
  final List<ServerSettingsServer> servers;
  final ServerSettingsServer? activeServer;
  final ServerSettingsData? settings;
  final VerdantUser? currentUser;
  final ServerSettingsCurrentUserMedia? currentUserMedia;
  final String? activeChannelId;
  final String? activeFeedId;
  final String? pendingChannelId;
  final bool isChannelTransitionLoading;
  final List<MemberSeed> activeChannelMembers;
  final List<MemberSeed> activeTypingMembers;
  final bool hasChannelActivityData;
  final bool isChannelActivityLoading;
  final List<MessageSeed> serverMessages;
  final bool isServerMessagesLoading;
  final bool isLoadingOlderServerMessages;
  final bool hasMoreServerMessages;
  final String? serverMessagesError;
  final DirectMessagesWorkspaceData? directMessages;
  final WorkspaceEntitlements entitlements;
  final DmConversationPreviewSeed? activeDmConversation;
  final DmConversationMessages? dmMessages;
  final bool isDmMessagesLoading;
  final bool isLoadingOlderDmMessages;
  final bool hasMoreDmMessages;
  final String? dmMessagesError;

  WorkspaceState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    bool? isAuthExpired,
    List<ServerSettingsServer>? servers,
    Object? activeServer = _sentinel,
    Object? settings = _sentinel,
    Object? currentUser = _sentinel,
    Object? currentUserMedia = _sentinel,
    Object? activeChannelId = _sentinel,
    Object? activeFeedId = _sentinel,
    Object? pendingChannelId = _sentinel,
    bool? isChannelTransitionLoading,
    List<MemberSeed>? activeChannelMembers,
    List<MemberSeed>? activeTypingMembers,
    bool? hasChannelActivityData,
    bool? isChannelActivityLoading,
    List<MessageSeed>? serverMessages,
    bool? isServerMessagesLoading,
    bool? isLoadingOlderServerMessages,
    bool? hasMoreServerMessages,
    Object? serverMessagesError = _sentinel,
    Object? directMessages = _sentinel,
    WorkspaceEntitlements? entitlements,
    Object? activeDmConversation = _sentinel,
    Object? dmMessages = _sentinel,
    bool? isDmMessagesLoading,
    bool? isLoadingOlderDmMessages,
    bool? hasMoreDmMessages,
    Object? dmMessagesError = _sentinel,
  }) {
    return WorkspaceState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      isAuthExpired: isAuthExpired ?? this.isAuthExpired,
      servers: servers ?? this.servers,
      activeServer: identical(activeServer, _sentinel)
          ? this.activeServer
          : activeServer as ServerSettingsServer?,
      settings: identical(settings, _sentinel)
          ? this.settings
          : settings as ServerSettingsData?,
      currentUser: identical(currentUser, _sentinel)
          ? this.currentUser
          : currentUser as VerdantUser?,
      currentUserMedia: identical(currentUserMedia, _sentinel)
          ? this.currentUserMedia
          : currentUserMedia as ServerSettingsCurrentUserMedia?,
      activeChannelId: identical(activeChannelId, _sentinel)
          ? this.activeChannelId
          : activeChannelId as String?,
      activeFeedId: identical(activeFeedId, _sentinel)
          ? this.activeFeedId
          : activeFeedId as String?,
      pendingChannelId: identical(pendingChannelId, _sentinel)
          ? this.pendingChannelId
          : pendingChannelId as String?,
      isChannelTransitionLoading:
          isChannelTransitionLoading ?? this.isChannelTransitionLoading,
      activeChannelMembers: activeChannelMembers ?? this.activeChannelMembers,
      activeTypingMembers: activeTypingMembers ?? this.activeTypingMembers,
      hasChannelActivityData:
          hasChannelActivityData ?? this.hasChannelActivityData,
      isChannelActivityLoading:
          isChannelActivityLoading ?? this.isChannelActivityLoading,
      serverMessages: serverMessages ?? this.serverMessages,
      isServerMessagesLoading:
          isServerMessagesLoading ?? this.isServerMessagesLoading,
      isLoadingOlderServerMessages:
          isLoadingOlderServerMessages ?? this.isLoadingOlderServerMessages,
      hasMoreServerMessages:
          hasMoreServerMessages ?? this.hasMoreServerMessages,
      serverMessagesError: identical(serverMessagesError, _sentinel)
          ? this.serverMessagesError
          : serverMessagesError as String?,
      directMessages: identical(directMessages, _sentinel)
          ? this.directMessages
          : directMessages as DirectMessagesWorkspaceData?,
      entitlements: entitlements ?? this.entitlements,
      activeDmConversation: identical(activeDmConversation, _sentinel)
          ? this.activeDmConversation
          : activeDmConversation as DmConversationPreviewSeed?,
      dmMessages: identical(dmMessages, _sentinel)
          ? this.dmMessages
          : dmMessages as DmConversationMessages?,
      isDmMessagesLoading: isDmMessagesLoading ?? this.isDmMessagesLoading,
      isLoadingOlderDmMessages:
          isLoadingOlderDmMessages ?? this.isLoadingOlderDmMessages,
      hasMoreDmMessages: hasMoreDmMessages ?? this.hasMoreDmMessages,
      dmMessagesError: identical(dmMessagesError, _sentinel)
          ? this.dmMessagesError
          : dmMessagesError as String?,
    );
  }
}

const Object _sentinel = Object();
