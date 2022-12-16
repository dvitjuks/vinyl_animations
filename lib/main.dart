import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinyl Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(title: 'Vinyl Animations'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  static const vinylSides = ['images/vinyl_1.png', 'images/vinyl_2.png'];

  static const sideATracks = [
    Song(title: 'Track 1', duration: '4:21'),
    Song(title: 'Track 2', duration: '4:08'),
    Song(title: 'Track 3', duration: '3:59'),
    Song(title: 'Track 4', duration: '3:43'),
  ];

  static const sideBTracks = [
    Song(title: 'Track 5', duration: '2:49'),
    Song(title: 'Track 6', duration: '3:41'),
    Song(title: 'Track 7', duration: '3:21'),
    Song(title: 'Track 8', duration: '2:30'),
  ];

  late AnimationController _flipController;
  late AnimationController _rotationController;
  bool _rotationIsPaused = true;
  late Animation<double> _flipAnimation;
  late Animation<double> _verticalOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        setState(() {});
      });

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: const Interval(0.35, 0.65, curve: Curves.linear),
      ),
    );
    _verticalOffsetAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: -100), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: -100, end: 0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: const Interval(0, 1, curve: Curves.bounceInOut),
      ),
    );

    _rotationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.9),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: [
                Image.asset(
                  'images/turntable.png',
                  width: screenWidth * 0.9,
                ),
                Positioned(
                  top: screenWidth * 0.19,
                  left: screenWidth * 0.085,
                  child: Transform.rotate(
                    angle: 0,
                    child: Transform.translate(
                      offset: Offset(
                        -_verticalOffsetAnimation.value / 4,
                        _verticalOffsetAnimation.value,
                      ),
                      child: Transform(
                        alignment: FractionalOffset.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0007)
                          ..rotateY(pi * _flipAnimation.value)
                          ..rotateX(pi * _flipAnimation.value),
                        child: GestureDetector(
                          onLongPress: _animateVinylFlip,
                          child: Transform.rotate(
                            angle: _isPlayingSideA() ? 0 : pi,
                            child: Transform.rotate(
                              angle: _rotationController.value * pi * 2,
                              child: VinylRecord(
                                size: screenWidth * 0.55,
                                asset: _isPlayingSideA()
                                    ? vinylSides.first
                                    : vinylSides.last,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: screenWidth * 0.05, right: 8),
                    child: ElevatedButton(
                      onPressed: _startStopRotation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_rotationIsPaused ? 'Play' : 'Pause'),
                          Icon(
                            _rotationIsPaused ? Icons.play_arrow : Icons.pause,
                            size: 20,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: screenWidth * 0.05, left: 8),
                    child: ElevatedButton(
                      onPressed: _animateVinylFlip,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Flip'),
                          SizedBox(
                            width: 4,
                          ),
                          Icon(
                            Icons.flip_camera_android_sharp,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'Side ${_isPlayingSideA() ? 'A' : 'B'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            Expanded(
              child: ListView(
                children: _isPlayingSideA()
                    ? List.generate(
                        sideATracks.length,
                        (index) => SongTile(
                          song: sideATracks[index],
                        ),
                      )
                    : List.generate(
                        sideBTracks.length,
                        (index) => SongTile(
                          song: sideBTracks[index],
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  bool _isPlayingSideA() {
    return _flipController.value < 0.5;
  }

  void _animateVinylFlip() {
    setState(() {
      if (_flipController.value < 0.5) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
  }

  void _startStopRotation() {
    setState(() {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
        _rotationIsPaused = true;
      } else {
        _rotationController.repeat();
        _rotationIsPaused = false;
      }
    });
  }
}

class VinylRecord extends StatelessWidget {
  final String asset;
  final double size;

  const VinylRecord({
    Key? key,
    required this.asset,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: Colors.deepOrange, width: 2)),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: AssetImage(asset),
        backgroundColor: Colors.black,
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final Song song;

  const SongTile({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        title: Text(song.title),
        trailing: Text(song.duration),
      ),
    );
  }
}

class Song {
  final String title;
  final String duration;

  const Song({
    required this.title,
    required this.duration,
  });
}
