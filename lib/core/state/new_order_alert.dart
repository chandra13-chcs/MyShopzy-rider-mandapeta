import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'new_order_vibration_stub.dart'
    if (dart.library.js_interop) 'new_order_vibration_web.dart'
    as browser_vibration;

class NewOrderAlert {
  NewOrderAlert({
    this.alertDuration = const Duration(seconds: 30),
    this.requireUserGestureForSound = kIsWeb,
    Future<void> Function()? playSound,
    this.stopSound,
    Future<void> Function()? vibrate,
  }) : _player = playSound == null ? AudioPlayer() : null,
       _playSound = playSound,
       _vibrate = vibrate ?? _vibrateForNewOrder,
       _soundActivated = !requireUserGestureForSound {
    _playerReady = _preparePlayer();
    _completionSubscription = _player?.onPlayerComplete.listen((_) {
      final orderId = _orderId;
      if (orderId != null) _playbackCompleted(orderId, _generation);
    });
  }

  static const _asset = 'sounds/rider_alert.mpeg';

  final Duration alertDuration;
  final bool requireUserGestureForSound;
  final AudioPlayer? _player;
  final Future<void> Function()? _playSound;
  final Future<void> Function() _vibrate;
  final Future<void> Function()? stopSound;
  final Set<String> _alertedOfferIds = {};
  Timer? _windowTimer;
  Timer? _vibrationTimer;
  String? _orderId;
  bool _isPlaying = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundActivated;
  int _generation = 0;
  late final Future<void> _playerReady;
  Future<void> _playerOperations = Future<void>.value();
  late final StreamSubscription<void>? _completionSubscription;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get soundNeedsActivation =>
      _soundEnabled && requireUserGestureForSound && !_soundActivated;

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
    if (_vibrationEnabled) {
      unawaited(_vibrateSafely());
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        unawaited(_vibrateSafely());
      });
    }

    if (!_soundEnabled || soundNeedsActivation) return;
    if (shouldStopPrevious) {
      unawaited(_stopThenPlay(orderId, generation));
    } else {
      unawaited(_playFor(orderId, generation));
    }
  }

  void enableSound() {
    if (!soundNeedsActivation) return;
    _soundActivated = true;
    final orderId = _orderId;
    final player = _player;
    if (orderId == null) return;

    final generation = _generation;
    if (player == null) {
      _isPlaying = false;
      unawaited(_playFor(orderId, generation));
      unawaited(_vibrateSafely());
      return;
    }

    _isPlaying = true;
    unawaited(_resumeFromUserGesture(player, orderId, generation));
    unawaited(_vibrateSafely());
  }

  void setSoundEnabled(bool enabled) {
    if (_soundEnabled == enabled) return;
    _soundEnabled = enabled;
    if (!enabled) {
      _isPlaying = false;
      unawaited(_stopPlayback());
      return;
    }

    final orderId = _orderId;
    if (orderId == null || soundNeedsActivation) return;
    final generation = _generation;
    final player = _player;
    if (player != null && requireUserGestureForSound) {
      _soundActivated = true;
      _isPlaying = true;
      unawaited(_resumeFromUserGesture(player, orderId, generation));
    } else {
      unawaited(_playFor(orderId, generation));
    }
  }

  void setVibrationEnabled(bool enabled) {
    if (_vibrationEnabled == enabled) return;
    _vibrationEnabled = enabled;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    if (enabled && _orderId != null) {
      unawaited(_vibrateSafely());
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        unawaited(_vibrateSafely());
      });
    }
  }

  Future<void> _preparePlayer() async {
    final player = _player;
    if (player == null) return;
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.alarm,
              audioFocus: AndroidAudioFocus.gain,
              stayAwake: true,
            ),
          ),
        );
      }
      await player.setSourceAsset(_asset, mimeType: 'audio/mpeg');
    } on Exception catch (error) {
      debugPrint('Unable to prepare the incoming-order alert: $error');
    }
  }

  Future<void> _resumeFromUserGesture(
    AudioPlayer player,
    String orderId,
    int generation,
  ) async {
    try {
      await player.resume();
      if (generation != _generation || _orderId != orderId) {
        await player.stop();
      }
    } on Exception catch (error) {
      debugPrint('Unable to start the incoming-order alert: $error');
      if (generation == _generation) _isPlaying = false;
    }
  }

  Future<void> _stopThenPlay(String orderId, int generation) async {
    await _stopPlayback();
    if (generation != _generation || _orderId != orderId) return;
    await _playFor(orderId, generation);
  }

  Future<void> _playFor(String orderId, int generation) async {
    if (!_soundEnabled ||
        _orderId != orderId ||
        generation != _generation ||
        _isPlaying) {
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
        await _playerReady;
        if (generation != _generation || _orderId != orderId) return;
        await player.resume();
      });
    } on Exception catch (error) {
      debugPrint('Unable to play the incoming-order alert: $error');
      if (generation == _generation) _isPlaying = false;
    }
  }

  void _playbackCompleted(String orderId, int generation) {
    if (!_soundEnabled ||
        generation != _generation ||
        _orderId != orderId ||
        !_isPlaying) {
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

  static Future<void> _vibrateForNewOrder() async {
    if (kIsWeb) {
      browser_vibration.vibrate();
      return;
    }
    await HapticFeedback.heavyImpact();
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
