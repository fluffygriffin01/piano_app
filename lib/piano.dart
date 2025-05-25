import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:quiver/async.dart';

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
  final timers = <CountdownTimer?>[];
  final notes = {
    'sounds/piano_C3.wav': LogicalKeyboardKey.keyZ,
    'sounds/piano_C#3.wav': LogicalKeyboardKey.keyS,
    'sounds/piano_D3.wav': LogicalKeyboardKey.keyX,
    'sounds/piano_D#3.wav': LogicalKeyboardKey.keyD,
    'sounds/piano_E3.wav': LogicalKeyboardKey.keyC,
    'sounds/piano_F3.wav': LogicalKeyboardKey.keyV,
    'sounds/piano_F#3.wav': LogicalKeyboardKey.keyG,
    'sounds/piano_G3.wav': LogicalKeyboardKey.keyB,
    'sounds/piano_G#3.wav': LogicalKeyboardKey.keyH,
    'sounds/piano_A3.wav': LogicalKeyboardKey.keyN,
    'sounds/piano_A#3.wav': LogicalKeyboardKey.keyJ,
    'sounds/piano_B3.wav': LogicalKeyboardKey.keyM,
    'sounds/piano_C4.wav': LogicalKeyboardKey.comma,
  }.entries.toList();
  var volume = 1;
  var decay = 200;

  initialize() {
    for (int i = 0; i < notes.length; i++) {
      players.add(AudioPlayer());
      timers.add(
        CountdownTimer(
          Duration(milliseconds: decay),
          const Duration(milliseconds: 50),
        ),
      );
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
    timers[index]?.cancel();

    if (players[index].source == null) {
      await players[index].setSource(AssetSource(notes[index].key));
    }
    await players[index].seek(Duration(milliseconds: 0));
    await players[index].setVolume(1);
    //players[index].resume();
    Future.delayed(Duration(milliseconds: 100), () {
      // print("setVolume: " + players[index].volume.toString());
      // players[index].getCurrentPosition().then(
      //   (value) => (print(value?.inMilliseconds.toString())),
      // );
      print("Gonna resume");
      if (players[index].volume >= 1) {
        players[index].resume();
      }
    });
  }

  void _stopSound(int index) async {
    /// Will fade out over 3 seconds
    double startVolume = players[index].volume;
    Duration duration = Duration(milliseconds: decay);

    /// Using a [CountdownTimer] to decrement the volume every 50 milliseconds, then stop [AudioPlayer] when done.
    timers[index] = CountdownTimer(duration, const Duration(milliseconds: 50))
      ..listen((event) {
        final percent =
            event.remaining.inMilliseconds / duration.inMilliseconds;
        players[index].setVolume(percent * startVolume);
      }).onDone(() async {
        await players[index].pause();
        print("Finished timer");
        // if (players[index].state == PlayerState.paused) {
        //   Future.delayed(Duration(milliseconds: 10), () {
        //     players[index].setVolume(1);
        //     print("setVolume");
        //   });
        // }
      });

    Future.delayed(duration, () {
      timers[index] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode _focusNode = FocusNode();
    var theme = Theme.of(context);

    List<Widget> pianoKeys = [];
    for (var i = 0; i < notes.length; i++) {
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
