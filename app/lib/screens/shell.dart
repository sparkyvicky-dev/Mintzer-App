import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/s.dart';
import '../mock/session.dart';
import '../theme/app_theme.dart';
import '../widgets/help_ticket_sheet.dart';
import '../widgets/mintzer_toast.dart';
import '../util/notification_permission.dart';
import '../widgets/play_update_prompt.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  DateTime? _lastBackAt;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // Build once — recreating HomeScreen every rebuild stalled View deals.
    _tabs = [
      HomeScreen(onWallet: () => MockSession.tabIndex.value = 2),
      const OrdersScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];
    MockSession.tabIndex.addListener(_rebuild);
    MockSession.homeChrome.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await NotificationPermission.maybeAskOnFirstHome(context);
      if (!mounted) return;
      PlayUpdatePrompt.maybeAsk(context);
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MockSession.tabIndex.removeListener(_rebuild);
    MockSession.homeChrome.removeListener(_rebuild);
    super.dispose();
  }

  void _onBack() {
    if (MockSession.tabIndex.value != 0) {
      MockSession.tabIndex.value = 0;
      return;
    }
    final now = DateTime.now();
    if (_lastBackAt != null && now.difference(_lastBackAt!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackAt = now;
    showMintzerToast(
      context,
      S.e('Press back again to exit'),
      kind: MintzerToastKind.info,
      icon: Icons.logout_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = MockSession.tabIndex.value;
    final onHome = index == 0;
    final mini = onHome && MockSession.homeChrome.value > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: ValueListenableBuilder<PlayUpdatePhase>(
          valueListenable: PlayUpdatePrompt.phase,
          builder: (context, phase, _) {
            return Column(
              children: [
                if (phase != PlayUpdatePhase.idle) _UpdateBar(phase: phase),
                Expanded(child: IndexedStack(index: index, children: _tabs)),
              ],
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: onHome ? const _HelpFab() : null,
        bottomNavigationBar: _MintzerBottomNav(
          index: index,
          mini: mini,
          onSelect: (i) {
            FocusManager.instance.primaryFocus?.unfocus();
            if (i != 0) MockSession.homeChrome.value = 0;
            MockSession.tabIndex.value = i;
          },
        ),
      ),
    );
  }
}

class _UpdateBar extends StatelessWidget {
  const _UpdateBar({required this.phase});

  final PlayUpdatePhase phase;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final ready = phase == PlayUpdatePhase.ready;
    return Material(
      color: const Color(0xFF7B61FF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ready ? S.e('Update ready') : S.e('Downloading update…'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              if (ready)
                TextButton(
                  onPressed: PlayUpdatePrompt.restart,
                  child: Text(
                    S.e('Restart'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 56px circle above nav — expands to “Help” on tap, then opens sheet.
class _HelpFab extends StatefulWidget {
  const _HelpFab();

  @override
  State<_HelpFab> createState() => _HelpFabState();
}

class _HelpFabState extends State<_HelpFab> {
  bool _expanded = false;

  Future<void> _open() async {
    setState(() => _expanded = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await showHelpTicketSheet(context);
    if (mounted) setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: MintzerColors.fabPurple,
        elevation: 4,
        shadowColor: const Color(0x407B61FF),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _open,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 56,
            width: _expanded ? 112 : 56,
            padding: EdgeInsets.symmetric(horizontal: _expanded ? 16 : 0),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
                if (_expanded) ...[
                  const SizedBox(width: 8),
                  Text(
                    S.t('help'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Demo chrome: full bar with labels · scroll → floating pill, icons only.
class _MintzerBottomNav extends StatelessWidget {
  const _MintzerBottomNav({
    required this.index,
    required this.mini,
    required this.onSelect,
  });

  final int index;
  final bool mini;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'nav_home'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'nav_orders'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'nav_wallet'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'nav_profile'),
  ];

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(mini ? 48 : 0, 0, mini ? 48 : 0, mini ? 10 + bottom * 0.25 : 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: (mini ? 46 : 60) + (mini ? 0 : bottom),
        padding: EdgeInsets.only(bottom: mini ? 0 : bottom, top: mini ? 4 : 4, left: 6, right: 6),
        decoration: BoxDecoration(
          color: const Color(0xF0FFFFFF),
          borderRadius: mini ? BorderRadius.circular(28) : BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Color(mini ? 0x2E7B61FF : 0x147B61FF),
              blurRadius: mini ? 18 : 8,
              offset: Offset(0, mini ? 6 : -2),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavItem(
                  icon: index == i ? _items[i].$2 : _items[i].$1,
                  label: S.t(_items[i].$3),
                  selected: index == i,
                  mini: mini,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.mini,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool mini;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    S.watch(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(vertical: mini ? 8 : 6),
          decoration: BoxDecoration(
            color: selected ? MintzerColors.spendFill : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: selected ? MintzerColors.primary : MintzerColors.muted),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: mini
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? MintzerColors.primary : MintzerColors.muted,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
