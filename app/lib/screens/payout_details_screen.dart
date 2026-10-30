import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../theme/app_theme.dart';
import '../widgets/payout_account_sheet.dart';

class PayoutDetailsScreen extends StatelessWidget {
  const PayoutDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Scaffold(
      backgroundColor: MintzerColors.background,
      appBar: AppBar(
        title: Text(S.e('Payout account'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          PayoutAccountForm(
            asSheet: false,
            showStep: false,
            onSaved: () {
              // Stay on page so user can Change again — toast comes from the form.
            },
          ),
        ],
      ),
    );
  }
}
