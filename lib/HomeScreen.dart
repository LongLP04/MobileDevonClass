import 'package:flutter/material.dart';

import 'AlarmScreen.dart';
import 'StopwatchScreen.dart';
import 'TemperatureConverterScreen.dart';
import 'UnitConverterScreen.dart';
import 'YouTubePlayerScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featureCards = _FeatureCardData.items;
    return Scaffold(
      backgroundColor: const Color(0xFF110C32),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF211C4A), Color(0xFF0B0824)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: featureCards
                      .map(
                        (data) => _FeatureCard(
                          data: data,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => data.builder()),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Best Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _BestServiceCard(
                  title: 'Website design & development',
                  subtitle: 'Tối ưu hoá trải nghiệm chuyển đổi',
                  price: 'Free Tools',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const YouTubePlayerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Hey Long!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Bạn muốn sử dụng gì?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: Colors.white24,
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

}

class _FeatureCardData {
  _FeatureCardData({
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.color,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final double rating;
  final Color color;
  final IconData icon;
  final Widget Function() builder;

  static final List<_FeatureCardData> items = [
    _FeatureCardData(
      title: 'Nhiệt độ',
      subtitle: '°C ↔ °F',
      rating: 4.9,
      color: const Color(0xFF7D5CFF),
      icon: Icons.thermostat,
      builder: () => TemperatureConverterScreen(),
    ),
    _FeatureCardData(
      title: 'Đơn vị đo',
      subtitle: 'Chiều dài',
      rating: 4.8,
      color: const Color(0xFF5ED3E4),
      icon: Icons.straighten,
      builder: () => const UnitConverterScreen(),
    ),
    _FeatureCardData(
      title: 'Báo thức',
      subtitle: 'Có âm thanh',
      rating: 4.7,
      color: const Color(0xFF5C7CFF),
      icon: Icons.alarm,
      builder: () => const AlarmScreen(),
    ),
    _FeatureCardData(
      title: 'Bấm giờ',
      subtitle: 'Chính xác',
      rating: 4.9,
      color: const Color(0xFF60E6B3),
      icon: Icons.timer,
      builder: () => const StopwatchScreen(),
    ),
    _FeatureCardData(
      title: 'YouTube',
      subtitle: 'Xem video',
      rating: 4.6,
      color: const Color(0xFFF673AB),
      icon: Icons.ondemand_video,
      builder: () => const YouTubePlayerScreen(),
    ),
  ];
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data, required this.onTap});

  final _FeatureCardData data;
  final VoidCallback onTap;

  // Thay thế toàn bộ hàm build trong class _FeatureCard (khoảng dòng 210)
  @override
  Widget build(BuildContext context) {
    // Lấy tổng độ rộng màn hình
    final screenWidth = MediaQuery.of(context).size.width;

    // Tổng Padding ngang của SingleChildScrollView là 24x2 = 48px
    const double horizontalPadding = 24 * 2;

    // Khoảng cách giữa các thẻ trong Wrap là 16px
    const double spacing = 16;

    // TÍNH ĐỘ RỘNG KHẢ DỤNG: Lấy độ rộng màn hình trừ đi tổng padding
    final availableWidth = screenWidth - horizontalPadding;

    // TÍNH ĐỘ RỘNG MỖI THẺ: (Độ rộng khả dụng - khoảng cách) / 2
    // Dòng này được sửa để đảm bảo không bị trừ lặp
    final width = (availableWidth - spacing) / 2;

    // LỖI XẢY RA KHI MÀN HÌNH QUÁ NHỎ HOẶC ĐỘ RỘNG CŨ LÀM CHO width ÂM.
    // Bây giờ, width đã được tính toán đúng dựa trên không gian bên trong Padding.

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Giữ nguyên độ rộng đã tính toán:
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: data.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: data.color.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // ... (Phần còn lại của Column giữ nguyên)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(data.icon, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              data.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  data.rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BestServiceCard extends StatelessWidget {
  const _BestServiceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4F),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2A255F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.web_asset,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

