import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Nội dung thanh "Đang nấu dở": "Trứng chiên hành · bước 2/4", bấm thì mở [location].
typedef ResumeCooking = ({String text, String location});

/// Phiên nấu đang dở để mời nấu tiếp; null khi không có phiên, phiên đã xong hoặc chưa tải món.
final resumeCookingProvider = Provider.autoDispose<ResumeCooking?>((ref) {
  final session = ref.watch(cookSessionProvider);
  if (session == null || session.isDone) return null;
  final recipes = ref.watch(recipesProvider).value;
  final dish = session.currentDish;
  final recipe = recipes?.where((r) => r.id == dish.recipeId).firstOrNull;
  if (recipe == null || recipe.steps.isEmpty) return null;
  final step = session.positions[session.current].clamp(0, recipe.steps.length - 1);
  return (
    text: CookStrings.resumeStep(recipe.name, step + 1, recipe.steps.length),
    location: session.isMeal ? mealCookStepLocation : cookStepLocation(recipe.id),
  );
});

/// Thanh "Đang nấu dở · Nấu tiếp" ở đầu màn Khám phá (prototype `Main`, `showResume`): nền `ink`,
/// bấm thì mở lại đúng bước đang dở. Không có phiên nấu dở thì không hiện gì.
///
/// Tự lo khoảng cách bên dưới, nên màn Khám phá cứ đặt `const ResumeCookingBanner()` đầu danh sách.
class ResumeCookingBanner extends ConsumerWidget {
  const ResumeCookingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeCookingProvider);
    if (resume == null) return const SizedBox.shrink();
    final colors = context.colors;
    return Padding(
      // Prototype: lề dưới -8 cộng khoảng 24 giữa các section.
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s4),
      child: Material(
        color: colors.ink,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(resume.location),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s3,
              AppSpacing.s3,
              AppSpacing.s3,
            ),
            child: Row(
              spacing: AppSpacing.s3,
              children: [
                Icon(AppIcons.timer, color: colors.surface),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CookStrings.resumeTitle,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.surface.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        resume.text,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors.chili, borderRadius: AppRadius.mdAll),
                    // Chữ trắng trên `chili` như nút chính.
                    child: Text(
                      CookStrings.resumeAction,
                      style: AppTextStyles.label.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
