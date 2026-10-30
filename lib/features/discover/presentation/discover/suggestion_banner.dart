import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

/// Dữ liệu cho một thẻ trong [SuggestionBanner].
class SuggestionBannerItem {
  const SuggestionBannerItem({
    required this.title,
    required this.description,
    this.contextText,
    this.icon,
    this.imageAsset,
    this.tags = const [],
    this.ctaLabel = DiscoverStrings.viewDish,
    this.hasTrailingArrow = true,
    this.onTap,
  });

  /// Tiêu đề chính của thẻ (vd: "Sáng nay vội?", "Tủ còn trứng, cà chua, hành").
  final String title;

  /// Mô tả ngắn (tối đa 2 dòng).
  final String description;

  /// Ngữ cảnh phía trên tiêu đề (vd: "Sáng Thứ Năm · 35° nắng", "Dọn tủ lạnh").
  final String? contextText;

  /// Icon ngữ cảnh (vd: AppIcons.clock, AppIcons.fridge, AppIcons.sun).
  final IconData? icon;

  /// Ảnh minh hoạ (nếu có thay vì icon).
  final String? imageAsset;

  /// Danh sách nhãn tag (vd: ['Siêu tốc', '1 món gọn lẹ']).
  final List<String> tags;

  /// Nhãn nút hành động (mặc định 'Xem món').
  final String ctaLabel;

  /// Hiện icon mũi tên sau nhãn nút CTA (mặc định true cho nút link).
  final bool hasTrailingArrow;

  /// Callback khi bấm vào thẻ hoặc nút CTA.
  final VoidCallback? onTap;
}

/// Banner gợi ý dạng carousel ở đầu màn Khám phá (prototype `Main.dc.html`).
///
/// - Nhận danh sách thẻ [items] và callback [onPreferencesTap] cho nút "Gợi ý cho mình".
/// - Dùng [PageView], tự chuyển thẻ mỗi 6 giây ([autoAdvanceInterval]).
/// - Tạm dừng khi chạm hoặc nhận focus, tắt khi `MediaQuery.disableAnimations` bật.
/// - Hủy timer khi widget bị gỡ khỏi cây widget (tránh rò rỉ timer).
class SuggestionBanner extends StatefulWidget {
  const SuggestionBanner({
    super.key,
    required this.items,
    this.onPreferencesTap,
    this.autoAdvanceInterval = const Duration(seconds: 6),
  });

  /// Danh sách thẻ gợi ý.
  final List<SuggestionBannerItem> items;

  /// Callback khi bấm nút "Gợi ý cho mình" ở góc dưới bên phải.
  final VoidCallback? onPreferencesTap;

  /// Khoảng thời gian tự động chuyển thẻ (mặc định 6 giây).
  final Duration autoAdvanceInterval;

  @override
  State<SuggestionBanner> createState() => _SuggestionBannerState();
}

class _SuggestionBannerState extends State<SuggestionBanner> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _cancelTimer();
    } else if (_timer == null && !_isPaused) {
      _scheduleTimer();
    }
  }

  @override
  void didUpdateWidget(SuggestionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      if (_currentIndex >= widget.items.length) {
        _currentIndex = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }
      _scheduleTimer();
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    _pageController.dispose();
    super.dispose();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _pauseTimer() {
    _isPaused = true;
    _cancelTimer();
  }

  void _resumeTimer() {
    _isPaused = false;
    _scheduleTimer();
  }

  void _scheduleTimer() {
    _cancelTimer();
    if (!mounted || _isPaused || widget.items.length <= 1) return;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) return;

    _timer = Timer(widget.autoAdvanceInterval, _onAutoAdvance);
  }

  void _onAutoAdvance() {
    if (!mounted || _isPaused || widget.items.length <= 1) return;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) return;

    final nextIndex = (_currentIndex + 1) % widget.items.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.ease,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    if (!_isPaused) {
      _scheduleTimer();
    }
  }

  void _goToPage(int index) {
    if (index == _currentIndex || index < 0 || index >= widget.items.length) return;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final textScaler = MediaQuery.textScalerOf(context);
    final titleHeight = textScaler.scale(28.0);
    final descHeight = textScaler.scale(44.0);
    // 18 top + 16 ctx + 6 gap + title + 6 gap + desc + 6 gap + 20 tags + 10 gap + 40 cta + 16 bottom
    final minHeight =
        18.0 + 16.0 + 6.0 + titleHeight + 6.0 + descHeight + 6.0 + 20.0 + 10.0 + 40.0 + 16.0;
    final cardHeight = math.max(212.0, minHeight);

    return Semantics(
      label: DiscoverStrings.suggestionBannerAria,
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _pauseTimer();
          } else {
            _resumeTimer();
          }
        },
        child: MouseRegion(
          onEnter: (_) => _pauseTimer(),
          onExit: (_) => _resumeTimer(),
          child: Listener(
            onPointerDown: (_) => _pauseTimer(),
            onPointerUp: (_) => _resumeTimer(),
            onPointerCancel: (_) => _resumeTimer(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  child: ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: SizedBox(
                      height: cardHeight,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.items.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          return _SuggestionCard(
                            item: item,
                            index: index,
                            total: widget.items.length,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DotIndicators(
                        count: widget.items.length,
                        currentIndex: _currentIndex,
                        onTap: _goToPage,
                      ),
                      if (widget.onPreferencesTap != null)
                        _PreferencesButton(onTap: widget.onPreferencesTap!),
                    ],
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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.item,
    required this.index,
    required this.total,
  });

  final SuggestionBannerItem item;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: '${DiscoverStrings.cardSemanticLabel(index + 1, total)}: ${item.title}',
      button: item.onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.chiliSoft,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.contextText != null || item.icon != null || item.imageAsset != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.icon != null) ...[
                          Icon(item.icon, size: 16, color: colors.chiliDeep),
                          const SizedBox(width: 6),
                        ] else if (item.imageAsset != null) ...[
                          Image.asset(item.imageAsset!, width: 16, height: 16),
                          const SizedBox(width: 6),
                        ],
                        if (item.contextText != null)
                          Flexible(
                            child: Text(
                              item.contextText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.sans,
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w700,
                                color: colors.chiliDeep,
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      color: colors.chiliDeep,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: colors.ink,
                    ),
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in item.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.surfaceRaised,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontFamily: AppFonts.sans,
                                fontSize: 12,
                                height: 18 / 12,
                                fontWeight: FontWeight.w600,
                                color: colors.chiliDeep,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colors.chili,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.ctaLabel,
                          style: const TextStyle(
                            fontFamily: AppFonts.sans,
                            fontSize: 15,
                            height: 22 / 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (item.hasTrailingArrow) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Symbols.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotIndicators extends StatelessWidget {
  const _DotIndicators({
    required this.count,
    required this.currentIndex,
    required this.onTap,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            _DotItem(
              index: i,
              count: count,
              isSelected: i == currentIndex,
              activeColor: colors.chili,
              inactiveColor: colors.outline,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _DotItem extends StatelessWidget {
  const _DotItem({
    required this.index,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final int index;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: DiscoverStrings.cardSemanticLabel(index + 1, count),
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: SizedBox(
          width: 28,
          height: 36,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 8,
              width: isSelected ? 20 : 8,
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillAll,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferencesButton extends StatelessWidget {
  const _PreferencesButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: DiscoverStrings.heroAction,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DiscoverStrings.heroAction,
                style: AppTextStyles.meta.copyWith(
                  color: colors.chiliDeep,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                AppIcons.chevron,
                size: 16,
                color: colors.chiliDeep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
