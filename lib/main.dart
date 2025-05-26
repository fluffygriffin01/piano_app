import 'package:flutter/material.dart';
import 'piano.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piano',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: const MyHomePage(title: 'Virtual Piano'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PianoKeyboard keyboard;
  KeyboardType _currentInstrument = KeyboardType.piano;
  double _currentVolume = 1.0;
  double _currentAttack = 15;
  double _currentRelease = 300;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    keyboard = PianoKeyboard(keyboardType: _currentInstrument);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primary,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            DropdownButton<KeyboardType>(
              value: _currentInstrument,
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              style: const TextStyle(color: Colors.deepPurple),
              underline: Container(height: 2, color: Colors.deepPurpleAccent),
              onChanged: (KeyboardType? value) {
                // This is called when the user selects an item.
                setState(() {
                  _currentInstrument = value!;
                });
              },
              items: [
                DropdownMenuItem<KeyboardType>(
                  value: KeyboardType.piano,
                  child: Text("Piano"),
                ),
                DropdownMenuItem<KeyboardType>(
                  value: KeyboardType.drums,
                  child: Text("Drums"),
                ),
              ],
            ),
            Slider(
              value: _currentVolume,
              min: 0,
              max: 1,
              label: _currentVolume.toString(),
              onChanged: (double value) {
                setState(() {
                  keyboard.setVolume(value);
                  _currentVolume = value;
                });
              },
            ),
            Slider(
              value: _currentAttack,
              min: 0,
              max: 1000,
              divisions: 200,
              label: _currentAttack.toString(),
              onChanged: (double value) {
                setState(() {
                  keyboard.setAttack(value.toInt());
                  _currentAttack = value;
                });
              },
            ),
            Slider(
              value: _currentRelease,
              min: 0,
              max: 1000,
              divisions: 200,
              label: _currentRelease.toString(),
              onChanged: (double value) {
                setState(() {
                  keyboard.setRelease(value.toInt());
                  _currentRelease = value;
                });
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.inversePrimary,
                  ],
                ),
              ),
              child: keyboard,
            ),
          ],
        ),
      ),
    );
  }
}
