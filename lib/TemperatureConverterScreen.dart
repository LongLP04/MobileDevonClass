import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';

class TemperatureConverterScreen extends StatefulWidget {
  @override
  _TemperatureConverterScreenState createState() =>
      _TemperatureConverterScreenState();
}

class _TemperatureConverterScreenState
    extends State<TemperatureConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  double? _convertedTemperature;
  bool _isCelsiusToFahrenheit = true;

  void _convertTemperature() {
    setState(() {
      final input = double.tryParse(_controller.text);
      if (input != null) {
        _convertedTemperature = _isCelsiusToFahrenheit
            ? input * 9 / 5 + 32
            : (input - 32) * 5 / 9;
      } else {
        _convertedTemperature = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Chuyển đổi nhiệt độ'),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Biến đổi qua lại giữa °C và °F với độ chính xác theo yêu cầu của bạn.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nhập nhiệt độ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: AppTheme.inputDecoration(
                          'Giá trị cần đổi',
                          hint: 'Ví dụ: 36.6',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<bool>(
                              title: const Text(
                                'Từ °C sang °F',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: true,
                              activeColor: Colors.lightBlueAccent,
                              groupValue: _isCelsiusToFahrenheit,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _isCelsiusToFahrenheit = value;
                                  });
                                }
                              },
                            ),
                            const Divider(color: Colors.white24, height: 0),
                            RadioListTile<bool>(
                              title: const Text(
                                'Từ °F sang °C',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: false,
                              activeColor: Colors.lightBlueAccent,
                              groupValue: _isCelsiusToFahrenheit,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _isCelsiusToFahrenheit = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _convertedTemperature == null
                            ? 'Kết quả sẽ hiển thị ở đây'
                            : _isCelsiusToFahrenheit
                                ? 'Nhiệt độ F là: ${_convertedTemperature!.toStringAsFixed(1)}°F'
                                : 'Nhiệt độ C là: ${_convertedTemperature!.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: AppTheme.primaryButtonStyle,
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Chuyển đổi'),
                  onPressed: _convertTemperature,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}