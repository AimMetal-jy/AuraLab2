import 'package:go_router/go_router.dart';
import 'package:auralab_0701/screens/tts/tts_page.dart';
import 'package:auralab_0701/screens/tts/tts_processing.dart';
import 'package:auralab_0701/screens/asr_page.dart';
import 'package:auralab_0701/screens/tabs.dart';

final router = GoRouter(routes: [
  GoRoute(path: '/', builder: (context, state) => Tabs()),
  GoRoute(path: '/tts', builder: (context, state) => const TtsPage()),
  GoRoute(path: '/tts-processing', builder: (context, state) => const TtsProcessingPage()),
  GoRoute(path: '/asr', builder: (context, state) => const AsrPage()),
]);

