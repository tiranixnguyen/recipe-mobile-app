/// Một món trong menu. Giá tính bằng VND, là giá size M.
class Drink {
  const Drink({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.basePrice,
  });

  final String id;
  final String name;
  final String description;
  final String emoji;
  final int basePrice;
}
