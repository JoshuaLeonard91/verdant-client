abstract interface class WorkspaceMessageMutationRepository {
  Future<void> deleteChannelMessage({
    required String channelId,
    required String messageId,
  });
}
