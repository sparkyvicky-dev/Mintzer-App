import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../l10n/s.dart';
import '../models/deal.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

/// Payment summary — agreed clarity layout (default totals; fees collapsed).
class MoneySummaryCard extends StatefulWidget {
  const MoneySummaryCard({super.key, required this.deal});

  final MockDeal deal;

  @override
  State<MoneySummaryCard> createState() => _MoneySummaryCardState();
}

class _MoneySummaryCardState extends State<MoneySummaryCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final d = widget.deal;
    final tds = d.tdsAmount;
    final earnSub = tds > 0 ? S.e('Profit after TDS.') : 'This is your profit.';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(S.e('Payment summary'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF202124))),
          const SizedBox(height: 2),
          // l10n-missing
          const Text(
            "Here's what you pay and what you get back.",
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.35),
          ),
          const SizedBox(height: 12),
          _totalRow(S.e('You pay at checkout'), formatInr(d.spend), bold: true),
          const SizedBox(height: 10),
          if (d.cashback > 0) ...[
            _moneyLine(
              icon: Icons.account_balance_outlined,
              title: S.e('Bank cashback'),
              value: formatInr(d.cashback),
              // l10n-missing
              sub: 'Credited to your card/account according to the bank statements.',
            ),
            const SizedBox(height: 8),
          ],
          _moneyLine(
            icon: Icons.payments_outlined,
            title: S.e('Mintzer payout'),
            value: formatInr(d.walletFromMintzer),
            // l10n-missing
            sub: 'Reimbursement after verification.',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCEEAD6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, size: 20, color: Color(0xFF188038)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.e('Your earnings'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF188038))),
                      Text(earnSub, style: const TextStyle(fontSize: 11, color: Color(0xFF137333))),
                    ],
                  ),
                ),
                Text(
                  formatInr(d.earn),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF188038)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    S.e('How this is calculated?'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MintzerColors.primary),
                  ),
                  Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: MintzerColors.primary),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 4),
            // l10n-missing
            _calcRow('Product price', formatInr(d.orderValue)),
            _calcRow(S.t('discount'), '− ${formatInr(d.discount)}', green: true),
            _calcRow(S.t('platform_fee'), formatInr(d.platformFee)),
            _calcRow(S.t('card_fee'), formatInr(d.cardFee)),
            const Divider(height: 16, color: Color(0xFFE8EAED)),
            _calcRow(S.e('You pay at checkout'), formatInr(d.spend), bold: true),
            if (d.cashback > 0)
              _calcRow(S.e('Bank cashback'), formatInr(d.cashback), green: true),
            _calcRow(S.e('Mintzer payout'), formatInr(d.walletFromMintzer), green: true),
            const Divider(height: 16, color: Color(0xFFE8EAED)),
            // l10n-missing
            _calcRow('Cash reward', formatInr(d.cashRewardShown), green: true),
            if (tds > 0)
              _calcRow(
                // l10n-missing
                d.tds != null ? 'TDS' : 'TDS (${_pctLabel(AppConfig.tdsPercentDefault)}%)',
                '− ${formatInr(tds)}',
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Text(S.e('Your earnings'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF188038))),
                  const Spacer(),
                  Text(formatInr(d.earn), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF188038))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF202124),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF202124),
          ),
        ),
      ],
    );
  }

  Widget _moneyLine({
    required IconData icon,
    required String title,
    required String value,
    required String sub,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5F6368)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF202124))),
              Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368), height: 1.3)),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF188038))),
      ],
    );
  }

  String _pctLabel(double p) => p == p.roundToDouble() ? '${p.toInt()}' : p.toString();

  Widget _calcRow(String label, String value, {bool green = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF5F6368),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: green ? const Color(0xFF188038) : const Color(0xFF202124),
            ),
          ),
        ],
      ),
    );
  }
}
