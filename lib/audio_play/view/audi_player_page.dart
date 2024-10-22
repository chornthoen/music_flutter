import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AudiPlayerPage extends StatefulWidget {
  const AudiPlayerPage({super.key});

  static const String routeName = '/audioplayer';

  @override
  State<AudiPlayerPage> createState() => _AudiPlayerPageState();
}

class _AudiPlayerPageState extends State<AudiPlayerPage> {
  late AudioPlayer _player;
  bool isPlaying = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  late StreamSubscription _durationSubscription;
  late StreamSubscription _playerStateSubscription;
  late StreamSubscription _positionSubscription;

  List<String> playlist = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  ];
  int currentTrackIndex = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _durationSubscription = _player.onDurationChanged.listen((event) {
      if (mounted) {
        setState(() {
          duration = event;
        });
      }
    });

    _playerStateSubscription = _player.onPlayerStateChanged.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event == PlayerState.playing;
        });
      }
    });

    _positionSubscription = _player.onPositionChanged.listen((event) {
      if (mounted) {
        setState(() {
          position = event;
        });
      }
    });

    _player.onPlayerComplete.listen((event) {
      _playNextTrack();
    });
  }

  @override
  void dispose() {
    _durationSubscription.cancel();
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  void _playNextTrack() {
    if (currentTrackIndex < playlist.length - 1) {
      currentTrackIndex++;
      _player.play(UrlSource(playlist[currentTrackIndex]));
    } else {
      setState(() {
        isPlaying = false;
      });
    }
  }

  void _playPreviousTrack() {
    if (currentTrackIndex > 0) {
      currentTrackIndex--;
      _player.play(UrlSource(playlist[currentTrackIndex]));
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Playlist Player')),
      body: Column(
        children: [
          Slider(
            value: position.inSeconds.toDouble(),
            max: duration.inSeconds.toDouble(),
            onChanged: (value) async {
              await _player.seek(Duration(seconds: value.toInt()));
              await _player.resume();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(position)),
                Text(formatDuration(duration - position)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous),
                iconSize: 48,
                onPressed: _playPreviousTrack,
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 48,
                onPressed: () {
                  if (isPlaying) {
                    _player.pause();
                  } else {
                    _player.play(UrlSource(playlist[currentTrackIndex]));
                  }
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.skip_next),
                iconSize: 48,
                onPressed: _playNextTrack,
              ),
            ],
          ),
        ],
      ),
    );
  }
}