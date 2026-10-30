import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../theme/app_theme.dart';
import '../util/external_links.dart';

/// Shown after successful account delete — session already cleared; no back to app.
class AccountDeletedScreen extends StatelessWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE7FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 40, color: MintzerColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  S.t('deleted'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                ),
                const SizedBox(height: 10),
                Text(
                  S.e('Your account has been removed. Contact support if you need help.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.45),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
                    style: FilledButton.styleFrom(
                      backgroundColor: MintzerColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(S.t('back_login'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => openSupportWhatsApp(
                    context,
                    preset: S.e('Hi Mintzer, I deleted my account and need help.'),
                  ),
                  child: Text(S.t('contact'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
