import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:quiver/async.dart';
import 'package:audio_session/audio_session.dart';

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
  final attackTimers = <CountdownTimer?>[];
  final releaseTimers = <CountdownTimer?>[];
  final notes = {
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_C3.wav':
        LogicalKeyboardKey.keyZ,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_C%233.wav':
        LogicalKeyboardKey.keyS,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_D3.wav':
        LogicalKeyboardKey.keyX,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_D%233.wav':
        LogicalKeyboardKey.keyD,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_E3.wav':
        LogicalKeyboardKey.keyC,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_F3.wav':
        LogicalKeyboardKey.keyV,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_F%233.wav':
        LogicalKeyboardKey.keyG,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_G3.wav':
        LogicalKeyboardKey.keyB,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_G%233.wav':
        LogicalKeyboardKey.keyH,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_A3.wav':
        LogicalKeyboardKey.keyN,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_A%233.wav':
        LogicalKeyboardKey.keyJ,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_B3.wav':
        LogicalKeyboardKey.keyM,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_C4.wav':
        LogicalKeyboardKey.comma,
  }.entries.toList();
  final notesPlaying = <int>[];
  var volume = 1.0;
  var attack = 500;
  var decay = 300;
  var releasedNoteRecently = false;

  initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    for (int i = 0; i < notes.length; i++) {
      players.add(AudioPlayer());
      try {
        players[i].setUrl(notes[i].key);
      } on PlayerException catch (e) {
        print("Error loading audio source: $e");
      }

      attackTimers.add(
        CountdownTimer(
          Duration(milliseconds: attack),
          const Duration(milliseconds: 10),
        ),
      );

      releaseTimers.add(
        CountdownTimer(
          Duration(milliseconds: decay),
          const Duration(milliseconds: 10),
        ),
      );
    }
  }

  void _handleNoteRelease() {
    //releasedNoteRecently = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      releasedNoteRecently = false;
    });
  }

  void _handleInput(KeyEvent event) {
    int index = 0;
    for (int i = 0; i < notes.length; i++) {
      if (event.logicalKey == notes[i].value) {
        index = i;
        break;
      }
    }

    if (event is KeyDownEvent) {
      print("play sound: " + index.toString());
      _playSound(index);
    } else if (event is KeyUpEvent && !releasedNoteRecently) {
      _handleNoteRelease();
      print("fade sound: " + index.toString());
      _stopSound(index);
    }
  }

  void _setVolume(double v) {
    volume = v;
  }

  void _playSound(int index) async {
    if (notesPlaying.contains(index)) {
      return;
    }

    //print("play sound: " + index.toString());
    releaseTimers[index]?.cancel();
    notesPlaying.add(index);

    await players[index].seek(Duration(milliseconds: 0));
    if (attack > 0) {
      await players[index].setVolume(1); //Change back to zero
    } else {
      await players[index].setVolume(volume);
    }
    players[index].play();

    // if (attack > 0) {
    //   Duration duration = Duration(milliseconds: attack);
    //   attackTimers[index] =
    //       CountdownTimer(duration, const Duration(milliseconds: 10))
    //         ..listen((event) {
    //           final newVolume = clampDouble(
    //             lerpDouble(
    //               volume,
    //               0,
    //               event.remaining.inMilliseconds / duration.inMilliseconds,
    //             )!,
    //             0,
    //             volume,
    //           );
    //           players[index].setVolume(newVolume);
    //         }).onDone(() async {
    //           //await players[index].setVolume(volume);
    //         });
    // }
  }

  void _stopSound(int index) async {
    if (!notesPlaying.contains(index)) {
      return;
    }

    //print("fade sound: " + index.toString());
    attackTimers[index]?.cancel();
    notesPlaying.remove(index);

    /// Will fade out over 3 seconds
    Duration duration = Duration(milliseconds: decay);
    double initialVolume = players[index].volume;

    /// Using a [CountdownTimer] to decrement the volume every 50 milliseconds, then stop [AudioPlayer] when done.
    releaseTimers[index] =
        CountdownTimer(duration, const Duration(milliseconds: 10))
          ..listen((event) {
            final newVolume = clampDouble(
              (event.remaining.inMilliseconds / duration.inMilliseconds) *
                  initialVolume,
              0,
              initialVolume,
            );
            players[index].setVolume(newVolume);
          }).onDone(() async {
            await players[index].pause();
          });
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode _focusNode = FocusNode();
    var theme = Theme.of(context);

    List<Widget> pianoKeys = [];
    for (var i = 0; i < notes.length; i++) {
      String keyName = notes[i].key.replaceAll(
        "https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_",
        "",
      );
      keyName = keyName.replaceAll("%233", "#");
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
        _handleInput(event);
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
