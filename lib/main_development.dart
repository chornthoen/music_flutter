import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_flutter/app/app.dart';
import 'package:music_flutter/bootstrap.dart';

// void main() {
//   bootstrap(() => const App());
// }
Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  await bootstrap(() => const App());
}
