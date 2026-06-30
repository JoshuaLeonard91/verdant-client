import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../app/client_version.dart';
import '../../auth/auth_diagnostics.dart';
import 'server_media_url_policy.dart';

typedef ServerMediaAddressResolver =
    Future<List<InternetAddress>> Function(String host);
typedef ServerMediaSocketConnector =
    Future<ConnectionTask<Socket>> Function(
      InternetAddress address,
      String host,
      int port,
      bool secure,
      Duration timeout,
    );

var _serverMediaHttpRequestSequence = 0;
var _serverMediaHttpOpenInFlight = 0;

final class ServerMediaLoadException implements Exception {
  const ServerMediaLoadException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

final class ServerMediaLoader {
  ServerMediaLoader({
    HttpClient Function()? httpClientFactory,
    ServerMediaAddressResolver? addressResolver,
    ServerMediaSocketConnector? socketConnector,
    this.maxBytes = 10 * 1024 * 1024,
    this.timeout = const Duration(seconds: 15),
    this.validateResolvedAddresses = true,
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new,
       _addressResolver = addressResolver ?? InternetAddress.lookup,
       _socketConnector = socketConnector ?? _defaultSocketConnector;

  final HttpClient Function() _httpClientFactory;
  final ServerMediaAddressResolver _addressResolver;
  final ServerMediaSocketConnector _socketConnector;
  final int maxBytes;
  final Duration timeout;
  final bool validateResolvedAddresses;
  final _clientsByPolicy = <ServerMediaPolicy, HttpClient>{};

  Future<Uint8List> load(
    Uri uri, {
    required ServerMediaPolicy policy,
    int? maxBytes,
  }) async {
    final safeUri = safeServerMediaUri(uri.toString(), policy: policy);
    if (safeUri == null) {
      throw const ServerMediaLoadException('Media URL is not allowed');
    }

    try {
      return await _loadWithClient(
        _clientForPolicy(policy),
        safeUri,
        policy,
        maxBytes ?? this.maxBytes,
      ).timeout(timeout);
    } on ServerMediaLoadException {
      rethrow;
    } on TimeoutException {
      _discardClientForPolicy(policy);
      throw const ServerMediaLoadException('Media request timed out');
    } on HandshakeException {
      _discardClientForPolicy(policy);
      throw const ServerMediaLoadException('Media TLS handshake failed');
    } on SocketException {
      _discardClientForPolicy(policy);
      throw const ServerMediaLoadException('Media connection failed');
    } on HttpException {
      _discardClientForPolicy(policy);
      throw const ServerMediaLoadException('Media request failed');
    }
  }

  HttpClient _clientForPolicy(ServerMediaPolicy policy) {
    return _clientsByPolicy.putIfAbsent(policy, () {
      final client = _httpClientFactory();
      client.findProxy = (_) => 'DIRECT';
      if (validateResolvedAddresses) {
        client.connectionFactory = (uri, proxyHost, proxyPort) {
          return _openValidatedConnection(uri, proxyHost, proxyPort, policy);
        };
      }
      return client;
    });
  }

  void _discardClientForPolicy(ServerMediaPolicy policy) {
    final client = _clientsByPolicy.remove(policy);
    client?.close(force: true);
  }

  Future<Uint8List> _loadWithClient(
    HttpClient httpClient,
    Uri safeUri,
    ServerMediaPolicy policy,
    int maxBytes,
  ) async {
    var currentUri = safeUri;
    for (var redirectCount = 0; redirectCount <= 4; redirectCount += 1) {
      final response = await _openResponse(httpClient, currentUri);
      if (_isRedirectResponse(response)) {
        if (redirectCount == 4) {
          await response.drain<void>();
          throw const ServerMediaLoadException('Media redirect limit exceeded');
        }
        final nextUri = _safeRedirectUri(response, currentUri, policy);
        await response.drain<void>();
        if (nextUri == null) {
          throw const ServerMediaLoadException(
            'Media redirect URL is not allowed',
          );
        }
        currentUri = nextUri;
        continue;
      }
      return _readValidatedResponse(response, maxBytes);
    }

    throw const ServerMediaLoadException('Media redirect limit exceeded');
  }

  Future<HttpClientResponse> _openResponse(
    HttpClient httpClient,
    Uri safeUri,
  ) async {
    final requestId = ++_serverMediaHttpRequestSequence;
    final startedAt = DateTime.now();
    _serverMediaHttpOpenInFlight += 1;
    _recordServerMediaHttpDiagnostic(
      'request',
      safeUri,
      extra: {
        'requestId': requestId,
        'openInFlight': _serverMediaHttpOpenInFlight,
      },
    );
    try {
      final request = await httpClient.getUrl(safeUri).timeout(timeout);
      request.followRedirects = false;
      request.headers.set(
        HttpHeaders.acceptHeader,
        'image/png,image/jpeg,image/gif,image/webp',
      );
      request.headers.set(HttpHeaders.userAgentHeader, verdantFlutterUserAgent);
      final referer = _officialMediaReferer(safeUri);
      if (referer != null) {
        request.headers.set(HttpHeaders.refererHeader, referer);
      }
      final response = await request.close().timeout(timeout);
      _recordServerMediaHttpDiagnostic(
        'response',
        safeUri,
        statusCode: response.statusCode,
        elapsed: DateTime.now().difference(startedAt),
        extra: {
          'requestId': requestId,
          'openInFlight': _serverMediaHttpOpenInFlight,
          ..._responseHeaderDiagnostics(response),
        },
      );
      return response;
    } catch (error) {
      _recordServerMediaHttpDiagnostic(
        'error',
        safeUri,
        reason: _serverMediaHttpFailureReason(error),
        elapsed: DateTime.now().difference(startedAt),
        extra: {
          'requestId': requestId,
          'openInFlight': _serverMediaHttpOpenInFlight,
        },
      );
      rethrow;
    } finally {
      if (_serverMediaHttpOpenInFlight > 0) {
        _serverMediaHttpOpenInFlight -= 1;
      }
    }
  }

  Future<Uint8List> _readValidatedResponse(
    HttpClientResponse response,
    int maxBytes,
  ) async {
    if (response.statusCode >= 300) {
      throw ServerMediaLoadException(
        'Media request failed: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode != HttpStatus.ok) {
      throw ServerMediaLoadException(
        'Media request failed: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    if (response.contentLength > maxBytes) {
      throw const ServerMediaLoadException('Media response is too large');
    }
    if (!_isPassiveRasterContentType(response.headers.contentType)) {
      throw const ServerMediaLoadException('Media content type is not allowed');
    }

    final builder = BytesBuilder(copy: false);
    var received = 0;
    await for (final chunk in response.timeout(timeout)) {
      received += chunk.length;
      if (received > maxBytes) {
        throw const ServerMediaLoadException('Media response is too large');
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (!_hasPassiveRasterSignature(bytes)) {
      throw const ServerMediaLoadException('Media bytes are not an image');
    }
    return bytes;
  }

  Future<ConnectionTask<Socket>> _openValidatedConnection(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
    ServerMediaPolicy policy,
  ) async {
    if (proxyHost != null || proxyPort != null) {
      throw const ServerMediaLoadException('Media proxies are not allowed');
    }
    final safeUri = safeServerMediaUri(uri.toString(), policy: policy);
    if (safeUri == null) {
      throw const ServerMediaLoadException('Media URL is not allowed');
    }

    final addresses = await _addressResolver(
      safeUri.host,
    ).timeout(const Duration(seconds: 5));
    if (addresses.isEmpty) {
      throw const ServerMediaLoadException('Media host did not resolve');
    }
    for (final address in addresses) {
      if (!_isAllowedAddress(address, safeUri, policy)) {
        throw const ServerMediaLoadException(
          'Media host resolved to a private address',
        );
      }
    }
    return _connectToFirstAvailableAddress(
      _prioritizedAddresses(addresses),
      safeUri.host,
      safeUri.port,
      safeUri.scheme == 'https',
      timeout,
    );
  }

  Future<ConnectionTask<Socket>> _connectToFirstAvailableAddress(
    List<InternetAddress> addresses,
    String host,
    int port,
    bool secure,
    Duration timeout,
  ) async {
    if (addresses.length == 1) {
      return _socketConnector(addresses.first, host, port, secure, timeout);
    }

    const fallbackDelay = Duration(milliseconds: 75);
    final socketCompleter = Completer<Socket>();
    final startedTasks = <ConnectionTask<Socket>>[];
    var cancelled = false;
    var remainingAttempts = addresses.length;
    Object? lastError;
    StackTrace? lastStackTrace;

    void failAttempt(Object error, StackTrace stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      remainingAttempts -= 1;
      if (remainingAttempts <= 0 && !socketCompleter.isCompleted) {
        socketCompleter.completeError(lastError!, lastStackTrace);
      }
    }

    for (var index = 0; index < addresses.length; index += 1) {
      final address = addresses[index];
      unawaited(() async {
        if (index > 0) {
          await Future<void>.delayed(fallbackDelay * index);
        }
        if (cancelled || socketCompleter.isCompleted) {
          return;
        }

        ConnectionTask<Socket>? task;
        try {
          task = await _socketConnector(address, host, port, secure, timeout);
          startedTasks.add(task);
          final socket = await task.socket;
          if (cancelled || socketCompleter.isCompleted) {
            socket.destroy();
            return;
          }
          socketCompleter.complete(socket);
          for (final startedTask in startedTasks) {
            if (!identical(startedTask, task)) {
              startedTask.cancel();
            }
          }
        } catch (error, stackTrace) {
          failAttempt(error, stackTrace);
        }
      }());
    }

    void cancelAll() {
      cancelled = true;
      for (final task in startedTasks) {
        task.cancel();
      }
    }

    return ConnectionTask.fromSocket(
      socketCompleter.future.timeout(timeout),
      cancelAll,
    );
  }

  void close() {
    for (final client in _clientsByPolicy.values) {
      client.close(force: true);
    }
    _clientsByPolicy.clear();
  }
}

bool _isRedirectResponse(HttpClientResponse response) {
  return response.isRedirect ||
      response.statusCode >= 300 && response.statusCode < 400;
}

void _recordServerMediaHttpDiagnostic(
  String event,
  Uri uri, {
  int? statusCode,
  String? reason,
  Duration? elapsed,
  Map<String, Object?> extra = const {},
}) {
  if (!verdantClientDiagnosticsEnabled) {
    return;
  }
  final fields = <String, Object?>{
    'origin': _mediaOriginForDiagnostic(uri),
    'pathRoot': _mediaPathRootForDiagnostic(uri),
    'extension': _mediaExtensionForDiagnostic(uri),
    'secure': uri.scheme == 'https',
  };
  if (verdantClientMediaUrlDiagnosticsEnabled) {
    fields['url'] = uri.toString();
  }
  if (statusCode != null) {
    fields['status'] = statusCode;
  }
  if (reason != null) {
    fields['reason'] = reason;
  }
  if (elapsed != null) {
    fields['ms'] = elapsed.inMilliseconds;
  }
  fields.addAll(extra);
  debugPrint(
    'verdant.media.http $event ${sanitizeAuthDiagnosticFields(fields)}',
  );
}

Map<String, Object?> _responseHeaderDiagnostics(HttpClientResponse response) {
  final fields = <String, Object?>{'redirect': _isRedirectResponse(response)};
  if (response.contentLength >= 0) {
    fields['contentLength'] = response.contentLength;
  }
  final contentType = response.headers.contentType;
  if (contentType != null) {
    fields['contentType'] = contentType.toString();
  }
  void addHeader(String field, String header) {
    final value = response.headers.value(header);
    if (value == null || value.trim().isEmpty) {
      return;
    }
    fields[field] = _shortMediaHeaderValue(value);
  }

  addHeader('retryAfter', 'retry-after');
  addHeader('rateLimitLimit', 'ratelimit-limit');
  addHeader('rateLimitRemaining', 'ratelimit-remaining');
  addHeader('rateLimitReset', 'ratelimit-reset');
  addHeader('xRateLimitLimit', 'x-ratelimit-limit');
  addHeader('xRateLimitRemaining', 'x-ratelimit-remaining');
  addHeader('xRateLimitReset', 'x-ratelimit-reset');
  addHeader('cfCacheStatus', 'cf-cache-status');
  addHeader('cacheStatus', 'cache-status');
  addHeader('xCache', 'x-cache');
  addHeader('age', 'age');
  return fields;
}

String _serverMediaHttpFailureReason(Object error) {
  if (error is ServerMediaLoadException) {
    return error.statusCode == null
        ? error.message
        : '${error.message} (${error.statusCode})';
  }
  if (error is TimeoutException) {
    return 'timeout';
  }
  if (error is HandshakeException) {
    return 'tlsHandshake';
  }
  if (error is SocketException) {
    return 'socket';
  }
  if (error is HttpException) {
    return 'http';
  }
  return error.runtimeType.toString();
}

String _mediaOriginForDiagnostic(Uri uri) {
  final defaultPort = uri.scheme == 'https'
      ? HttpClient.defaultHttpsPort
      : HttpClient.defaultHttpPort;
  final port = uri.hasPort && uri.port != defaultPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port';
}

String _mediaPathRootForDiagnostic(Uri uri) {
  for (final segment in uri.pathSegments) {
    if (segment.trim().isNotEmpty) {
      return segment;
    }
  }
  return '/';
}

String _mediaExtensionForDiagnostic(Uri uri) {
  if (uri.pathSegments.isEmpty) {
    return '';
  }
  final filename = uri.pathSegments.last;
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == filename.length - 1) {
    return '';
  }
  return filename.substring(dotIndex + 1).toLowerCase();
}

String _shortMediaHeaderValue(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 80) {
    return trimmed;
  }
  return '${trimmed.substring(0, 77)}...';
}

Uri? _safeRedirectUri(
  HttpClientResponse response,
  Uri currentUri,
  ServerMediaPolicy policy,
) {
  final location = response.headers.value(HttpHeaders.locationHeader);
  if (location == null || location.trim().isEmpty) {
    return null;
  }
  final resolved = currentUri.resolve(location);
  return safeServerMediaUri(resolved.toString(), policy: policy);
}

String? _officialMediaReferer(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host == 'cdn.pryzmapp.com' || host == 'pryzmapp.com') {
    return 'https://pryzmapp.com/';
  }
  if (host == 'cdn.verdant.chat' ||
      host == 'media.verdant.chat' ||
      host == 'verdant.chat') {
    return 'https://verdant.chat/';
  }
  return null;
}

bool _isPassiveRasterContentType(ContentType? contentType) {
  if (contentType == null) {
    return true;
  }
  final type = contentType.primaryType.toLowerCase();
  final subType = contentType.subType.toLowerCase();
  if (type != 'image') {
    return false;
  }
  return subType == 'png' ||
      subType == 'jpeg' ||
      subType == 'jpg' ||
      subType == 'gif' ||
      subType == 'webp';
}

bool _hasPassiveRasterSignature(Uint8List bytes) {
  return _hasPrefix(bytes, const [0x89, 0x50, 0x4E, 0x47]) ||
      _hasPrefix(bytes, const [0xFF, 0xD8, 0xFF]) ||
      _hasPrefix(bytes, const [0x47, 0x49, 0x46, 0x38]) ||
      _hasWebpSignature(bytes);
}

bool _hasPrefix(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) {
    return false;
  }
  for (var index = 0; index < prefix.length; index += 1) {
    if (bytes[index] != prefix[index]) {
      return false;
    }
  }
  return true;
}

bool _hasWebpSignature(Uint8List bytes) {
  if (bytes.length < 12) {
    return false;
  }
  return _asciiAt(bytes, 0, 'RIFF') && _asciiAt(bytes, 8, 'WEBP');
}

bool _asciiAt(Uint8List bytes, int offset, String value) {
  for (var index = 0; index < value.length; index += 1) {
    if (bytes[offset + index] != value.codeUnitAt(index)) {
      return false;
    }
  }
  return true;
}

Future<ConnectionTask<Socket>> _defaultSocketConnector(
  InternetAddress address,
  String host,
  int port,
  bool secure,
  Duration timeout,
) async {
  final task = await Socket.startConnect(address, port).timeout(timeout);
  Socket? activeSocket;
  var cancelled = false;

  Future<Socket> socketFuture = task.socket
      .timeout(timeout)
      .then<Socket>((socket) async {
        activeSocket = socket;
        if (cancelled) {
          socket.destroy();
          throw const SocketException('Media connection cancelled');
        }
        if (!secure) {
          return socket;
        }
        final secureSocket = await SecureSocket.secure(
          socket,
          host: host,
          supportedProtocols: const ['http/1.1'],
        ).timeout(timeout);
        activeSocket = secureSocket;
        if (cancelled) {
          secureSocket.destroy();
          throw const SocketException('Media connection cancelled');
        }
        return secureSocket;
      })
      .timeout(timeout);

  void cancel() {
    cancelled = true;
    task.cancel();
    activeSocket?.destroy();
  }

  return ConnectionTask.fromSocket(socketFuture, cancel);
}

List<InternetAddress> _prioritizedAddresses(List<InternetAddress> addresses) {
  return [
    for (final address in addresses)
      if (address.type == InternetAddressType.IPv4) address,
    for (final address in addresses)
      if (address.type != InternetAddressType.IPv4) address,
  ];
}

bool _isAllowedAddress(
  InternetAddress address,
  Uri uri,
  ServerMediaPolicy policy,
) {
  if (policy.allowLocalHttp && uri.scheme == 'http') {
    return address.isLoopback;
  }
  return !_isDisallowedAddress(address);
}

bool _isDisallowedAddress(InternetAddress address) {
  if (address.isLoopback || address.isLinkLocal) {
    return true;
  }
  final raw = address.rawAddress;
  if (address.type == InternetAddressType.IPv4 && raw.length == 4) {
    return _isDisallowedIpv4(raw[0], raw[1], raw[2]);
  }
  if (address.type == InternetAddressType.IPv6 && raw.length == 16) {
    final mapped = _ipv4MappedBytes(raw);
    if (mapped != null) {
      return _isDisallowedIpv4(mapped[0], mapped[1], mapped[2]);
    }
    return raw.every((part) => part == 0) ||
        raw[0] == 0xFC ||
        raw[0] == 0xFD ||
        raw[0] == 0xFE && (raw[1] & 0xC0) == 0x80;
  }
  return true;
}

bool _isDisallowedIpv4(int first, int second, int third) {
  return first == 0 ||
      first == 10 ||
      first == 100 && second >= 64 && second <= 127 ||
      first == 127 ||
      first == 169 && second == 254 ||
      first == 172 && second >= 16 && second <= 31 ||
      first == 192 && second == 0 && second <= 255 ||
      first == 192 && second == 168 ||
      first == 198 && (second == 18 || second == 19) ||
      first == 203 && second == 0 && third == 113 ||
      first >= 224;
}

List<int>? _ipv4MappedBytes(List<int> raw) {
  for (var index = 0; index < 10; index += 1) {
    if (raw[index] != 0) {
      return null;
    }
  }
  if (raw[10] != 0xFF || raw[11] != 0xFF) {
    return null;
  }
  return raw.sublist(12, 16);
}
