import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../theme/app_theme.dart';
import '../util/external_links.dart';

/// Account suspended — locked soft copy (not “banned”). Demo phone ending `0000`.
class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: const Color(0xFF202124),
                ),
              ),
              const Spacer(flex: 2),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF7E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause_circle_filled_rounded, size: 40, color: Color(0xFFE37400)),
              ),
              const SizedBox(height: 20),
              Text(
                S.t('suspended'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
              ),
              const SizedBox(height: 10),
              Text(
                S.t('suspended_p'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368), height: 1.45),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => openSupportWhatsApp(
                    context,
                    preset: S.e('Hi Mintzer, my account is suspended. Please help.'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: MintzerColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(S.t('contact'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MintzerColors.primary,
                    side: const BorderSide(color: MintzerColors.primary, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(S.t('back_login'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
