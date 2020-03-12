import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;



final url ='https://itsallwidgets.com/podcast/feed';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EpisodesPage(),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: http.get(url),
        builder: (context, AsyncSnapshot<http.Response>snapshot){
          if(snapshot.hasData){
            final response = snapshot.data;
            if(response.statusCode == 200){
              final rssString=response.body;
              var rssFeed= RssFeed.parse(rssString);
              return EpisodeTile(rssFeed: rssFeed);
            }
          }else{
            return Center(
             child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class EpisodeTile extends StatelessWidget {
  const EpisodeTile({
    Key key,
    @required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView(
      itemExtent: 42,
      diameterRatio: 2.5, 
      
      useMagnifier: true,
      magnification: 1.5,
      children: rssFeed.items.map((i) => ListTile(
        title: Text(i.title),
        
      )).toList());
  }
}

class PlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Player()));
  }
}

class Player extends StatelessWidget {
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
