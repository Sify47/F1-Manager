import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static AudioService get instance => _instance;

  AudioPlayer? _sfxPlayer;
  AudioPlayer? _radioPlayer;
  AudioPlayer? _enginePlayer;

  AudioPlayer? get sfxPlayer {
    try {
      return _sfxPlayer ??= AudioPlayer();
    } catch (_) {
      return null;
    }
  }

  AudioPlayer? get radioPlayer {
    try {
      return _radioPlayer ??= AudioPlayer();
    } catch (_) {
      return null;
    }
  }

  AudioPlayer? get enginePlayer {
    try {
      return _enginePlayer ??= AudioPlayer();
    } catch (_) {
      return null;
    }
  }

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stopAll();
    }
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      stopAll();
    }
  }

  Future<void> playRadioBeep() async {
    if (_isMuted) return;
    try {
      await radioPlayer?.stop();
      await radioPlayer?.play(AssetSource('audio/radio_beep.wav'), volume: 0.7);
    } catch (e) {
      debugPrint('AudioService.playRadioBeep error: $e');
    }
  }

  Future<void> playRadioStatic() async {
    if (_isMuted) return;
    try {
      await radioPlayer?.stop();
      await radioPlayer?.play(AssetSource('audio/radio_static.wav'), volume: 0.5);
    } catch (e) {
      debugPrint('AudioService.playRadioStatic error: $e');
    }
  }

  Future<void> playStartLights() async {
    if (_isMuted) return;
    try {
      await sfxPlayer?.stop();
      await sfxPlayer?.play(AssetSource('audio/start_lights.wav'), volume: 0.8);
    } catch (e) {
      debugPrint('AudioService.playStartLights error: $e');
    }
  }

  Future<void> playPitGun() async {
    if (_isMuted) return;
    try {
      await sfxPlayer?.stop();
      await sfxPlayer?.play(AssetSource('audio/pit_gun.wav'), volume: 0.85);
    } catch (e) {
      debugPrint('AudioService.playPitGun error: $e');
    }
  }

  Future<void> playEngineFlyby() async {
    if (_isMuted) return;
    try {
      await enginePlayer?.stop();
      await enginePlayer?.play(AssetSource('audio/engine_flyby.wav'), volume: 0.6);
    } catch (e) {
      debugPrint('AudioService.playEngineFlyby error: $e');
    }
  }

  Future<void> playBoxConfirm() async {
    if (_isMuted) return;
    try {
      await sfxPlayer?.stop();
      await sfxPlayer?.play(AssetSource('audio/box_confirm.wav'), volume: 0.75);
    } catch (e) {
      debugPrint('AudioService.playBoxConfirm error: $e');
    }
  }

  Future<void> playChequeredFlag() async {
    if (_isMuted) return;
    try {
      await sfxPlayer?.stop();
      await sfxPlayer?.play(AssetSource('audio/chequered_flag.wav'), volume: 0.85);
    } catch (e) {
      debugPrint('AudioService.playChequeredFlag error: $e');
    }
  }

  void stopAll() {
    try {
      _sfxPlayer?.stop();
      _radioPlayer?.stop();
      _enginePlayer?.stop();
    } catch (e) {
      debugPrint('AudioService.stopAll error: $e');
    }
  }

  void dispose() {
    _sfxPlayer?.dispose();
    _radioPlayer?.dispose();
    _enginePlayer?.dispose();
  }
}
