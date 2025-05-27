import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'piano.dart';

// Runs the app
void main() {
  runApp(const MyApp());
}

// A change notifier class that will notify the app
// when the theme has changed
class AppTheme with ChangeNotifier {
  ThemeData _currentTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  );
  ThemeData get currentTheme => _currentTheme;

  void setThemeColor(Color c) {
    _currentTheme = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: c));
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppTheme appTheme = AppTheme();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appTheme,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'Piano',
          theme: appTheme._currentTheme,
          home: MyHomePage(title: 'Virtual Piano', appTheme: appTheme),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.appTheme});
  final String title;
  final AppTheme appTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PianoKeyboard keyboard;
  Instrument _currentInstrument = Instrument.piano;
  double _currentVolume = 1.0;
  double _currentAttack = 15;
  double _currentRelease = 300;
  Color appThemeColor = Colors.black;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    keyboard = PianoKeyboard(
      instrument: _currentInstrument,
      volume: _currentVolume,
      attack: _currentAttack,
      release: _currentRelease,
    );

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
            DropdownButton<Instrument>(
              focusNode: FocusNode(canRequestFocus: false),
              value: _currentInstrument,
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              style: TextStyle(color: theme.colorScheme.primary),
              underline: Container(height: 2, color: theme.colorScheme.primary),
              onChanged: (Instrument? value) {
                setState(() {
                  _currentInstrument = value!;
                });
              },
              items: [
                DropdownMenuItem<Instrument>(
                  value: Instrument.piano,
                  child: Text("Piano"),
                ),
                DropdownMenuItem<Instrument>(
                  value: Instrument.drums,
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
                  _currentRelease = value;
                });
              },
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Card(
                  elevation: 2,
                  child: ColorPicker(
                    color: appThemeColor,
                    onColorChanged: (Color color) => setState(() {
                      widget.appTheme.setThemeColor(color);
                      appThemeColor = color;
                    }),
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.both: false,
                      ColorPickerType.primary: true,
                      ColorPickerType.accent: false,
                      ColorPickerType.bw: false,
                      ColorPickerType.custom: false,
                      ColorPickerType.customSecondary: false,
                      ColorPickerType.wheel: false,
                    },
                    enableShadesSelection: false,
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    heading: Text(
                      'Select color',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
              ),
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
