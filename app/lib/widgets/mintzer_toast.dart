import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../theme/app_theme.dart';

/// Mintzer toast families — short · relevant · dismissible.
enum MintzerToastKind {
  /// Solid primary — rare system updates (#1, #16).
  brand,
  /// Dark celebrate — order submitted (#2).
  celebrate,
  /// Lilac info — copies, soft confirms (#3–5, #13–14).
  info,
  /// Mint success — upload / wallet (#11, #15).
  success,
  /// Amber warning — 5 min left (#6).
  warn,
  /// Soft red — critical / errors / expired (#7–10, #12).
  danger,
}

class _ToastStyle {
  const _ToastStyle({
    required this.bg,
    required this.fg,
    required this.subFg,
    required this.iconBg,
    required this.iconFg,
    this.solid = false,
  });

  final Color bg;
  final Color fg;
  final Color subFg;
  final Color iconBg;
  final Color iconFg;
  final bool solid;
}

_ToastStyle _styleFor(MintzerToastKind kind) {
  switch (kind) {
    case MintzerToastKind.brand:
      return const _ToastStyle(
        bg: MintzerColors.primary,
        fg: Colors.white,
        subFg: Color(0xE6FFFFFF),
        iconBg: Colors.white,
        iconFg: MintzerColors.primary,
        solid: true,
      );
    case MintzerToastKind.celebrate:
      return const _ToastStyle(
        bg: Color(0xFF1A1A2E),
        fg: Colors.white,
        subFg: Color(0xCCFFFFFF),
        iconBg: Color(0xFF2A2A40),
        iconFg: Color(0xFFFFD54F),
        solid: true,
      );
    case MintzerToastKind.info:
      return const _ToastStyle(
        bg: Color(0xFFF3EFFF),
        fg: Color(0xFF3D2E7A),
        subFg: Color(0xFF6B5FA0),
        iconBg: Color(0xFFE8E0FF),
        iconFg: MintzerColors.primary,
      );
    case MintzerToastKind.success:
      return const _ToastStyle(
        bg: Color(0xFFE6F4EA),
        fg: Color(0xFF137333),
        subFg: Color(0xFF188038),
        iconBg: Color(0xFFCEECD7),
        iconFg: Color(0xFF188038),
      );
    case MintzerToastKind.warn:
      return const _ToastStyle(
        bg: Color(0xFFFEF7E0),
        fg: Color(0xFFB06000),
        subFg: Color(0xFFE37400),
        iconBg: Color(0xFFFFE8B8),
        iconFg: Color(0xFFE37400),
      );
    case MintzerToastKind.danger:
      return const _ToastStyle(
        bg: Color(0xFFFCE8E6),
        fg: Color(0xFFC5221F),
        subFg: Color(0xFFD93025),
        iconBg: Color(0xFFFAD2CF),
        iconFg: Color(0xFFD93025),
      );
  }
}

Duration _durationFor(MintzerToastKind kind, {Duration? override}) {
  if (override != null) return override;
  return switch (kind) {
    MintzerToastKind.brand || MintzerToastKind.info || MintzerToastKind.success || MintzerToastKind.warn =>
      const Duration(seconds: 2),
    MintzerToastKind.celebrate || MintzerToastKind.danger => const Duration(seconds: 3),
  };
}

/// Primary API — typed toast with optional subtitle + dismiss.
void showMintzerToast(
  BuildContext context,
  String title, {
  String? subtitle,
  MintzerToastKind kind = MintzerToastKind.info,
  IconData? icon,
  Duration? duration,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  showMintzerToastOn(messenger, title, subtitle: subtitle, kind: kind, icon: icon, duration: duration);
}

/// Use after popping a sheet — pass [ScaffoldMessenger.of(context)] before pop.
void showMintzerToastOn(
  ScaffoldMessengerState messenger,
  String title, {
  String? subtitle,
  MintzerToastKind kind = MintzerToastKind.info,
  IconData? icon,
  Duration? duration,
}) {
  messenger.hideCurrentSnackBar();
  final style = _styleFor(kind);
  final resolvedIcon = icon ?? _defaultIcon(kind);
  final dur = _durationFor(kind, override: duration);

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      duration: dur,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      content: _MintzerToastCard(
        title: title,
        subtitle: subtitle,
        icon: resolvedIcon,
        style: style,
        onClose: () => messenger.hideCurrentSnackBar(),
      ),
    ),
  );
}

/// Convenience presets matching the locked toast sheet.
abstract final class MintzerToasts {
  static void ordersUpdated(BuildContext c) => showMintzerToast(
        c,
        S.e('Orders updated'),
        kind: MintzerToastKind.brand,
        icon: Icons.check_circle_rounded,
      );

  static void orderSubmitted(BuildContext c) => showMintzerToast(
        c,
        // l10n-missing
        'Order submitted successfully',
        // l10n-missing
        subtitle: 'We’ll verify it shortly',
        kind: MintzerToastKind.celebrate,
        icon: Icons.celebration_rounded,
      );

  static void orderIdCopied(BuildContext c) => showMintzerToast(
        c,
        S.e('Order ID copied'),
        kind: MintzerToastKind.info,
        icon: Icons.description_outlined,
      );

