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
  final PianoKeyboard keyboard = PianoKeyboard();
  double _currentVolume = 1.0;
  double _currentAttack = 50;
  double _currentRelease = 300;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

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
