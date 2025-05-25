import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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

class KeyboardInput {
  const KeyboardInput({required this.playSound, required this.stopSound});

  final Function playSound;
  final Function stopSound;

  void handleInput(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyZ) {
      playSound(0);
    }
  }
}

class PianoKeyboard extends StatelessWidget {
  PianoKeyboard({super.key});

  final players = <AudioPlayer>[];
  final notes = {
    'sounds/piano_C3.wav': LogicalKeyboardKey.keyZ,
    'sounds/piano_C#3.wav': LogicalKeyboardKey.keyS,
    'sounds/piano_D3.wav': LogicalKeyboardKey.keyX,
    'sounds/piano_D#3.wav': LogicalKeyboardKey.keyD,
    'sounds/piano_E3.wav': LogicalKeyboardKey.keyC,
  }.entries.toList();

  initialize() {
    for (int i = 0; i < 5; i++) {
      players.add(AudioPlayer());
      players[i].setSource(AssetSource(notes[i].key));
    }
  }

  void handleInput(KeyEvent event) {
    for (int i = 0; i < notes.length; i++) {
      if (event.logicalKey == notes[i].value) {
        if (event is KeyDownEvent) {
          _playSound(i);
        } else if (event is KeyUpEvent) {
          _stopSound(i);
        }
      }
    }
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
    final FocusNode _focusNode = FocusNode();
    var theme = Theme.of(context);

    List<Widget> pianoKeys = [];
    for (var i = 0; i < 5; i++) {
      String keyName = notes[i].key.replaceAll("sounds/piano_", "");
      keyName = keyName.replaceAll(".wav", "");

      var key = PianoKey(
        note: Note(index: i, string: keyName),
        playSound: _playSound,
        stopSound: _stopSound,
      );
      pianoKeys.add(key);
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        handleInput(event);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(color: theme.colorScheme.primary),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: pianoKeys,
        ),
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
