import 'package:go_router/go_router.dart';
import 'package:music_flutter/audio_play/view/audi_player_page.dart';
import 'package:music_flutter/counter/counter.dart';
import 'package:music_flutter/main/view/main_page.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: MainPage.routeName,
        builder: (context, state) => const MainPage(),
      ),
      GoRoute(
        path: AudiPlayerPage.routeName,
        builder: (context, state) => const AudiPlayerPage(),
      ),
      GoRoute(
        path: '/counter',
        builder: (context, state) => const CounterPage(),
      ),
    ],
  );
}