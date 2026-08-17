import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service wrapping microphone recording (voice input) and audio playback
/// (spoken assistant replies) for the voice assistant.
///
/// Recording produces an AAC (.m4a) file that is uploaded for server-side
/// transcription; playback takes the raw audio bytes returned by the
/// server-side text-to-speech endpoint.
class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final bool debug;

  bool _isRecording = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  VoiceService({this.debug = false});

  void _debugPrint(String message) {
    if (debug) {
      // ignore: avoid_print
      print(message);
    }
  }

  bool get isRecording => _isRecording;

  bool get isPlaying => _player.playing;

  /// Whether microphone permission is granted (requests it if needed).
  Future<bool> hasMicPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ Mic permission check failed: $e');
      return false;
    }
  }

  /// Start recording voice input to a temporary .m4a file.
  /// Returns true when recording actually started.
  Future<bool> startRecording() async {
    if (_isRecording) return true;
    try {
      if (!await _recorder.hasPermission()) {
        _debugPrint('[MeAI SDK] ⚠️ Microphone permission denied');
        return false;
      }
      await stopPlayback();
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/meai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _isRecording = true;
      _debugPrint('[MeAI SDK] 🎙️ Recording started: $path');
      return true;
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ Failed to start recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the recorded file path (null on failure).
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _debugPrint('[MeAI SDK] 🎙️ Recording stopped: $path');
      return path;
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ Failed to stop recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel and discard the current recording.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    try {
      await _recorder.cancel();
      _debugPrint('[MeAI SDK] 🎙️ Recording cancelled');
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ Failed to cancel recording: $e');
    } finally {
      _isRecording = false;
    }
  }

  /// Play synthesized speech bytes. [onComplete] fires when playback finishes
  /// or is stopped.
  Future<void> playBytes(List<int> bytes, {void Function()? onComplete}) async {
    try {
      await stopPlayback();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/meai_tts_${DateTime.now().millisecondsSinceEpoch}.audio');
      await file.writeAsBytes(bytes, flush: true);

      _playerStateSubscription = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _playerStateSubscription?.cancel();
          _playerStateSubscription = null;
          onComplete?.call();
          file.delete().catchError((_) => file);
        }
      });

      await _player.setFilePath(file.path);
      await _player.play();
      _debugPrint('[MeAI SDK] 🔊 Playing synthesized speech (${bytes.length} bytes)');
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ Failed to play audio: $e');
      _playerStateSubscription?.cancel();
      _playerStateSubscription = null;
      onComplete?.call();
    }
  }

  /// Stop any ongoing playback.
  Future<void> stopPlayback() async {
    try {
      _playerStateSubscription?.cancel();
      _playerStateSubscription = null;
      if (_player.playing) {
        await _player.stop();
      }
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ Failed to stop playback: $e');
    }
  }

  /// Delete a recorded voice file after it has been uploaded.
  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _debugPrint('[MeAI SDK] ❌ Failed to delete recording: $e');
    }
  }

  Future<void> dispose() async {
    await cancelRecording();
    await stopPlayback();
    await _recorder.dispose();
    await _player.dispose();
  }
}
