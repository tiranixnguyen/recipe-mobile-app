import 'package:flutter/material.dart';

/// Màn tạm Lead tạo sẵn cho mỗi feature; chủ feature thay bằng màn thật.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Đang làm…')),
    );
  }
}
