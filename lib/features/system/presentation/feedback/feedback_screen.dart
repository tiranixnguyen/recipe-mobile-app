import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/data/feedback_repository.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/features/system/presentation/feedback/feedback_view_model.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Góp ý & báo lỗi (prototype `Feedback`). [errorCode] khi mở từ màn lỗi.
class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key, this.errorCode});

  final String? errorCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final provider = feedbackViewModelProvider(errorCode);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    final screenshot = state.screenshot;

    Future<void> send() async {
      // Thử lại từ snackbar sau khi đã rời màn thì bỏ qua, không gửi góp ý người dùng không còn thấy.
      if (!context.mounted) return;
      final router = GoRouter.of(context);
      final sent = await viewModel.send();
      if (!context.mounted) return;
      if (sent) {
        AppSnackbar.show(context, SystemStrings.feedbackSent);
        router.pop();
      } else {
        AppSnackbar.show(
          context,
          SystemStrings.feedbackFailed,
          kind: SnackKind.error,
          action: SnackAction(SystemStrings.retry, send),
        );
      }
    }

    Widget label(String text, {String? optional}) => Text.rich(
      TextSpan(
        text: text,
        children: [
          if (optional != null)
            TextSpan(
              text: optional,
              style: TextStyle(color: colors.inkMuted, fontWeight: FontWeight.w400),
            ),
        ],
      ),
      style: AppTextStyles.label,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          tooltip: SystemStrings.back,
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: const Text(SystemStrings.feedback),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s4,
          AppSpacing.s4,
        ),
        children: [
          Text(
            SystemStrings.feedbackIntro,
            style: AppTextStyles.body.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s5),
          Semantics(header: true, child: label(SystemStrings.feedbackKindLabel)),
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final kind in FeedbackKind.values)
                AppChip(
                  label: SystemStrings.feedbackKinds[kind]!.$1,
                  selected: kind == state.kind,
                  onTap: () => viewModel.setKind(kind),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          label(SystemStrings.feedbackMessageLabel),
          const SizedBox(height: AppSpacing.s2),
          TextFormField(
            initialValue: state.message,
            onChanged: viewModel.setMessage,
            minLines: 5,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: SystemStrings.feedbackKinds[state.kind]!.$2,
              hintMaxLines: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          if (screenshot == null)
            AppButton.secondary(
              label: SystemStrings.feedbackAttach,
              icon: AppIcons.image,
              onPressed: state.sending ? null : viewModel.pickScreenshot,
            )
          else
            _Attachment(
              image: Image.memory(screenshot, fit: BoxFit.cover),
              onRemove: state.sending ? null : viewModel.removeScreenshot,
            ),
          if (state.screenshotTooBig) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(
              SystemStrings.feedbackImageTooBig,
              style: AppTextStyles.caption.copyWith(color: colors.dangerInk),
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
          label(SystemStrings.feedbackEmailLabel, optional: SystemStrings.feedbackOptional),
          const SizedBox(height: AppSpacing.s2),
          TextFormField(
            onChanged: viewModel.setEmail,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: SystemStrings.feedbackEmailHint,
              errorText: state.emailValid ? null : SystemStrings.feedbackEmailInvalid,
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          MergeSemantics(
            child: InkWell(
              onTap: () => viewModel.setIncludeDeviceInfo(!state.includeDeviceInfo),
              borderRadius: AppRadius.smAll,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Checkbox(
                      value: state.includeDeviceInfo,
                      onChanged: (on) => viewModel.setIncludeDeviceInfo(on ?? false),
                    ),
                    Expanded(
                      child: Text(
                        SystemStrings.feedbackDevice,
                        style: AppTextStyles.body.copyWith(fontSize: 14, height: 20 / 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s3,
              AppSpacing.s4,
              AppSpacing.s6,
            ),
            child: AppButton(
              label: SystemStrings.feedbackSend,
              size: AppButtonSize.lg,
              block: true,
              onPressed: state.canSend ? send : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ảnh đã đính kèm: ảnh nhỏ, nhãn và nút bỏ ảnh.
class _Attachment extends StatelessWidget {
  const _Attachment({required this.image, required this.onRemove});

  final Widget image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s2),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: SizedBox(width: 48, height: 64, child: image),
            ),
            const SizedBox(width: AppSpacing.s3),
            const Expanded(child: Text(SystemStrings.feedbackAttached, style: AppTextStyles.body)),
            IconButton(
              icon: const Icon(AppIcons.close),
              tooltip: SystemStrings.feedbackRemoveImage,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
