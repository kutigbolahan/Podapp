import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final url = 'https://itsallwidgets.com/podcast/feed';
final pathSuffix = 'dashcast/downloads';
//trying to download the podcast to the pathsuffix folder
Future<String> _getDownloadPath(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final prefix = dir.uri.path;
  final absolutePath = path.join(prefix, filename);
  return absolutePath;
}

class Podcast with ChangeNotifier {
  RssFeed _feed;
  RssItem _selecteditem;
  Map<String, bool> downloadStatus;

  RssFeed get feed => _feed;
  void parse(String xmlStr) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selecteditem;
  set selectedItem(RssItem value) {
    _selecteditem = value;
    notifyListeners();
  }

  void download(RssItem item) async {
    final client = http.Client();
    final req = http.Request('GET', Uri.parse(item.guid));
    final res = await client.send(req);
    if (res.statusCode != 200)
      throw Exception('Unexpected HTTPcode:${res.statusCode}');

    final file = File(await _getDownloadPath(path.split(item.guid).last));
    res.stream.listen((byte) {
      print('${byte.length}');
    });

    res.stream.pipe(file.openWrite()).whenComplete(() {
      print('Downloading Complete');
    });
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (builder) => Podcast()..parse(url),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MyPage(),
        ));
  }
}

class MyPage extends StatefulWidget {
  
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  var navIndex =0;
  final pages =List<Widget>.unmodifiable([
    EpisodesPage(),
    DummyPage()
  ]);
  final iconList = List<IconData>.unmodifiable([
    Icons.hot_tub,
    Icons.timelapse
  ]);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[navIndex],
      bottomNavigationBar: MyNavBar(icons: iconList,),
    );
  }
}

class MyNavBar extends StatefulWidget {
 final  List<IconData> icons ;

  const MyNavBar({Key key, @required this.icons}) : assert(icons != null) ;
  
  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container( 
      height: 50,
      child: Row(
        children: [
          for (var i = 0; i < widget.icons; i++) 
            
          
        ],
      ),
    );
  }
}

class DummyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text('DummyPage'),
    );
  }
}
class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<Podcast>(builder: (context, podcast, _) {
      return podcast.feed != null
          ? EpisodeListView(rssFeed: podcast.feed)
          : Center(
              child: CircularProgressIndicator(),
            );
    });
    //FutureBuilder(
    //   future: http.get(url),
    //   builder: (context, AsyncSnapshot<http.Response> snapshot) {
    //     if (snapshot.hasData) {
    //       final response = snapshot.data;
    //       if (response.statusCode == 200) {
    //         final rssString = response.body;
    //         var rssFeed = RssFeed.parse(rssString);
    //         return EpisodeListView(rssFeed: rssFeed);
    //       }
    //     } else {
    //       return Center(
    //         child: CircularProgressIndicator(),
    //       );
    //     }
    //   },
    // ),
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key key,
    @required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: rssFeed.items
            .map((i) => ListTile(
                  title: Text(i.title),
                  subtitle: Text(
                    i.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                      icon: Icon(Icons.arrow_downward),
                      onPressed: () {
                        Provider.of<Podcast>(context, listen: false)
                            .download(i);
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Downloading ${i.title}'),
                        ));
                      }),
                  onTap: () {
                    Provider.of<Podcast>(context, listen: false).selectedItem =
                        i;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlayerPage(),
                      ),
                    );
                  },
                ))
            .toList());
  }
}

class PlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(Provider.of<Podcast>(context).selectedItem.title),
        ),
        body: SafeArea(child: Player()));
  }
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    return Column(
      children: <Widget>[
        Flexible(
          flex: 5,
          child: Image.network(
            podcast.feed.image.url,
          ),
        ),
        Flexible(
          flex: 4,
          child: SingleChildScrollView(
            child: Text(podcast.selectedItem.description),
          ),
        ),
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

  void _play(String url) async {
    await _sound.startPlayer(url);
    _playerSubscription = _sound.onPlayerStateChanged
      ..listen((e) {
        if (e != null) {
          print(e.currentPosition);

          setState(() => playPosition = e.currentPosition / e.duration);
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
    final item = Provider.of<Podcast>(context).selectedItem;
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
                    _play(item.guid);
                  }
                },
              ),
              IconButton(icon: Icon(Icons.fast_forward), onPressed: null),
            ]),
          ]),
    );
  }
}
