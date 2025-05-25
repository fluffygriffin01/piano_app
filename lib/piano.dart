import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

class Note {
  Note({required this.index, required this.string});

  final int index;
  final String string;

  int getIndex() {
    return index;
  }

  String getString() {
    return string;
  }
}

class KeyboardInput extends FlameGame with KeyboardEvents {
  //KeyboardInput({required this.playSound, required this.stopSound});

  //final Function playSound;
  //final Function stopSound;

  @override
  Future<void> onLoad() async {
    print("Loading player sprite...");
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        print("keyZDown");
        //playSound(0);
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        //stopSound(0);
      }
    }
    return KeyEventResult.handled;
  }
}

class PianoKeyboard extends StatelessWidget {
  PianoKeyboard({super.key});

  //late KeyboardInput input;
  final players = <AudioPlayer>[];
  final sounds = <String>[
    'sounds/piano_C3.wav',
    'sounds/piano_C#3.wav',
    'sounds/piano_D3.wav',
    'sounds/piano_D#3.wav',
    'sounds/piano_E3.wav',
  ];

  initialize() {
    for (int i = 0; i < 5; i++) {
      players.add(AudioPlayer());
      players[i].setSource(AssetSource(sounds[i]));
    }

    //input = KeyboardInput(playSound: _playSound, stopSound: _stopSound);
  }

  void _setVolume(double volume) {
    for (AudioPlayer player in players) {
      player.setVolume(volume);
    }
  }

  void _playSound(int index) async {
    await players[index].seek(Duration(seconds: 0));
    await players[index].resume();
  }

  void _stopSound(int index) async {
    await players[index].pause();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    List<Widget> pianoKeys = [];
    for (var i = 0; i < 5; i++) {
      String keyName = sounds[i].replaceAll("sounds/piano_", "");
      keyName = keyName.replaceAll(".wav", "");

      var key = PianoKey(
        note: Note(index: i, string: keyName),
        playSound: _playSound,
        stopSound: _stopSound,
      );
      pianoKeys.add(key);
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: pianoKeys,
      ),
    );
  }
}

class PianoKey extends StatelessWidget {
  const PianoKey({
    super.key,
    required this.note,
    required this.playSound,
    required this.stopSound,
  });

  final Note note;
  final Function playSound;
  final Function stopSound;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    // Black Note
    if (note.getString().contains('#')) {
      return SizedBox(
        width: 40,
        height: 200,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                theme.colorScheme.inversePrimary,
                Color.fromARGB(255, 0, 0, 0),
              ],
            ),
            border: Border.all(width: 4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTapDown: (TapDownDetails d) => playSound(note.index),
            onTapUp: (TapUpDetails d) => stopSound(note.index),
            onTapCancel: () => stopSound(note.index),
            child: Column(
              children: <Widget>[
                Text(note.getString(), style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }
    // White note
    else {
      return SizedBox(
        width: 60,
        height: 200,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                theme.colorScheme.inversePrimary,
                Color.fromARGB(255, 255, 255, 255),
              ],
            ),
            border: Border.all(width: 4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTapDown: (TapDownDetails d) => playSound(note.index),
            onTapUp: (TapUpDetails d) => stopSound(note.index),
            onTapCancel: () => stopSound(note.index),
            child: Column(
              children: <Widget>[
                Text(
                  note.getString(),
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
