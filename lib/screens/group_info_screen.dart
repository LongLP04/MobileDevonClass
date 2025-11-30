import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final PageController _controller = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  static const List<_GroupMember> _members = [
    _GroupMember(
      name: 'Phước Long',
      role: 'Trưởng nhóm • Flutter UI',
      description:
          'Phụ trách định hướng sản phẩm, kết nối các tính năng tiện ích và tối ưu trải nghiệm.',
      imageUrl: 'https://picsum.photos/seed/long/600/800',
    ),
    _GroupMember(
      name: 'Hữu Nhân',
      role: 'Backend • Speech/Alarm',
      description:
          'Triển khai logic báo thức và nhận diện giọng nói, đảm bảo thao tác rảnh tay chính xác.',
      imageUrl: 'https://picsum.photos/seed/nhan/600/800',
    ),
    _GroupMember(
      name: 'Hoàng Phúc',
      role: 'ML Kit • Translator',
      description:
          'Tích hợp Google ML Kit cho dịch văn bản, giọng nói và hình ảnh theo yêu cầu đề tài.',
      imageUrl: 'https://picsum.photos/seed/phuc/600/800',
    ),
    _GroupMember(
      name: 'Hồng Thiên',
      role: 'Media • YouTube',
      description:
          'Chịu trách phần giải trí YouTube và hiệu ứng giao diện để ứng dụng sinh động hơn.',
      imageUrl: 'https://picsum.photos/seed/thien/600/800',
    ),
    _GroupMember(
      name: 'Minh Mẫn',
      role: 'QA • Converter',
      description:
          'Kiểm thử các bộ chuyển đổi đơn vị/nhiệt độ, đảm bảo số liệu chính xác và dễ dùng.',
      imageUrl: 'https://picsum.photos/seed/man/600/800',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Thông tin nhóm'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  'Lướt để xem từng thành viên',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _members.length,
                  onPageChanged: (value) => setState(() => _currentPage = value),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _MemberCard(member: member),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _PageIndicator(
                length: _members.length,
                index: _currentPage,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final _GroupMember member;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                member.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.person, color: Colors.white54, size: 56),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            member.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.role,
            style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Text(
            member.description,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.length, required this.index});

  final int length;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 28 : 10,
          decoration: BoxDecoration(
            color: active ? Colors.lightBlueAccent : Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}

class _GroupMember {
  const _GroupMember({
    required this.name,
    required this.role,
    required this.description,
    required this.imageUrl,
  });

  final String name;
  final String role;
  final String description;
  final String imageUrl;
}
