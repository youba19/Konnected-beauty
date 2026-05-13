import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../config/api_base_url.dart';
import '../models/campaign_chat_message.dart';
import 'storage/token_storage_service.dart';

/// Real-time campaign chat using the same host as [ApiBaseUrl] (Socket.IO).
class CampaignChatSocketService {
  socket_io.Socket? _socket;
  String? _campaignId;

  /// Last time we had a healthy connect or server chat traffic (avoids "zombie" connected=true).
  DateTime? _lastSocketActivityAt;

  /// If the socket sits idle longer than this, [sendMessage] forces a fresh connection.
  static const Duration _idleReconnectThreshold = Duration(seconds: 45);

  /// After this much idle time on an already-connected socket, re-emit [campaign-message:join] before send
  /// (client can still show `connected` while the server dropped the room).
  static const Duration _softRejoinIdleThreshold = Duration(seconds: 10);

  /// Brief pause after a soft re-join so the server can process before [campaign-message:send].
  static const Duration _softRejoinSettle = Duration(milliseconds: 250);

  /// After [campaign-message:join], wait before [connectJoin] completes so the server can attach the socket to the room.
  static const Duration _joinSettleDelay = Duration(milliseconds: 500);

  void Function(CampaignChatMessageItem message)? onMessage;
  void Function(String message)? onError;

  void _markSocketActivity() {
    _lastSocketActivityAt = DateTime.now();
  }

  static String _socketOrigin() {
    final u = Uri.parse(ApiBaseUrl.value);
    final port = u.hasPort ? ':${u.port}' : '';
    return '${u.scheme}://${u.host}$port';
  }

  bool get isConnected => _socket?.connected == true;

  /// Connects and waits until the socket is ready, or until timeout / error.
  ///
  /// Set [forceRefresh] to drop an existing connection (e.g. idle zombie socket).
  ///
  /// Returns `false` if the connection could not be established (also triggers [onError]).
  Future<bool> connectJoin(
    String campaignId, {
    bool forceRefresh = false,
  }) async {
    if (campaignId.isEmpty) return false;
    if (!forceRefresh &&
        _socket?.connected == true &&
        _campaignId == campaignId) {
      return true;
    }

    disconnect();

    final token = await TokenStorageService.getAccessToken();
    if (token == null || token.isEmpty) {
      onError?.call('Not signed in');
      return false;
    }

    _campaignId = campaignId;

    final completer = Completer<bool>();
    Timer? timeoutTimer;

    void completeOk() {
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.complete(true);
      }
    }

