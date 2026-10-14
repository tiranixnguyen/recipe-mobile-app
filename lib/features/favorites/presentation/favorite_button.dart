import 'package:flutter/material.dart';

/// STUB: chưa lưu gì, chỉ để Menu và Chi tiết đặt nút vào ngay. Bản thật thay ở issue Yêu thích,
/// giữ nguyên constructor nên chỗ dùng không phải sửa.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.drinkId});

  final String drinkId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.favorite_border),
      tooltip: 'Yêu thích',
      onPressed: () {},
    );
  }
}
