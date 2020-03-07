import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: PodApp()));
  }
}

class PodApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(flex: 9, child: Placeholder()),
        Flexible(flex: 2, child: AudioControls())
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[PlaybackButtons()],
    );
  }
}

class PlaybackButtons extends StatefulWidget {
  @override
  _PlaybackButtonsState createState() => _PlaybackButtonsState();
}

class _PlaybackButtonsState extends State<PlaybackButtons> {
  bool _isPlaying = false;
  FlutterSound _sound;
  final url =
      'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Surf%20Shimmy.mp3';
  // FlutterSound flutterSound = FlutterSound();
  double playPosition;
  Stream<PlayStatus> _playerSubscription;
  @override
  void initState() {
    super.initState();
    _sound = FlutterSound();
    playPosition = 0;
  }

  void _stop() async {
    await _sound.stopPlayer();
    setState(() {
            _isPlaying = false;
          });
  }

  void _play() async {
    await _sound.startPlayer(url);
    _playerSubscription = _sound.onPlayerStateChanged
      ..listen((e) {
        if (e != null) {
          print(e.currentPosition);
          
       setState(()=>   playPosition = e.currentPosition/e.duration);

         
        }
      });
       setState(() {
            _isPlaying = true;
          });
  }

  void _fastForward() {}
  void _rewind() {}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Slider(value: playPosition, onChanged: null),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              IconButton(icon: Icon(Icons.fast_rewind), onPressed: null),
              IconButton(
                icon: _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
                onPressed: () {
                  if (_isPlaying) {
                    _stop();
                  } else {
                    _play();
                  }
                },
              ),
              IconButton(icon: Icon(Icons.fast_forward), onPressed: null),
            ]),
          ]),
    );
  }
}