    void completeFail() {
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.complete(false);
      }
    }

    timeoutTimer = Timer(const Duration(seconds: 30), () {
      onError?.call('Chat connection timed out');
      completeFail();
    });

    final opts = socket_io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .setExtraHeaders(ApiBaseUrl.mergeRequestHeaders())
        .enableForceNew()
        .enableReconnection()
        .build();

    _socket = socket_io.io(_socketOrigin(), opts);

    void onConnected() {
      _markSocketActivity();
      if (kDebugMode) {
        debugPrint(
          '💬 [CampaignChat] socket connected → join room campaignId=$campaignId',
        );
      }
      _socket!.emit('campaign-message:join', {'campaignId': campaignId});
      Future<void>.delayed(_joinSettleDelay, () {
        if (completer.isCompleted) return;
        if (_socket?.connected == true && _campaignId == campaignId) {
          if (kDebugMode) {
            debugPrint(
              '💬 [CampaignChat] join settle (${_joinSettleDelay.inMilliseconds}ms) → ready',
            );
          }
          completeOk();
        } else {
          if (kDebugMode) {
            debugPrint(
              '💬 [CampaignChat] join settle aborted (socket gone or campaign changed)',
            );
          }
          completeFail();
        }
      });
    }

    _socket!.on('disconnect', (reason) {
      _lastSocketActivityAt = null;
      if (kDebugMode) {
        debugPrint('💬 [CampaignChat] socket disconnect reason=$reason');
      }
    });

    _socket!.on('campaign-message:new', (data) {
      _markSocketActivity();
      if (kDebugMode) {
        debugPrint('💬 [CampaignChat] ← campaign-message:new $data');
      }
      final m = CampaignChatMessageItem.tryParse(data);
      if (m != null) onMessage?.call(m);
    });

    _socket!.on('campaign-message:sent', (data) {
      _markSocketActivity();
      if (kDebugMode) {
        debugPrint('💬 [CampaignChat] ← campaign-message:sent $data');
      }
      final m = CampaignChatMessageItem.tryParse(data);
      if (m != null) {
        onMessage?.call(m);
      } else if (kDebugMode && data is Map) {
        debugPrint(
          '💬 [CampaignChat] campaign-message:sent payload not parsed (check API shape)',
        );
      }
    });

    _socket!.on('campaign-message:error', (data) {
      _markSocketActivity();
      var msg = 'Chat error';
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      } else if (data != null) {
        msg = data.toString();
      }
      onError?.call(msg);
    });

    _socket!.on('connect_error', (err) {
      onError?.call(err?.toString() ?? 'Connection failed');
      completeFail();
    });

    _socket!.on('connect', (_) => onConnected());

    if (_socket!.connected) {
      onConnected();
    }

    return completer.future;
  }

  /// Connects if needed, then emits `campaign-message:send`.
  ///
  /// Does not wait for `campaign-message:sent` (avoids hanging when the server is slow or the client misses the event).
  /// Returns `false` if the message could not be emitted ([onError] may have been called).
  Future<bool> sendMessage(String campaignId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return false;

    final idle = _lastSocketActivityAt == null
        ? Duration.zero
        : DateTime.now().difference(_lastSocketActivityAt!);
    final idleStale = idle > _idleReconnectThreshold;

    final needsConnection = _socket == null ||
        !_socket!.connected ||
        _campaignId != campaignId ||
        idleStale;

    if (kDebugMode) {
      final preview =
          text.length > 120 ? '${text.substring(0, 120)}…' : text;
      debugPrint(
        '💬 [CampaignChat] sendMessage start campaignId=$campaignId '
        'reconnect=$needsConnection idleStale=$idleStale idle=${idle.inSeconds}s '
        'connected=${_socket?.connected} activeCampaign=$_campaignId '
        'len=${text.length} preview="$preview"',
      );
    }

    if (needsConnection) {
      if (kDebugMode) {
        debugPrint(
          '💬 [CampaignChat] reconnecting before send… '
          '(forceRefresh=$idleStale or socket down)',
        );
      }
      final ok = await connectJoin(
        campaignId,
        forceRefresh: idleStale,
      );
      if (!ok) {
        if (kDebugMode) {
          debugPrint('💬 [CampaignChat] send aborted (connectJoin failed)');
        }
        return false;
      }
    }

    if (_socket == null || !_socket!.connected) {
      onError?.call('Not connected to chat');
      if (kDebugMode) {
        debugPrint(
          '💬 [CampaignChat] send aborted (still not connected after join)',
        );
      }
      return false;
    }

    if (!needsConnection &&
        idle > _softRejoinIdleThreshold &&
        _campaignId == campaignId) {
      if (kDebugMode) {
        debugPrint(
          '💬 [CampaignChat] soft re-join before send (idle=${idle.inSeconds}s)',
        );
      }
      _socket!.emit('campaign-message:join', {'campaignId': campaignId});
      await Future<void>.delayed(_softRejoinSettle);
      if (_socket == null || !_socket!.connected) {
        onError?.call('Not connected to chat');
        return false;
      }
    }

    _socket!.emit('campaign-message:send', {
      'campaignId': campaignId,
      'content': text,
    });
    if (kDebugMode) {
      debugPrint(
        '💬 [CampaignChat] → emitted campaign-message:send campaignId=$campaignId '
        'chars=${text.length}',
      );
    }
    return true;
  }

  void disconnect() {
    final id = _campaignId;
    if (_socket != null && id != null) {
      _socket!.emit('campaign-message:leave', {'campaignId': id});
    }
    _socket?.dispose();
    _socket = null;
    _campaignId = null;
    _lastSocketActivityAt = null;
  }
}
