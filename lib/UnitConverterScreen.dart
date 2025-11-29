import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({Key? key}) : super(key: key);

  @override
  _UnitConverterScreenState createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final TextEditingController _controller = TextEditingController();
  double? _convertedValue;
  bool _isMetersToFeet = true;

  void _convertUnits() {
    setState(() {
      final input = double.tryParse(_controller.text);
      if (input != null) {
        _convertedValue =
            _isMetersToFeet ? input * 3.28084 : input / 3.28084;
      } else {
        _convertedValue = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Chuyển đổi đơn vị đo'),
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
                const Text(
                  'Chuyển đổi linh hoạt giữa mét và feet.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giá trị đầu vào',
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
                          'Ví dụ: 12.5',
                          hint: 'Nhập chiều dài',
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
                                'Từ mét sang feet',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: true,
                              activeColor: Colors.lightBlueAccent,
                              groupValue: _isMetersToFeet,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _isMetersToFeet = value;
                                  });
                                }
                              },
                            ),
                            const Divider(color: Colors.white24, height: 0),
                            RadioListTile<bool>(
                              title: const Text(
                                'Từ feet sang mét',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: false,
                              activeColor: Colors.lightBlueAccent,
                              groupValue: _isMetersToFeet,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _isMetersToFeet = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _convertedValue == null
                            ? 'Kết quả sẽ hiển thị ở đây'
                            : _isMetersToFeet
                                ? 'Giá trị đổi sang feet là: ${_convertedValue!.toStringAsFixed(2)} ft'
                                : 'Giá trị đổi sang mét là: ${_convertedValue!.toStringAsFixed(2)} m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: AppTheme.primaryButtonStyle,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Chuyển đổi'),
                  onPressed: _convertUnits,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}