  static void productLinkCopied(BuildContext c) => showMintzerToast(
        c,
        S.t('snack_link'),
        kind: MintzerToastKind.info,
        icon: Icons.link_rounded,
      );

  static void deliveryCopied(BuildContext c, {bool gst = false}) => showMintzerToast(
        c,
        S.e('Delivery details copied'),
        // l10n-missing
        subtitle: gst ? 'Use the same for GST billing' : null,
        kind: MintzerToastKind.info,
        icon: Icons.badge_outlined,
      );

  static void timerFiveMin(BuildContext c) => showMintzerToast(
        c,
        // l10n-missing
        'Only 5 minutes left',
        // l10n-missing
        subtitle: 'Complete your order now',
        kind: MintzerToastKind.warn,
        icon: Icons.schedule_rounded,
      );

  static void timerOneMin(BuildContext c) => showMintzerToast(
        c,
        S.e('Last 1 minute!'),
        // l10n-missing
        subtitle: 'Complete now to keep this deal',
        kind: MintzerToastKind.danger,
        icon: Icons.schedule_rounded,
        duration: const Duration(seconds: 3),
      );

  static void timerExpired(BuildContext c) => showMintzerToast(
        c,
        // l10n-missing
        'Deal reservation expired',
        // l10n-missing
        subtitle: 'You can still try if it’s available',
        kind: MintzerToastKind.danger,
        icon: Icons.warning_amber_rounded,
      );

  static void noInternet(BuildContext c) => showMintzerToast(
        c,
        S.e('No internet connection'),
        // l10n-missing
        subtitle: 'Check your connection and try again',
        kind: MintzerToastKind.danger,
        icon: Icons.wifi_off_rounded,
      );

  static void somethingWrong(BuildContext c) => showMintzerToast(
        c,
        // l10n-missing
        'Something went wrong',
        // l10n-missing
        subtitle: 'Please try again',
        kind: MintzerToastKind.danger,
        icon: Icons.error_outline_rounded,
      );

  static void invoiceUploaded(BuildContext c) => showMintzerToast(
        c,
        S.e('Invoice uploaded'),
        // l10n-missing
        subtitle: 'We’ll verify it shortly',
        kind: MintzerToastKind.success,
        icon: Icons.check_circle_rounded,
      );

  static void uploadFailed(BuildContext c) => showMintzerToast(
        c,
        // l10n-missing
        'Upload failed',
        // l10n-missing
        subtitle: 'Please try again',
        kind: MintzerToastKind.danger,
        icon: Icons.cancel_rounded,
      );

  static void walletUpdated(BuildContext c, {required String amountLabel}) => showMintzerToast(
        c,
        S.e('Wallet updated'),
        subtitle: amountLabel,
        kind: MintzerToastKind.success,
        icon: Icons.account_balance_wallet_outlined,
      );

  static void newDeals(BuildContext c) => showMintzerToast(
        c,
        // l10n-missing
        'New deals available',
        // l10n-missing
        subtitle: 'Check the latest offers',
        kind: MintzerToastKind.brand,
        icon: Icons.auto_awesome_rounded,
        duration: const Duration(seconds: 3),
      );

  static void ticketOpened(BuildContext c, String id) => showMintzerToast(
        c,
        S.e('Ticket opened'),
        subtitle: id,
        kind: MintzerToastKind.info,
        icon: Icons.confirmation_number_outlined,
      );

  static void copied(BuildContext c, [String? label]) => showMintzerToast(
        c,
        label ?? S.t('snack_copied'),
        kind: MintzerToastKind.info,
        icon: Icons.content_copy_rounded,
      );

  static void saved(BuildContext c, String title, {String? subtitle}) => showMintzerToast(
        c,
        title,
        subtitle: subtitle,
        kind: MintzerToastKind.success,
        icon: Icons.check_circle_rounded,
      );

  static void opening(BuildContext c, String title, {String? subtitle}) => showMintzerToast(
        c,
        title,
        subtitle: subtitle,
        kind: MintzerToastKind.info,
        icon: Icons.open_in_new_rounded,
      );

  static void fieldNeeded(BuildContext c, String title) => showMintzerToast(
        c,
        title,
        kind: MintzerToastKind.warn,
        icon: Icons.edit_outlined,
      );
}

IconData _defaultIcon(MintzerToastKind kind) => switch (kind) {
      MintzerToastKind.brand => Icons.check_circle_rounded,
      MintzerToastKind.celebrate => Icons.celebration_rounded,
      MintzerToastKind.info => Icons.info_outline_rounded,
      MintzerToastKind.success => Icons.check_circle_rounded,
      MintzerToastKind.warn => Icons.schedule_rounded,
      MintzerToastKind.danger => Icons.error_outline_rounded,
    };

class _MintzerToastCard extends StatelessWidget {
  const _MintzerToastCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.style,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final _ToastStyle style;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: style.bg,
      borderRadius: BorderRadius.circular(14),
      elevation: style.solid ? 2 : 0,
      shadowColor: const Color(0x33000000),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: style.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: style.iconFg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: style.fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: style.subFg,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(Icons.close_rounded, size: 18, color: style.subFg),
            ),
          ],
        ),
      ),
    );
  }
}
