import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/domain/pantry_list.dart';

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  Ingredient(id: 'tofu', name: 'Đậu phụ', group: IngredientGroup.protein),
  Ingredient(id: 'rice', name: 'Cơm', group: IngredientGroup.starch),
  Ingredient(id: 'noodle', name: 'Mì gói', group: IngredientGroup.starch),
  Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
  Ingredient(id: 'garlic', name: 'Tỏi', group: IngredientGroup.spice),
  Ingredient(id: 'oyster', name: 'Dầu hào', group: IngredientGroup.other),
  Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
];

List<PantryGroupView> _filter({
  String query = '',
  PantryFilter filter = PantryFilter.all,
  Set<String> have = const {},
  Set<String> needed = const {},
}) => filterPantry(_ingredients, query: query, filter: filter, have: have, needed: needed);

Map<PantryGroupKey, List<String>> _ids(List<PantryGroupView> groups) => {
  for (final g in groups) g.key: [for (final i in g.items) i.id],
};

void main() {
  group('chipStatus', () {
    test('có thắng cần mua', () {
      expect(chipStatus('egg', have: {'egg'}, needed: {'egg'}), ChipStatus.have);
      expect(chipStatus('egg', have: {}, needed: {'egg'}), ChipStatus.needed);
      expect(chipStatus('egg', have: {'rice'}, needed: {'rice'}), ChipStatus.none);
    });
  });

  group('filterPantry', () {
    test('nhóm theo thứ tự prototype, gộp gia vị với khác, bỏ gia vị cơ bản', () {
      expect(_ids(_filter()), {
        PantryGroupKey.starch: ['rice', 'noodle'],
        PantryGroupKey.protein: ['egg', 'tofu'],
        PantryGroupKey.vegetable: ['tomato'],
        PantryGroupKey.other: ['garlic', 'oyster'],
      });
    });

    test('tìm không dấu, có dấu, chữ hoa, "đ"', () {
      for (final query in ['dau', 'Đậu', 'ĐẬU', '  dau  ']) {
        expect(_ids(_filter(query: query)), {
          PantryGroupKey.protein: ['tofu'],
          PantryGroupKey.other: ['oyster'],
        }, reason: query);
      }
      expect(_ids(_filter(query: 'trung')), {
        PantryGroupKey.protein: ['egg'],
      });
    });

    test('khớp tên nhóm thì hiện cả nhóm', () {
      expect(_ids(_filter(query: 'tinh bot')), {
        PantryGroupKey.starch: ['rice', 'noodle'],
      });
      expect(_ids(_filter(query: 'gia vi')), {
        PantryGroupKey.other: ['garlic', 'oyster'],
      });
    });

    test('khớp tên nhóm vẫn theo bộ lọc', () {
      expect(_ids(_filter(query: 'tinh bot', filter: PantryFilter.have, have: {'rice'})), {
        PantryGroupKey.starch: ['rice'],
      });
    });

    test('không khớp gì thì rỗng; gia vị cơ bản không tìm ra', () {
      expect(_filter(query: 'sushi'), isEmpty);
      expect(_filter(query: 'muoi'), isEmpty);
    });

    test('lọc Đang có / Cần mua, nhóm rỗng bị bỏ', () {
      const have = {'egg', 'tomato'};
      const needed = {'egg', 'rice', 'garlic'};
      expect(_ids(_filter(filter: PantryFilter.have, have: have, needed: needed)), {
        PantryGroupKey.protein: ['egg'],
        PantryGroupKey.vegetable: ['tomato'],
      });
      expect(_ids(_filter(filter: PantryFilter.needed, have: have, needed: needed)), {
        PantryGroupKey.starch: ['rice'],
        PantryGroupKey.other: ['garlic'],
      });
      expect(_filter(filter: PantryFilter.needed), isEmpty);
    });

    test('số đang có, cần mua đếm trên cả nhóm, không theo từ khoá', () {
      final groups = _filter(query: 'trung', have: {'egg'}, needed: {'tofu'});
      expect(groups.single.items.map((i) => i.id), ['egg']);
      expect(groups.single.haveCount, 1);
      expect(groups.single.neededCount, 1);
    });
  });

  group('đếm', () {
    test('filterCounts bỏ id lạ, gia vị cơ bản; đồ đang có không tính cần mua', () {
      expect(
        filterCounts(_ingredients, have: {'egg', 'salt', 'cu-la'}, needed: {'egg', 'rice', 'x'}),
        (have: 1, needed: 1),
      );
    });

    test('pantrySummary cộng tên tự gõ vào cần mua', () {
      expect(
        pantrySummary(_ingredients, have: {'egg', 'tofu'}, needed: {'rice'}, customCount: 2),
        (have: 2, needed: 3),
      );
    });
  });
}
