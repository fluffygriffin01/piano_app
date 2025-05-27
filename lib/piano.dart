import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quiver/async.dart';
import 'package:audio_session/audio_session.dart';

enum Instrument { piano, drums }

class PianoKeyboard extends StatefulWidget {
  const PianoKeyboard({
    super.key,
    required this.instrument,
    required this.volume,
    required this.attack,
    required this.release,
  });

  final instrument;
  final volume;
  final attack;
  final release;

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  final players = <AudioPlayer?>[];
  final attackTimers = <CountdownTimer?>[];
  late FocusNode _focusNode = FocusNode();

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
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Kick.wav':
        LogicalKeyboardKey.keyZ,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Sidestick.wav':
        LogicalKeyboardKey.keyX,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Snare.wav':
        LogicalKeyboardKey.keyC,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Rimclick.wav':
        LogicalKeyboardKey.keyV,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Tom_1.wav':
        LogicalKeyboardKey.keyB,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Closed_Hat.wav':
        LogicalKeyboardKey.keyN,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Tom_2.wav':
        LogicalKeyboardKey.keyM,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Pedal_Hat.wav':
        LogicalKeyboardKey.comma,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Tom_3.wav':
        LogicalKeyboardKey.period,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Open_Hat.wav':
        LogicalKeyboardKey.slash,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Tom_4.wav':
        LogicalKeyboardKey.keyA,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Ride.wav':
        LogicalKeyboardKey.keyS,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Ride Bell.wav':
        LogicalKeyboardKey.keyD,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Crash Left.wav':
        LogicalKeyboardKey.keyF,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Crash Right.wav':
        LogicalKeyboardKey.keyG,
    'https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/drums_Ride_Splash.wav':
        LogicalKeyboardKey.keyH,
  };

  late List<MapEntry<String, LogicalKeyboardKey>> notes;
  final notesPlaying = <int>{};
  final Set<int> pressedKeys = {};

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();

    // Set the list of notes to create
    if (widget.instrument == Instrument.drums) {
      notes = drumsMap.entries.toList();
    } else {
      notes = pianoMap.entries.toList();
    }

    _initialize();
  }

  @override
  void didUpdateWidget(PianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.instrument != widget.instrument) {
      for (int i = 0; i < players.length; i++) {
        players[i]?.dispose();
      }
      players.clear();
      notes.clear();
      notesPlaying.clear();
      pressedKeys.clear();
      attackTimers.clear();
      _focusNode.dispose();

      _focusNode = FocusNode();
      if (widget.instrument == Instrument.drums) {
        notes = drumsMap.entries.toList();
      } else {
        notes = pianoMap.entries.toList();
      }

      _initialize();
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < players.length; i++) {
      players[i]?.dispose();
    }
    players.clear();
    notes.clear();
    notesPlaying.clear();
    pressedKeys.clear();
    attackTimers.clear();
    _focusNode.dispose();

    super.dispose();
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
    _updatePressedState(index, true);

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

    // Handle special drums case
    if (widget.instrument == Instrument.drums) {
      if (index == 5 || index == 7 && notesPlaying.contains(9)) {
        _stopSound(9);
      }
    }

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
    _updatePressedState(index, false);

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
          .replaceAll("https://file.garden/aDOvpp9BNFHMB4ah/PianoSounds/", "")
          .replaceAll("piano_", "")
          .replaceAll("drums_", "")
          .replaceAll("%233", "#")
          .replaceAll("_", " ")
          .replaceAll(".wav", "");

      var key = PianoKey(
        noteIndex: i,
        noteName: keyName,
        playSound: _playSound,
        stopSound: _stopSound,
        isPressed: pressedKeys.contains(i),
        updatePressedState: _updatePressedState,
      );
      pianoKeys.add(key);
    }

    // Creates the visible piano keyboard
    FocusScope.of(context).requestFocus(_focusNode);
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
    required this.noteIndex,
    required this.noteName,
    required this.playSound,
    required this.stopSound,
    required this.isPressed,
    required this.updatePressedState,
  });

  final int noteIndex;
  final String noteName;
  final Function(int) playSound;
  final Function(int) stopSound;
  final bool isPressed;
  final void Function(int, bool) updatePressedState;

  void _handleTapDown(TapDownDetails details) {
    updatePressedState(noteIndex, true);
    playSound(noteIndex);
  }

  void _handleTapUp(TapUpDetails details) {
    updatePressedState(noteIndex, false);
    stopSound(noteIndex);
  }

  void _handleTapCancel() {
    updatePressedState(noteIndex, false);
    stopSound(noteIndex);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    bool isSharp = noteName.contains('#');
    Color pressedOverlay = isSharp ? Colors.grey[800]! : Colors.grey[300]!;

    return Flexible(
      child: SizedBox(
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
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: Text(
                  noteName,
                  style: TextStyle(
                    color: isSharp ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
