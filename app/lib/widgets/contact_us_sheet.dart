import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../util/external_links.dart';
import 'help_ticket_sheet.dart';

const _waDeep = Color(0xFF128C7E);
const _waSoft = Color(0xFFF4FBF7);
const _waLine = Color(0xFFB7E4C7);

Future<void> showContactUsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: const Color(0xFFE8EAED), borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const Text('Contact us', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MintzerColors.ink)),
            const SizedBox(height: 6),
            const Text(
              'If the delivery person calls, or something else is wrong, reach Mintzer from here. You don’t need the WhatsApp number saved.',
              style: TextStyle(fontSize: 13, color: MintzerColors.muted, height: 1.45),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _waSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _waLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('FASTEST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _waDeep, letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  const Text('WhatsApp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MintzerColors.ink)),
                  const SizedBox(height: 4),
                  const Text('82486 26422', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MintzerColors.ink, letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  const Text(
                    'Opens WhatsApp with a message ready.',
                    style: TextStyle(fontSize: 12, color: MintzerColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(colors: [_waDeep, MintzerColors.wa]),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => openSupportWhatsApp(ctx, preset: 'Hi Mintzer, I need help.'),
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Message on WhatsApp',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MintzerColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('INSIDE THE APP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: MintzerColors.primary, letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  const Text('Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MintzerColors.ink)),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick a topic and send a short note. We reply in My tickets.',
                    style: TextStyle(fontSize: 12, color: MintzerColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showHelpTicketSheet(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: MintzerColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Open a ticket', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
