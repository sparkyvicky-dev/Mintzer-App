import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/s.dart';
import '../theme/app_theme.dart';

const kReportPrompts = [
  'wrong1',
  'wrong2',
  'wrong3',
  'wrong4',
  'wrong5',
  'wrong6',
  'wrong7',
  'wrong8',
];

class ReportChip extends StatefulWidget {
  const ReportChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<ReportChip> createState() => _ReportChipState();
}

class _ReportChipState extends State<ReportChip> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % kReportPrompts.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: MintzerColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: SizedBox(
          width: 154,
          height: 32,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 3, 0),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Text(
                      S.t(kReportPrompts[_i]),
                      key: ValueKey(_i),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3C4043),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: MintzerColors.wa, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.chat, size: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
