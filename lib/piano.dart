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

enum KeyboardType { piano, drums }

class PianoKeyboard extends StatefulWidget {
  PianoKeyboard({super.key, required this.keyboardType});

  final keyboardType;
  var volume = 1.0;
  var attack = 15;
  var release = 300;

  void setVolume(double v) {
    volume = v;
  }

  void setAttack(int milliseconds) {
    attack = milliseconds;
  }

  void setRelease(int milliseconds) {
    release = milliseconds;
  }

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  final players = <AudioPlayer?>[];
  final attackTimers = <CountdownTimer?>[];
  final FocusNode _focusNode = FocusNode();

  final Map<String, LogicalKeyboardKey> pianoMap = {
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

  final Map<String, LogicalKeyboardKey> drumsMap = {
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_C3.wav':
        LogicalKeyboardKey.keyZ,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_C%233.wav':
        LogicalKeyboardKey.keyS,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/piano_D3.wav':
        LogicalKeyboardKey.keyX,
  };

  late List<MapEntry<String, LogicalKeyboardKey>> notes;
  final notesPlaying = <int>{};
  final Set<int> pressedKeys = {};

  @override
  void initState() {
    super.initState();

    // Set the list of notes to create
    if (widget.keyboardType == KeyboardType.drums) {
      notes = drumsMap.entries.toList();
    } else {
      notes = pianoMap.entries.toList();
    }

    _initialize();
  }

  @override
  void didUpdateWidget(PianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyboardType != widget.keyboardType) {
      if (widget.keyboardType == KeyboardType.drums) {
        notes = drumsMap.entries.toList();
      } else {
        notes = pianoMap.entries.toList();
      }
    }
  }

  Future<void> _initialize() async {
    // Set the audio session to handle music
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Initialize all of the audio players and timers
    for (var i = 0; i < notes.length; i++) {
      players.add(null);
      attackTimers.add(null);
      _loadAudioPlayer(i);
    }
  }

  // Receives keyboard event to play notes
  void _handleInput(KeyEvent event) {
    int? index;
    for (int i = 0; i < notes.length; i++) {
      if (event.logicalKey == notes[i].value) {
        index = i;
        break;
      }
    }

    if (index != null) {
      if (event is KeyDownEvent) {
        _playSound(index);
      } else if (event is KeyUpEvent) {
        _stopSound(index);
      }
    }
  }

  // Loads an audio player onto the index
  Future<void> _loadAudioPlayer(int index) async {
    if (players.length < index ||
        players[index] != null ||
        notes.length < index) {
      return;
    }

    try {
      players[index] = AudioPlayer();
      await players[index]?.setUrl(notes[index].key);
    } catch (e) {
      print("Error loading audio: $e");
    }
  }

  // Plays a sound given an index
  void _playSound(int index) async {
    // If sounds are not loaded or it's already the playing sound, return
    if (players.length < index || notesPlaying.contains(index)) {
      return;
    }

    // Set piano playing state
    notesPlaying.add(index);
    setState(() => pressedKeys.add(index));

    // Load audio player if it hasn't already
    await _loadAudioPlayer(index);

    // Set the initial volume
    if (widget.attack <= 0) {
      await players[index]?.setVolume(widget.volume);
    } else {
      await players[index]?.setVolume(0);
    }

    // Play the sound
    players[index]?.play();

    // Fade in sound if there's an attack
    if (widget.attack > 0) {
      Duration duration = Duration(milliseconds: widget.attack);
      attackTimers[index] =
          CountdownTimer(duration, const Duration(milliseconds: 10))
            ..listen((event) {
              final newVolume = clampDouble(
                lerpDouble(
                  widget.volume,
                  0,
                  event.remaining.inMilliseconds / duration.inMilliseconds,
                )!,
                0,
                widget.volume,
              );
              players[index]?.setVolume(newVolume);
            }).onDone(() async {
              //await players[index].setVolume(widget.volume);
            });
    }
  }

  // Stops a sound given an index
  void _stopSound(int index) async {
    // If sounds are not loaded or playing, return
    if (players.length < index ||
        players[index] == null ||
        attackTimers.length < index ||
        !notesPlaying.contains(index)) {
      return;
    }

    // Get the audio player, then set it to null
    AudioPlayer player = players[index]!;
    players[index] = null;

    // Stops the attack
    attackTimers[index]?.cancel();

    // Sets piano playing state
    notesPlaying.remove(index);
    setState(() => pressedKeys.remove(index));

    // Initialize variables
    Duration duration = Duration(milliseconds: widget.release);
    double initialVolume = player.volume;

    // Fade the sound out
    CountdownTimer(duration, const Duration(milliseconds: 10))
        .listen((event) {
          final newVolume = clampDouble(
            (event.remaining.inMilliseconds / duration.inMilliseconds) *
                initialVolume,
            0,
            initialVolume,
          );
          player.setVolume(newVolume);
        })
        .onDone(() async {
          await player.stop();
        });

    // Pre initialize the next audio player for future use
    await _loadAudioPlayer(index);
  }

  // Sets the state of a piano key to show if it's pressed
  void _updatePressedState(int index, bool isPressed) {
    setState(() {
      if (isPressed) {
        pressedKeys.add(index);
      } else {
        pressedKeys.remove(index);
      }
    });
  }

  // Builds the keyboard widgets
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    // Creates a list of piano key widgets
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

    // Creates the visible piano keyboard
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
