import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import 'strings.dart';

/// Chỉ có ở bản debug: `fvm flutter run --route /debug/theme` hoặc nút "Xem theme" trên màn tạm.
const themePreviewLocation = '/debug/theme';

/// Trang soi token: màu, chữ, khoảng cách, bo góc và widget Material của cả hai theme trên cùng màn,
/// để đối chiếu với `tokens.json` khi sửa theme.
class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.themePreview)),
      // Không dùng ListView: cả hai section luôn được dựng để test tìm thấy.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ThemeSection(title: AppStrings.themeLight, data: AppTheme.light),
            _ThemeSection(title: AppStrings.themeDark, data: AppTheme.dark),
          ],
        ),
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.title, required this.data});

  final String title;
  final ThemeData data;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: data,
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          return ColoredBox(
            color: colors.surface,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: DefaultTextStyle(
                style: AppTextStyles.body.copyWith(color: colors.ink),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.display.copyWith(color: colors.ink)),
                    const SizedBox(height: AppSpacing.s6),
                    const _Heading('Màu'),
                    Wrap(
                      spacing: AppSpacing.s3,
                      runSpacing: AppSpacing.s3,
                      children: [
                        for (final MapEntry(:key, :value) in colors.byToken.entries)
                          _Swatch(name: key, color: value),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    const _Heading('Chữ'),
                    for (final sample in _typeSamples) _TypeSample(sample),
                    const SizedBox(height: AppSpacing.s6),
                    const _Heading('Khoảng cách'),
                    for (final (name, value) in _spacings) _SpacingBar(name: name, value: value),
                    const SizedBox(height: AppSpacing.s6),
                    const _Heading('Bo góc'),
                    Wrap(
                      spacing: AppSpacing.s3,
                      runSpacing: AppSpacing.s3,
                      children: [
                        for (final MapEntry(:key, :value) in AppRadius.byToken.entries)
                          _RadiusBox(name: key, radius: value),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    const _Heading('Widget Material'),
                    const _MaterialSamples(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

typedef _TypeSampleData = ({String name, TextStyle style, String text});

const List<_TypeSampleData> _typeSamples = [
  (name: 'display', style: AppTextStyles.display, text: 'Bếp Hoà Lạc'),
  (name: 'title', style: AppTextStyles.title, text: 'Trứng chiên hành'),
  (name: 'subtitle', style: AppTextStyles.subtitle, text: 'Nguyên liệu cho 1 người'),
  (
    name: 'body',
    style: AppTextStyles.body,
    text: 'Đập trứng vào bát, thêm hành lá thái nhỏ và một chút nước mắm.',
  ),
  (name: 'meta', style: AppTextStyles.meta, text: '15 phút · 1 người · Bếp từ'),
  (name: 'label', style: AppTextStyles.label, text: 'Dưới 15 phút'),
  (name: 'caption', style: AppTextStyles.caption, text: 'Có trong tủ: trứng, hành lá'),
  (name: 'step', style: AppTextStyles.step, text: 'Phi thơm hành rồi đổ trứng vào chảo.'),
  (name: 'button', style: AppTextStyles.button, text: 'Thêm vào danh sách đi chợ'),
  (name: 'buttonLg', style: AppTextStyles.buttonLg, text: 'Bắt đầu nấu'),
];

const _spacings = [
  ('s1', AppSpacing.s1),
  ('s2', AppSpacing.s2),
  ('s3', AppSpacing.s3),
  ('s4', AppSpacing.s4),
  ('s5', AppSpacing.s5),
  ('s6', AppSpacing.s6),
  ('s8', AppSpacing.s8),
];

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Text(text, style: AppTextStyles.title.copyWith(color: context.colors.ink)),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  String get _hex =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 160,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: colors.line),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.label.copyWith(color: colors.ink)),
                Text(_hex, style: AppTextStyles.caption.copyWith(color: colors.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSample extends StatelessWidget {
  const _TypeSample(this.sample);

  final _TypeSampleData sample;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = sample.style;
    final size = style.fontSize!.round();
    final line = (style.fontSize! * style.height!).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sample.name} · $size/$line · ${style.fontWeight!.value}',
            style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
          ),
          Text(sample.text, style: style.copyWith(color: colors.ink)),
        ],
      ),
    );
  }
}

class _SpacingBar extends StatelessWidget {
  const _SpacingBar({required this.name, required this.value});

  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s1),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$name · ${value.round()}',
              style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
            ),
          ),
          Container(width: value, height: AppSpacing.s4, color: colors.chili),
        ],
      ),
    );
  }
}

class _RadiusBox extends StatelessWidget {
  const _RadiusBox({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 120,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.chiliSoft,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.chiliDeep),
      ),
      child: Text(name, style: AppTextStyles.label.copyWith(color: colors.chiliDeep)),
    );
  }
}

class _MaterialSamples extends StatelessWidget {
  const _MaterialSamples();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            FilledButton(onPressed: () {}, child: const Text('Bắt đầu nấu')),
            OutlinedButton(onPressed: () {}, child: const Text('Thêm vào Tủ đồ')),
            TextButton(onPressed: () {}, child: const Text('Bỏ qua')),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        const TextField(decoration: InputDecoration(hintText: 'Tìm món, nguyên liệu…')),
        const SizedBox(height: AppSpacing.s3),
        const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.s4),
            child: Text('Thẻ trên surface-raised, viền line'),
          ),
        ),
        const Divider(height: AppSpacing.s6),
      ],
    );
  }
}
