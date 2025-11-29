import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  final List<Duration> _laps = [];
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _voiceReady = false;
  bool _isListening = false;
  String? _voiceMessage;

  @override
  void dispose() {
    _ticker?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  void _start() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_stopwatch.isRunning) {
        _ticker?.cancel();
        _ticker = null;
      }
      setState(() {});
    });
    setState(() {});
  }

  void _pause() {
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    setState(() {});
  }

  void _reset() {
    _stopwatch.reset();
    if (!_stopwatch.isRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
    _laps.clear();
    setState(() {});
  }

  void _addLap() {
    if (!_stopwatch.isRunning) return;
    setState(() {
      _laps.insert(0, _stopwatch.elapsed);
    });
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceMessage = 'Đã dừng nghe.';
      });
      return;
    }

    if (!_voiceReady) {
      try {
        _voiceReady = await _speechToText.initialize(
          onError: (error) {
            if (!mounted) return;
            setState(() => _voiceMessage = 'Lỗi micro: ${error.errorMsg}');
          },
          onStatus: (status) {
            if (!mounted) return;
            setState(() => _isListening = status == 'listening');
          },
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _voiceMessage = 'Không thể khởi tạo micro: $e');
        return;
      }
    }

    if (!_voiceReady) {
      if (!mounted) return;
      setState(() => _voiceMessage = 'Thiết bị không hỗ trợ nhận diện giọng nói.');
      return;
    }

    setState(() => _voiceMessage = 'Đang lắng nghe...');

    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      await _speechToText.listen(
        localeId: 'vi_VN',
        listenMode: stt.ListenMode.confirmation,
        onResult: (result) {
          if (!mounted) return;
          if (result.finalResult) {
            _speechToText.stop();
            _handleVoiceCommand(result.recognizedWords);
          } else {
            setState(() => _voiceMessage = result.recognizedWords);
          }
        },
      );
      if (!mounted) return;
      setState(() => _isListening = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voiceMessage = 'Không thể bật nghe: $e';
        _isListening = false;
      });
    }
  }

  void _handleVoiceCommand(String rawCommand) {
    final text = rawCommand.trim();
    if (text.isEmpty) {
      setState(() => _voiceMessage = 'Không nghe rõ, hãy thử lại.');
      return;
    }

    final normalized = _normalizeText(text);
    if (normalized.contains('bat dau') ||
        normalized.contains('chay') ||
        normalized.contains('start') ||
        normalized.contains('tiep tuc')) {
      _start();
      setState(() => _voiceMessage = 'Đã bắt đầu bấm giờ.');
      return;
    }

    if (normalized.contains('tam dung') ||
        normalized.contains('pause') ||
        (normalized.contains('dung') && !normalized.contains('tiep'))) {
      _pause();
      setState(() => _voiceMessage = 'Đã tạm dừng bấm giờ.');
      return;
    }

    if (normalized.contains('lap') ||
        normalized.contains('moc') ||
        normalized.contains('ghi')) {
      _addLap();
      setState(() => _voiceMessage = 'Đã ghi lại mốc thời gian.');
      return;
    }

    if (normalized.contains('dat lai') ||
        normalized.contains('reset') ||
        normalized.contains('xoa')) {
      _reset();
      setState(() => _voiceMessage = 'Đã đặt lại đồng hồ.');
      return;
    }

    setState(() => _voiceMessage = 'Chưa hiểu lệnh: "$text"');
  }

  String _normalizeText(String value) {
    const mapping = {
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
      'đ': 'd',
    };

    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(mapping[char] ?? char);
    }
    return buffer.toString();
  }

  String _formattedElapsed() {
    final elapsed = _stopwatch.elapsed;
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final centiseconds = ((elapsed.inMilliseconds % 1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$hours:$minutes:$seconds.$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Đồng hồ bấm giờ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    children: [
                      const Text(
                        'Thời gian đã trôi',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formattedElapsed(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontFeatures: [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: AppTheme.primaryButtonStyle,
                        onPressed: _stopwatch.isRunning ? null : _start,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_stopwatch.elapsedMilliseconds == 0
                            ? 'Bắt đầu'
                            : 'Tiếp tục'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor:
                              MaterialStateProperty.all(const Color(0xFFF97386)),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                        ),
                        onPressed: _stopwatch.isRunning ? _pause : null,
                        icon: const Icon(Icons.pause),
                        label: const Text('Tạm dừng'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor:
                              MaterialStateProperty.all(const Color(0xFF7D5CFF)),
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                        ),
                        onPressed: _stopwatch.isRunning ? _addLap : null,
                        icon: const Icon(Icons.flag),
                        label: const Text('Ghi lại thời gian'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: AppTheme.secondaryButtonStyle,
                        onPressed:
                            _stopwatch.elapsedMilliseconds > 0 ? _reset : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Đặt lại'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isListening ? Icons.hearing : Icons.mic,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Điều khiển bằng giọng nói',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _voiceMessage ??
                            'Nói: "Bắt đầu bấm giờ", "Tạm dừng", "Ghi lại mốc" hoặc "Đặt lại".',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(
                            _isListening
                                ? const Color(0xFFF97386)
                                : const Color(0xFF5ED3E4),
                          ),
                          foregroundColor: MaterialStateProperty.all(
                            _isListening ? Colors.white : AppTheme.darkBackground,
                          ),
                        ),
                        onPressed: _toggleVoice,
                        icon: Icon(_isListening ? Icons.hearing_disabled : Icons.mic),
                        label: Text(_isListening ? 'Dừng nghe' : 'Ra lệnh bằng giọng nói'),
                      ),
                    ],
                  ),
                ),
                if (_laps.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Các mốc đã lưu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._laps.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mốc ${_laps.length - entry.key}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  _formatDuration(entry.value),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final centiseconds = ((duration.inMilliseconds % 1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$hours:$minutes:$seconds.$centiseconds';
  }
}
