import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles background audio playback and system-level media controls.
class WhiteRoseAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  WhiteRoseAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> playMediaItem(MediaItem item) async {
    mediaItem.add(item);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(item.id)));
    _player.play();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 3],
      playing: _player.playing,
      updatePosition: _player.position,
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
    );
  }
}

late AudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the audio service for background playback
  _audioHandler = await AudioService.init(
    builder: () => WhiteRoseAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.whiterose.audio',
      androidNotificationChannelName: 'White Rose Playback',
    ),
  );

  // Execute the newly named root class
  runApp(const whiterose());
}

/// The root application widget.
/// Class name strictly set to [whiterose] to match the test directory constraints.
class whiterose extends StatelessWidget {
  const whiterose({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDFDFD),
        textTheme: GoogleFonts.lustriaTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// Requests storage permissions required to scan the device for audio files.
  void _checkPermissions() async {
    await Permission.storage.request();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "WHITE ROSE",
          style: GoogleFonts.lustria(
            letterSpacing: 4,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.querySongs(
          sortType: SongSortType.ARTIST,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: Colors.black,
              ),
            );
          if (snapshot.data!.isEmpty)
            return const Center(child: Text("No localized audio found."));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemBuilder: (context, index) {
              final song = snapshot.data![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    song.artist ?? "Unknown",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.play_arrow_outlined,
                    size: 20,
                    color: Colors.black54,
                  ),
                  onTap: () {
                    _audioHandler.playMediaItem(
                      MediaItem(
                        id: song.uri!,
                        album: song.album,
                        title: song.title,
                        artist: song.artist,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
