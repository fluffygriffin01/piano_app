import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quiver/async.dart';
import 'package:audio_session/audio_session.dart';

class Note {
  Note({required this.index, required this.string});
  final int index;
  final String string;
  int getIndex() => index;
  String getString() => string;
}

class PianoKeyboard extends StatefulWidget {
  const PianoKeyboard({super.key});
  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  final players = <AudioPlayer>[];
  final attackTimers = <CountdownTimer?>[];
  final releaseTimers = <CountdownTimer?>[];
  final FocusNode _focusNode = FocusNode();

  final Map<String, LogicalKeyboardKey> noteMap = {
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
  };

  late final List<MapEntry<String, LogicalKeyboardKey>> notes;
  final notesPlaying = <int>{};
  final Set<int> pressedKeys = {};
  var volume = 1.0;
  var attack = 500;
  var decay = 300;

  @override
  void initState() {
    super.initState();
    notes = noteMap.entries.toList();
    initialize();
  }

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    for (var i = 0; i < notes.length; i++) {
      final player = AudioPlayer();
      try {
        await player.setUrl(notes[i].key);
      } catch (e) {
        print("Error loading audio: $e");
      }
      players.add(player);
      attackTimers.add(null);
      releaseTimers.add(null);
    }
  }

  void _handleInput(KeyEvent event) {
    for (int i = 0; i < notes.length; i++) {
      if (event.logicalKey == notes[i].value) {
        if (event is KeyDownEvent) {
          _playSound(i);
        } else if (event is KeyUpEvent) {
          _stopSound(i);
        }
        break;
      }
    }
  }

  void _playSound(int index) async {
    if (notesPlaying.contains(index)) return;

    releaseTimers[index]?.cancel();
    notesPlaying.add(index);
    setState(() => pressedKeys.add(index));

    await players[index].seek(Duration.zero);
    await players[index].setVolume(volume);
    players[index].play();
  }

  void _stopSound(int index) async {
    if (!notesPlaying.contains(index)) return;

    notesPlaying.remove(index);
    setState(() => pressedKeys.remove(index));

    Duration duration = Duration(milliseconds: decay);
    double initialVolume = players[index].volume;

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

  void _updatePressedState(int index, bool isPressed) {
    setState(() {
      if (isPressed) {
        pressedKeys.add(index);
      } else {
        pressedKeys.remove(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    List<Widget> pianoKeys = [];
    for (var i = 0; i < notes.length; i++) {
      String keyName = notes[i].key
          .replaceAll(
            "https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_",
            "",
          )
          .replaceAll("%233", "#")
          .replaceAll(".wav", "");

      var key = PianoKey(
        note: Note(index: i, string: keyName),
        playSound: _playSound,
        stopSound: _stopSound,
        isPressed: pressedKeys.contains(i),
        updatePressedState: _updatePressedState,
      );
      pianoKeys.add(key);
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleInput,
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
    required this.isPressed,
    required this.updatePressedState,
  });

  final Note note;
  final Function(int) playSound;
  final Function(int) stopSound;
  final bool isPressed;
  final void Function(int, bool) updatePressedState;

  void _handleTapDown(TapDownDetails details) {
    updatePressedState(note.index, true);
    playSound(note.index);
  }

  void _handleTapUp(TapUpDetails details) {
    updatePressedState(note.index, false);
    stopSound(note.index);
  }

  void _handleTapCancel() {
    updatePressedState(note.index, false);
    stopSound(note.index);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    bool isSharp = note.getString().contains('#');
    Color pressedOverlay = isSharp ? Colors.grey[800]! : Colors.grey[300]!;

    return SizedBox(
      width: isSharp ? 40 : 60,
      height: 200,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              isPressed ? pressedOverlay : theme.colorScheme.inversePrimary,
              isSharp ? Colors.black : Colors.white,
            ],
          ),
          border: Border.all(width: 4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Center(
            child: Text(
              note.getString(),
              style: TextStyle(color: isSharp ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
