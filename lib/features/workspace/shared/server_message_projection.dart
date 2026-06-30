import '../workspace_seed.dart';

List<MessageSeed> upsertServerMessage(
  List<MessageSeed> messages,
  MessageSeed incoming,
) {
  final incomingKey = serverMessageLocalKey(incoming.id);
  var replaced = false;
  final next = <MessageSeed>[
    for (final message in messages)
      if (serverMessageLocalKey(message.id) == incomingKey)
        () {
          replaced = true;
          return incoming;
        }()
      else
        message,
  ];
  if (!replaced) {
    next.add(incoming);
  }
  return next;
}

List<MessageSeed> replaceServerMessage(
  List<MessageSeed> messages,
  MessageSeed incoming,
) {
  final incomingKey = serverMessageLocalKey(incoming.id);
  return [
    for (final message in messages)
      if (serverMessageLocalKey(message.id) == incomingKey)
        incoming
      else
        message,
  ];
}

List<MessageSeed> removeServerMessage(
  List<MessageSeed> messages,
  String messageId,
) {
  final messageKey = serverMessageLocalKey(messageId);
  return [
    for (final message in messages)
      if (serverMessageLocalKey(message.id) != messageKey) message,
  ];
}

String serverMessageLocalKey(String rawMessageId) {
  final trimmed = rawMessageId.trim();
  final slash = trimmed.indexOf('/');
  if (slash >= 0 && slash < trimmed.length - 1) {
    return trimmed.substring(slash + 1);
  }
  return trimmed;
}
