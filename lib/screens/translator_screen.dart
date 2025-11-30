import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();
  final OnDeviceTranslatorModelManager _modelManager =
  OnDeviceTranslatorModelManager();

  TranslateLanguage _sourceLang = TranslateLanguage.vietnamese;
  TranslateLanguage _targetLang = TranslateLanguage.english;
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isListening = false;
  String? _speechStatus;
  String? _modelStatus;
  File? _lastImage;

  @override
  void dispose() {
    _sourceController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _translateText([String? override]) async {
    final text = override ?? _sourceController.text.trim();
    if (text.isEmpty) {
      setState(() => _translatedText = '');
      return;
    }

    setState(() {
      _isTranslating = true;
      _translatedText = '';
    });

    final TranslateLanguage source = _sourceLang;
    final TranslateLanguage target = _targetLang;

    try {
      final result = await _translateOnDevice(text, source, target);
      if (!mounted) return;
      setState(() => _translatedText = result);
      return;
    } catch (onDeviceError) {
      try {
        final fallback = await _remoteTranslate(text, source, target);
        if (!mounted) return;
        setState(() => _translatedText =
            '$fallback\n\n(Đã dùng dịch online vì: $onDeviceError)');
      } catch (fallbackError) {
        if (!mounted) return;
        setState(() => _translatedText =
            'Không thể dịch: $onDeviceError\nLỗi dịch online: $fallbackError');
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  Future<void> _ensureModel(TranslateLanguage language) async {
    final downloaded = await _modelManager.isModelDownloaded(language.bcpCode);
    if (downloaded) return;

    if (mounted) {
      setState(() {
        _modelStatus =
        'Đang tải gói ${_languageLabel(language)} (~20MB), vui lòng đợi...';
      });
    }

    try {
      await _modelManager
          .downloadModel(language.bcpCode, isWifiRequired: false)
          .timeout(const Duration(minutes: 2));
    } on TimeoutException {
      throw Exception(
        'Tải gói ${_languageLabel(language)} quá lâu. Kiểm tra kết nối mạng.',
      );
    } finally {
      if (mounted) {
        setState(() => _modelStatus = null);
      }
    }
  }

  Future<String> _translateOnDevice(
    String text,
    TranslateLanguage source,
    TranslateLanguage target,
  ) async {
    await _ensureModel(source);
    await _ensureModel(target);
    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    try {
      return await translator.translateText(text);
    } finally {
      await translator.close();
    }
  }

  Future<String> _remoteTranslate(
    String text,
    TranslateLanguage source,
    TranslateLanguage target,
  ) async {
    final uri = Uri.https(
      'translate.googleapis.com',
      '/translate_a/single',
      {
        'client': 'gtx',
        'sl': source.bcpCode,
        'tl': target.bcpCode,
        'dt': 't',
        'q': text,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty || decoded.first is! List) {
      throw Exception('Phản hồi dịch online không hợp lệ');
    }

    final buffer = StringBuffer();
    for (final segment in decoded.first) {
      if (segment is List && segment.isNotEmpty) {
        buffer.write(segment.first);
      }
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) {
      throw Exception('Dịch online không trả về kết quả');
    }
    return result;
  }

  Future<void> _toggleSpeech() async {
    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _isListening = status == 'listening');
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _speechStatus = 'Lỗi micro: ${error.errorMsg}');
      },
    );

    if (!available) {
      setState(() => _speechStatus = 'Thiết bị không hỗ trợ thu giọng nói.');
      return;
    }

    setState(() => _speechStatus = 'Đang nghe...');

    await _speechToText.listen(
      localeId: _localeFromLanguage(_sourceLang),
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        if (!mounted) return;
        _sourceController.text = result.recognizedWords;
        setState(() => _speechStatus = result.recognizedWords);
        if (result.finalResult) {
          _translateText(result.recognizedWords);
          _speechToText.stop();
        }
      },
    );
  }

  String _localeFromLanguage(TranslateLanguage language) {
    switch (language) {
      case TranslateLanguage.vietnamese:
        return 'vi_VN';
      case TranslateLanguage.english:
        return 'en_US';
      case TranslateLanguage.japanese:
        return 'ja_JP';
      default:
        return 'en_US';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      final file = File(picked.path);
      setState(() => _lastImage = file);
      final inputImage = InputImage.fromFile(file);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();
      final raw = recognizedText.text.trim();
      _sourceController.text = raw;
      await _translateText(raw);
    } catch (e) {
      setState(() => _translatedText = 'Không thể đọc ảnh: $e');
    }
  }

  void _swapLanguages() {
    setState(() {
      final tmp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = tmp;
    });
    _translateText();
  }

  String _languageLabel(TranslateLanguage language) {
    switch (language) {
      case TranslateLanguage.vietnamese:
        return 'Tiếng Việt';
      case TranslateLanguage.english:
        return 'English';
      case TranslateLanguage.japanese:
        return 'Nhật Bản';
      default:
        return language.bcpCode.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Dịch bằng ML Kit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLanguageSelector(),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _sourceController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: AppTheme.inputDecoration(
                          'Nhập văn bản cần dịch',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: AppTheme.primaryButtonStyle,
                        onPressed: (_isTranslating || _modelStatus != null)
                            ? null
                            : _translateText,
                        icon: _isTranslating
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.translate),
                        label: Text(_isTranslating ? 'Đang dịch...' : 'Dịch ngay'),
                      ),
                      const SizedBox(height: 12),
                      if (_modelStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _modelStatus!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      Text(
                        _translatedText.isEmpty
                            ? 'Kết quả dịch sẽ hiện ở đây.'
                            : _translatedText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSpeechCard(),
                const SizedBox(height: 24),
                _buildImageCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: _LanguageDropdown(
              value: _sourceLang,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sourceLang = value);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync_alt, color: Colors.white),
            onPressed: _swapLanguages,
          ),
          Expanded(
            child: _LanguageDropdown(
              value: _targetLang,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _targetLang = value);
                _translateText();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dịch từ giọng nói',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _speechStatus ??
                'Nhấn nút bên dưới và nói bằng ngôn ngữ nguồn để dịch.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: AppTheme.primaryButtonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(
                _isListening ? const Color(0xFFF97386) : const Color(0xFF5ED3E4),
              ),
              foregroundColor: MaterialStateProperty.all(
                _isListening ? Colors.white : AppTheme.darkBackground,
              ),
            ),
            onPressed: _toggleSpeech,
            icon: Icon(_isListening ? Icons.hearing_disabled : Icons.mic),
            label: Text(_isListening ? 'Dừng nghe' : 'Nói để dịch'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dịch từ ảnh',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_lastImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _lastImage!,
                height: 160,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white10,
              ),
              child: const Center(
                child: Text(
                  'Chưa có ảnh nào được chọn.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: AppTheme.secondaryButtonStyle,
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Chọn ảnh'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: AppTheme.primaryButtonStyle,
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Chụp ảnh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.value,
    required this.onChanged,
  });

  final TranslateLanguage value;
  final ValueChanged<TranslateLanguage?> onChanged;

  static const Map<TranslateLanguage, String> _labels = {
    TranslateLanguage.vietnamese: 'Tiếng Việt',
    TranslateLanguage.english: 'English',
    TranslateLanguage.japanese: '日本語',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TranslateLanguage>(
      value: value,
      dropdownColor: const Color(0xFF1E1B4F),
      iconEnabledColor: Colors.white,
      decoration: AppTheme.inputDecoration('Ngôn ngữ'),
      items: _labels.entries
          .map(
            (entry) => DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value, style: const TextStyle(color: Colors.white)),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}
