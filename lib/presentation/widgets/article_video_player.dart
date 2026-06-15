import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/article.dart';

/// Renders an article's video natively (no webview):
/// - YouTube via youtube_player_flutter
/// - Direct files (mp4) via video_player + chewie
class ArticleVideoPlayer extends StatefulWidget {
  final VideoInfo video;
  final String? posterUrl;

  const ArticleVideoPlayer({super.key, required this.video, this.posterUrl});

  @override
  State<ArticleVideoPlayer> createState() => _ArticleVideoPlayerState();
}

class _ArticleVideoPlayerState extends State<ArticleVideoPlayer> {
  YoutubePlayerController? _yt;
  VideoPlayerController? _videoController;
  ChewieController? _chewie;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final v = widget.video;
    if (v.isYoutube) {
      final id = v.id.isNotEmpty ? v.id : (YoutubePlayer.convertUrlToId(v.url) ?? '');
      if (id.isEmpty) {
        setState(() => _initError = true);
        return;
      }
      _yt = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );
      setState(() {});
    } else if (v.isFile) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(v.url));
        await controller.initialize();
        _videoController = controller;
        _chewie = ChewieController(
          videoPlayerController: controller,
          autoPlay: false,
          looping: false,
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
          ),
        );
        setState(() {});
      } catch (_) {
        setState(() => _initError = true);
      }
    } else {
      // Unsupported inline provider (e.g. Vimeo): show poster fallback.
      setState(() => _initError = true);
    }
  }

  @override
  void dispose() {
    _yt?.dispose();
    _chewie?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError) {
      return _poster();
    }
    if (_yt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _yt!,
          aspectRatio: 16 / 9,
          progressIndicatorColor: AppColors.primary,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
          ),
        ),
      );
    }
    if (_chewie != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _chewie!.aspectRatio ?? 16 / 9,
          child: Chewie(controller: _chewie!),
        ),
      );
    }
    return _loading();
  }

  Widget _loading() => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );

  Widget _poster() => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            image: (widget.posterUrl != null && widget.posterUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(widget.posterUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.35),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: const Center(
            child: Icon(Icons.play_circle_outline, color: Colors.white, size: 56),
          ),
        ),
      );
}
