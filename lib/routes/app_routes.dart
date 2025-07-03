import 'package:go_router/go_router.dart';
import 'package:auralab_0701/screens/tts/tts_page.dart';
import 'package:auralab_0701/screens/tts/tts_processing.dart';
import 'package:auralab_0701/screens/asr_page.dart';
import 'package:auralab_0701/screens/tabs.dart';
import 'package:auralab_0701/screens/music_player_page.dart';
import 'package:auralab_0701/models/note_model.dart';
import 'package:auralab_0701/screens/note_list_page.dart';
import 'package:auralab_0701/screens/note_edit_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => Tabs()),
    GoRoute(path: '/tts', builder: (context, state) => const TtsPage()),
    GoRoute(
      path: '/tts-processing',
      builder: (context, state) => const TtsProcessingPage(),
    ),
    GoRoute(path: '/asr', builder: (context, state) => const AsrPage()),
    GoRoute(
      path: '/music-player',
      builder: (context, state) => MusicPlayerPage(audioData: state.extra),
    ),
    GoRoute(
      path: '/notes',
      builder: (context, state) => const NoteListPage(),
    ),
    GoRoute(
      path: '/note-edit',
      builder: (context, state) => NoteEditPage(note: state.extra as Note?),
    ),
  ],
);
