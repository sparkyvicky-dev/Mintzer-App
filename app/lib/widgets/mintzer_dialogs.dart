import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../mock/session.dart';
import '../theme/app_theme.dart';

/// Centered dialog shell matching live demo `.modal-center` / `.dialog`.
Future<T?> showMintzerDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

/// Add / Edit note — demo modalNote style.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String initial,
}) {
  return showMintzerDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _NoteDialogBody(initial: initial),
  );
}

class _NoteDialogBody extends StatefulWidget {
  const _NoteDialogBody({required this.initial});
  final String initial;

  @override
  State<_NoteDialogBody> createState() => _NoteDialogBodyState();
}

class _NoteDialogBodyState extends State<_NoteDialogBody> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final isEdit = widget.initial.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEdit ? S.t('edit_note') : S.t('add_note'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF202124)),
        ),
        const SizedBox(height: 6),
        Text(
          S.t('note_p'),
          style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.45),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          maxLength: 200,
          maxLines: 4,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: S.t('note_ph'),
            hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8EAED)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8EAED)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: MintzerColors.primary, width: 1.5),
            ),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_ctrl.text.length}/200',
            style: const TextStyle(fontSize: 10, color: Color(0xFF5F6368)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  side: const BorderSide(color: Color(0xFFE8EAED)),
                  foregroundColor: const Color(0xFF5F6368),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(S.t('cancel'), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(S.t('save'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// First Accept — how do you want to order? (demo modalShopMode)
Future<String?> showShopModeDialog(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => const _ShopModeSheet(),
  );
}

class _ShopModeSheet extends StatefulWidget {
  const _ShopModeSheet();

  @override
  State<_ShopModeSheet> createState() => _ShopModeSheetState();
}

class _ShopModeSheetState extends State<_ShopModeSheet> {
  String _mode = 'external';
  bool _remember = true;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(S.t('how_order'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            S.t('how_order_p'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.4),
          ),
          const SizedBox(height: 14),
          _opt(
            id: 'external',
            title: S.t('store_app'),
            sub: S.t('store_app_sub'),
          ),
          const SizedBox(height: 8),
          _opt(
            id: 'inapp',
            title: S.t('inside_mz'),
            sub: S.t('inside_mz_sub'),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _remember = !_remember),
            child: Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? true),
                  activeColor: MintzerColors.primary,
                ),
                Expanded(
                  child: Text(S.t('keep_default'), style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              if (_remember) {
                MockSession.shopModeAsked = true;
                MockSession.shopMode = _mode;
              }
              Navigator.pop(context, _mode);
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(S.t('continue')),
          ),
        ],
      ),
    );
  }

  Widget _opt({required String id, required String title, required String sub}) {
    final selected = _mode == id;
    return Material(
      color: selected ? const Color(0xFFF3EEFF) : const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _mode = id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? MintzerColors.primary : const Color(0xFFE8EAED), width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: MintzerColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// GST deal alert — soft 1·2·3. Point to Company + GST No. in the delivery address (no company/GSTIN dump).
Future<bool> showGstAlertDialog(BuildContext context) async {
  final ok = await showMintzerDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      S.watch(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFF3EEFF), shape: BoxShape.circle),
              child: const Icon(Icons.description_outlined, size: 28, color: MintzerColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            S.e('GST invoice needed'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
          ),
          const SizedBox(height: 6),
          Text(
            S.t('gst_1').replaceAll(RegExp(r'</?b>'), ''),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.4),
          ),
          const SizedBox(height: 16),
           _GstStep(
            n: '1',
            title: S.e('Enter GST at checkout'),
            // l10n-missing
            body:
                'On the store, enter the Company and GST No. exactly as shown in the delivery address section in the app.',
          ),
          const _GstStep(
            n: '2',
            // l10n-missing
            title: 'Upload the invoice after delivery',
            // l10n-missing
            body: 'Uploading the correct invoice in the app is mandatory for this order.',
          ),
           _GstStep(
            n: '3',
            title: S.e('Wrong GST or invoice may delay payout'),
            // l10n-missing
            body: 'If details don’t match, you can re-upload a corrected invoice.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: MintzerColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(S.e('I understand')),
          ),
        ],
      );
    },
  );
  return ok == true;
}

class _GstStep extends StatelessWidget {
  const _GstStep({required this.n, required this.title, required this.body});
  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFF3EEFF), shape: BoxShape.circle),
            child: Text(n, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MintzerColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF202124))),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Finish current order first — demo modalBlocked.
Future<void> showBlockedAcceptDialog(BuildContext context, {VoidCallback? onContinueOrder}) {
  return showMintzerDialog<void>(
    context: context,
    builder: (ctx) {
      S.watch(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(S.t('finish_first'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            S.t('already_order'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onContinueOrder?.call();
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(S.t('continue_order')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(S.t('ok')),
          ),
        ],
      );
    },
  );
}
