import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  TimeOfDay? _selectedTime;
  Timer? _alarmTimer;
  Timer? _countdownTimer;
  Duration? _timeRemaining;
  bool _isRinging = false;
  String? _statusMessage;

  bool _isListening = false;
  bool _speechReady = false;
  String? _voiceMessage;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _audioPlayer.setAsset('assets/alarm.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi: Không tải được âm thanh.';
      });
    }
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _statusMessage = null;
      });
    }
  }

  void _scheduleAlarm() {
    if (_selectedTime == null) {
      setState(() {
        _statusMessage = 'Vui lòng chọn thời gian trước.';
      });
      return;
    }

    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, _selectedTime!.hour,
        _selectedTime!.minute);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    final duration = target.difference(now);
    _alarmTimer?.cancel();
    _countdownTimer?.cancel();

    _alarmTimer = Timer(duration, _triggerAlarm);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = target.difference(DateTime.now());
      if (remaining.isNegative || remaining == Duration.zero) {
        _countdownTimer?.cancel();
        setState(() {
          _timeRemaining = Duration.zero;
        });
      } else {
        setState(() {
          _timeRemaining = remaining;
        });
      }
    });

    setState(() {
      _timeRemaining = duration;
      _isRinging = false;
      _statusMessage = 'Chuông sẽ reo lúc ${_selectedTime!.format(context)}.';
    });
  }

  void _triggerAlarm() async {
    setState(() {
      _isRinging = true;
      _statusMessage = 'Nhấn Dừng để dừng chuông.';
    });

    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
    } catch (e) {
      _statusMessage = 'Không thể phát âm thanh trên nền tảng này.';
    }
  }

  void _stopAlarm() async {
    if (_isRinging && _audioPlayer.processingState != ProcessingState.ready) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    }

    await _audioPlayer.stop();

    _alarmTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isRinging = false;
      _timeRemaining = null;
      _statusMessage = 'Chuông đã dừng.';
    });
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceMessage = 'Đã dừng nghe.';
      });
      return;
    }

    if (!_speechReady) {
      try {
        _speechReady = await _speechToText.initialize(
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

    if (!_speechReady) {
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
        listenMode: stt.ListenMode.dictation,
        onResult: (result) {
          if (!mounted) return;
          if (result.finalResult) {
            _speechToText.stop();
            _processVoiceCommand(result.recognizedWords);
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

  void _processVoiceCommand(String rawCommand) {
    final cleaned = rawCommand.trim();
    if (cleaned.isEmpty) {
      setState(() => _voiceMessage = 'Không nghe rõ, hãy thử lại.');
      return;
    }

    final normalized = _normalizeText(cleaned);
    if (normalized.contains('huy') ||
        normalized.contains('tat') ||
        normalized.contains('dung') ||
        normalized.contains('stop')) {
      _stopAlarm();
      setState(() => _voiceMessage = 'Đã hủy báo thức bằng giọng nói.');
      return;
    }

    if (normalized.contains('bao thuc') ||
        normalized.contains('dat') ||
        normalized.contains('alarm')) {
      final parsed = _parseTimeFromSpeech(normalized);
      if (parsed != null) {
        setState(() => _selectedTime = parsed);
        _scheduleAlarm();
        setState(() => _voiceMessage = 'Đã đặt báo thức lúc ${parsed.format(context)}.');
      } else {
        setState(() => _voiceMessage = 'Chưa hiểu thời gian trong lệnh.');
      }
      return;
    }

    setState(() => _voiceMessage = 'Chưa hiểu lệnh: "$cleaned"');
  }

  TimeOfDay? _parseTimeFromSpeech(String normalized) {
    final numbers = RegExp(r'(\d{1,2})')
        .allMatches(normalized)
        .map((match) => int.tryParse(match.group(1) ?? ''))
        .whereType<int>()
        .toList();
    if (numbers.isEmpty) return null;

    var hour = numbers.first.clamp(0, 23);
    var minute = numbers.length > 1 ? numbers[1].clamp(0, 59) : 0;

    if (normalized.contains('chieu') || normalized.contains('toi')) {
      if (hour < 12) {
        hour = (hour + 12).clamp(0, 23);
      }
    }

    return TimeOfDay(hour: hour, minute: minute);
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

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--:--';
    final totalSeconds = duration.inSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Đồng hồ báo thức'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Thời gian đã chọn',
                          style: TextStyle(color: Colors.white70),
                        ),
                        subtitle: Text(
                          _selectedTime == null
                              ? 'Chưa chọn'
                              : _selectedTime!.format(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.access_time, color: Colors.white),
                          onPressed: _pickTime,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Còn lại: ${_formatDuration(_timeRemaining)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trạng thái',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage ?? 'Chưa lên lịch',
                        style: TextStyle(
                          color: _isRinging ? Colors.orangeAccent : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                              'Ra lệnh bằng giọng nói',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _voiceMessage ?? 'Ví dụ: "Đặt báo thức lúc 6 giờ 30" hoặc "Hủy báo thức".',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(
                            _isListening ? const Color(0xFFF97386) : const Color(0xFF5ED3E4),
                          ),
                          foregroundColor: MaterialStateProperty.all(
                            _isListening ? Colors.white : AppTheme.darkBackground,
                          ),
                        ),
                        onPressed: _toggleVoiceInput,
                        icon: Icon(_isListening ? Icons.hearing_disabled : Icons.mic),
                        label: Text(_isListening ? 'Dừng nghe' : 'Bắt đầu nghe'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: AppTheme.primaryButtonStyle,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Đặt báo thức'),
                  onPressed: _scheduleAlarm,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: AppTheme.secondaryButtonStyle,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(_isRinging ? 'Dừng chuông' : 'Hủy báo thức'),
                  onPressed:
                      (_alarmTimer != null || _isRinging) ? _stopAlarm : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lưu ý: Báo thức chỉ hoạt động khi ứng dụng đang mở hoặc chạy nền.',
                  style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}