import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static const routeName = '/';

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late AudioPlayer _player;

  Stream<DurationState> get durationStateStreams =>
      Rx.combineLatest3<Duration, Duration, Duration?, DurationState>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) {
          return DurationState(
            position: position,
            buffered: bufferedPosition,
            duration: duration ?? Duration.zero,
          );
        },
      );
  final playList = ConcatenatingAudioSource(
    children: [
      AudioSource.uri(
        Uri.parse(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        ),
        tag: MediaItem(
          id: '1',
          album: 'The Album',
          title: 'Song title 2024',
          artUri: Uri.parse(
              'https://cdn-icons-png.flaticon.com/512/1040/1040485.png'),
        ),
      ),
      AudioSource.uri(
        Uri.parse(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        ),
        tag: MediaItem(
          id: '2',
          album: 'Album name',
          title: 'Song title 2025',
          artUri: Uri.parse(
              'https://cdn-icons-png.flaticon.com/512/6213/6213062.png'),
        ),
      ),
    ],
  );

  Future<void> _loadPlaylist() async {
    await _player.setLoopMode(LoopMode.all);
    await _player.setAudioSource(playList);
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    // _player.setAsset('assets/images/play.mp3');
    _loadPlaylist();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Player')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_double_arrow_down),
            onPressed: () {},
            iconSize: 24,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              children: [
                StreamBuilder<SequenceState?>(
                  stream: _player.sequenceStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final metadata = state?.currentSource?.tag as MediaItem?;
                    return Items(
                      title: metadata?.title ?? '',
                      artist: metadata?.album ?? '',
                      image: metadata?.artUri.toString() ?? '',
                    );
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<DurationState>(
                  stream: durationStateStreams,
                  builder: (context, snapshot) {
                    final durationState = snapshot.data;
                    final progress = durationState?.position ?? Duration.zero;
                    final buffered = durationState?.buffered ?? Duration.zero;
                    final total = durationState?.duration ?? Duration.zero;
                    print('total: $total');
                    print('progress: $progress');
                    print('buffered: $buffered');

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: ProgressBar(
                        barHeight: 12,
                        progress: progress,
                        buffered: buffered,
                        total: total,
                        onSeek: _player.seek,
                      ),
                    );
                  },
                ),
                Controls(player: _player),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Controls extends StatelessWidget {
  const Controls({
    required this.player,
    super.key,
  });

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Add skip to previous button 10 seconds
        IconButton(
          icon: const Icon(Icons.replay_10),
          onPressed: () {
            player.seek(player.position - const Duration(seconds: 10));
          },
          iconSize: 33,
        ),

        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: player.seekToPrevious,
          iconSize: 33,
        ),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 33,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 33,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 33,
                onPressed: () => player.seek(
                  Duration.zero,
                  index: player.effectiveIndices!.first,
                ),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: player.seekToNext,
          iconSize: 33,
        ),
        //add button to skip 10 seconds
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed: () {
            player.seek(player.position + const Duration(seconds: 10));
          },
          iconSize: 33,
        ),
        // Add loop button
        StreamBuilder<LoopMode>(
          stream: player.loopModeStream,
          builder: (context, snapshot) {
            final loopMode = snapshot.data ?? LoopMode.off;
            return IconButton(
              icon: Icon(
                loopMode == LoopMode.all
                    ? Icons.repeat
                    : loopMode == LoopMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
              ),
              onPressed: () {
                final newMode = LoopMode.values[
                    (loopMode.index + 1) % LoopMode.values.length];
                player.setLoopMode(newMode);
              },
            );
          },
        ),
        //add speed button
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) {
            final speed = snapshot.data ?? 1.0;
            return PopupMenuButton<double>(
              icon: Text('x${speed.toStringAsFixed(1)}'),
              itemBuilder: (context) {
                return [
                  for (final speed in [0.5, 1.0, 1.5, 2.0])
                    PopupMenuItem(
                      value: speed,
                      child: Text('${speed.toStringAsFixed(1)}x'),
                    ),
                ];
              },
              onSelected: player.setSpeed,
            );
          },
        ),
      ],
    );
  }
}
class Items extends StatelessWidget {
  const Items({
    required this.title,
    required this.artist,
    required this.image,
    super.key,
  });

  final String title;
  final String artist;
  final String image;

  @override
  Widget build(BuildContext context) {
    final validImageUrl = Uri.tryParse(image)?.hasAbsolutePath == true
        ? image
        : 'https://via.placeholder.com/200';
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.purple[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: validImageUrl,
              height: 300,
              width: 300,
              placeholder: (context, url) => Container(
                color: Colors.purple[100],
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text(artist ?? '', style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class DurationState {
  DurationState({
    required this.position,
    required this.buffered,
    required this.duration,
  });

  final Duration position;
  final Duration buffered;
  final Duration duration;
}
