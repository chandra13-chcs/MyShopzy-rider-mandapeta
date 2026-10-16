import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NewOrderAlert {
  NewOrderAlert({
    this.alertDuration = const Duration(seconds: 30),
    Future<void> Function()? playSound,
    this.stopSound,
    Future<void> Function()? vibrate,
  }) : _player = playSound == null ? AudioPlayer() : null,
       _playSound = playSound,
       _vibrate = vibrate ?? HapticFeedback.heavyImpact {
    _completionSubscription = _player?.onPlayerComplete.listen((_) {
      final orderId = _orderId;
      if (orderId != null) _playbackCompleted(orderId, _generation);
    });
  }

  static const _asset = 'sounds/rider_alert.mpeg';

  final Duration alertDuration;
  final AudioPlayer? _player;
  final Future<void> Function()? _playSound;
  final Future<void> Function() _vibrate;
  final Future<void> Function()? stopSound;
  final Set<String> _alertedOfferIds = {};
  Timer? _windowTimer;
  Timer? _vibrationTimer;
  String? _orderId;
  bool _isPlaying = false;
  int _generation = 0;
  Future<void> _playerOperations = Future<void>.value();
  late final StreamSubscription<void>? _completionSubscription;

  void start(String orderId) {
    if (_alertedOfferIds.contains(orderId)) return;

    final shouldStopPrevious = _orderId != null || _isPlaying;
    final generation = ++_generation;
    _alertedOfferIds.add(orderId);
    _windowTimer?.cancel();
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _orderId = orderId;
    _isPlaying = false;
    _windowTimer = Timer(alertDuration, () {
      unawaited(stop());
    });
    unawaited(_vibrateSafely());
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_vibrateSafely());
    });

    if (shouldStopPrevious) {
      unawaited(_stopThenPlay(orderId, generation));
    } else {
      unawaited(_playFor(orderId, generation));
    }
  }

  Future<void> _stopThenPlay(String orderId, int generation) async {
    await _stopPlayback();
    if (generation != _generation || _orderId != orderId) return;
    await _playFor(orderId, generation);
  }

  Future<void> _playFor(String orderId, int generation) async {
    if (_orderId != orderId || generation != _generation || _isPlaying) {
      return;
    }

    _isPlaying = true;
    try {
      final playSound = _playSound;
      if (playSound != null) {
        await playSound();
        _playbackCompleted(orderId, generation);
        return;
      }

      final player = _player!;
      await _runPlayerOperation(() async {
        await player.setReleaseMode(ReleaseMode.stop);
        if (generation != _generation || _orderId != orderId) return;
        await player.play(AssetSource(_asset));
      });
    } on Exception catch (error) {
      debugPrint('Unable to play the incoming-order alert: $error');
      if (generation == _generation) _isPlaying = false;
    }
  }

  void _playbackCompleted(String orderId, int generation) {
    if (generation != _generation || _orderId != orderId || !_isPlaying) {
      return;
    }

    _isPlaying = false;
    unawaited(_playFor(orderId, generation));
  }

  Future<void> _stopPlayback() async {
    try {
      final stopSoundCallback = stopSound;
      if (stopSoundCallback != null) {
        await stopSoundCallback();
      } else {
        await _runPlayerOperation(() async {
          await _player?.stop();
        });
      }
    } on Exception catch (error) {
      debugPrint('Unable to stop the incoming-order alert: $error');
    }
  }

  Future<void> _runPlayerOperation(Future<void> Function() operation) {
    final next = _playerOperations.then(
      (_) => operation(),
      onError: (Object _, StackTrace _) => operation(),
    );
    _playerOperations = next;
    return next;
  }

  Future<void> _vibrateSafely() async {
    try {
      await _vibrate();
    } on Exception catch (error) {
      debugPrint('Unable to vibrate for the incoming-order alert: $error');
    }
  }

  Future<void> stop() async {
    final wasActive = _windowTimer != null || _orderId != null || _isPlaying;
    ++_generation;
    _windowTimer?.cancel();
    _windowTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _orderId = null;
    _isPlaying = false;
    if (wasActive) await _stopPlayback();
  }

  Future<void> dispose() async {
    await stop();
    await _completionSubscription?.cancel();
    try {
      await _player?.dispose();
    } on Exception catch (error) {
      debugPrint('Unable to dispose the incoming-order alert: $error');
    }
  }
}
