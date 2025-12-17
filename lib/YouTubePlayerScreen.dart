import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';

class YouTubePlayerScreen extends StatefulWidget {
  const YouTubePlayerScreen({super.key});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  final TextEditingController _urlController = TextEditingController();
  late YoutubePlayerController _playerController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // KHỞI TẠO CHUẨN – QUAN TRỌNG
    _playerController = YoutubePlayerController.fromVideoId(
      videoId: '',
      autoPlay: false,
      params: const YoutubePlayerParams(
        enableJavaScript: true,
        showFullscreenButton: true,
        playsInline: true,
        strictRelatedVideos: true,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    _playerController.close();
    _urlController.dispose();
    super.dispose();
  }

  void _loadVideo() {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đường dẫn YouTube.');
      return;
    }

    final videoId = _extractVideoId(rawUrl);
    if (videoId == null) {
      setState(() => _errorMessage = 'Link không hợp lệ, vui lòng thử lại.');
      return;
    }

    setState(() {
      _errorMessage = null;

      // DÙNG cueVideoById để tránh lỗi 153
      _playerController.cueVideoById(videoId: videoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _playerController,
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: AppBar(
            title: const Text('Xem video YouTube'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Container(
            decoration: AppTheme.gradientBackground,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GlassCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _urlController,
                            style: const TextStyle(color: Colors.white),
                            decoration: AppTheme.inputDecoration(
                              'Dán link YouTube tại đây',
                              hint: 'https://youtu.be/...',
                            ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white70),
                                    onPressed: () {
                                      _urlController.clear();
                                      setState(() => _errorMessage = null);
                                    },
                                  ),
                                ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: AppTheme.primaryButtonStyle,
                              icon: const Icon(Icons.play_circle_fill),
                              label: const Text('Phát video'),
                              onPressed: _loadVideo,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: player,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idRegex.hasMatch(trimmed)) return trimmed;

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
      if (!uri.hasScheme) {
        uri = Uri.parse('https://$trimmed');
      }
    } catch (_) {
      return null;
    }

    if (uri.host.isEmpty) return null;

    String? candidate;

    if (uri.host.contains('youtu.be')) {
      candidate = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.host.contains('youtube.com')) {
      candidate = uri.queryParameters['v'];

      final segments = uri.pathSegments;
      if (candidate == null && segments.contains('embed')) {
        candidate = segments[segments.indexOf('embed') + 1];
      }

      if (candidate == null && segments.contains('shorts')) {
        candidate = segments[segments.indexOf('shorts') + 1];
      }

      if (candidate == null && segments.contains('live')) {
        candidate = segments[segments.indexOf('live') + 1];
      }
    }

    candidate ??= YoutubePlayerController.convertUrlToId(trimmed);

    if (candidate != null && idRegex.hasMatch(candidate)) {
      return candidate;
    }

    return null;
  }
}
