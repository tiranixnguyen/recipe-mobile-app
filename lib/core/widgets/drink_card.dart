import 'package:flutter/material.dart';

import '../format.dart';
import '../models/drink.dart';

/// Card dùng chung cho mọi danh sách món. [trailing] để feature khác gắn nút (ví dụ yêu thích).
class DrinkCard extends StatelessWidget {
  const DrinkCard({super.key, required this.drink, this.onTap, this.trailing});

  final Drink drink;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(drink.emoji, style: const TextStyle(fontSize: 32)),
        title: Text(drink.name),
        subtitle: Text('từ ${formatVnd(drink.basePrice)}'),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
