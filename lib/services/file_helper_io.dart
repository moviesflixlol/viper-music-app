import 'dart:io';
import 'package:just_audio/just_audio.dart';

bool checkFileExists(String path) {
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

void deleteLocalFile(String path) {
  try {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  } catch (_) {}
}

AudioSource? getAudioSourceForFile(String path) {
  try {
    return AudioSource.file(path);
  } catch (_) {
    return null;
  }
}
