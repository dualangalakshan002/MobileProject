import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class AudioManager extends Component {
  bool musicEnabled = true;
  bool soundsEnabled = true;

  final List<String> _sounds = [
    'click',
    'collect',
    'explode1',
    'explode2',
    'fire',
    'hit',
    'laser',
    'start',
  ];

  final Map<String, int> _soundIds = {};
  final Soundpool _soundpool = Soundpool.fromOptions(
    options: const SoundpoolOptions(maxStreams: 10),
  );

  @override
  FutureOr<void> onLoad() async {
    FlameAudio.bgm.initialize();

    // load the sound effect files
    for (String sound in _sounds) {
      _soundIds[sound] = await rootBundle
          .load('assets/audio/$sound.ogg')
          .then((ByteData data) {
        return _soundpool.load(data);
      });
    }

    return super.onLoad();
  }

  void playMusic() {
    if (musicEnabled) {
      FlameAudio.bgm.play('music.ogg');
    }
  }

  void playSound(String sound) {
    if (soundsEnabled) {
      _soundpool.play(_soundIds[sound]!);
    }
  }

  void toggleMusic() {
    musicEnabled = !musicEnabled;
    if (musicEnabled) {
      playMusic();
    } else {
      FlameAudio.bgm.stop();
    }
  }

  void toggleSounds() {
    soundsEnabled = !soundsEnabled;
  }
}
