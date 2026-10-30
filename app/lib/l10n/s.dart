import 'package:flutter/widgets.dart';

import '../mock/session.dart';
import 'extra_l10n.dart';
import 'strings.dart';

/// Rebuilds dependents when Profile or Login changes language.
class LangScope extends InheritedWidget {
  const LangScope({required this.lang, required super.child, super.key});

  final String lang;

  static String watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LangScope>();
    return scope?.lang ?? MockSession.language;
  }

  @override
  bool updateShouldNotify(LangScope oldWidget) => lang != oldWidget.lang;
}

class LangHost extends StatefulWidget {
  const LangHost({required this.child, super.key});

  final Widget child;

  @override
  State<LangHost> createState() => _LangHostState();
}

class _LangHostState extends State<LangHost> {
  @override
  void initState() {
    super.initState();
    MockSession.languageRevision.addListener(_onLang);
  }

  void _onLang() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MockSession.languageRevision.removeListener(_onLang);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(lang: MockSession.language, child: widget.child);
  }
}

/// Short lookup. Call [watch] once in each screen `build` so a language
/// change repaints that screen. Child widgets can then call [t] only.
class S {
  static String watch(BuildContext context) => LangScope.watch(context);

  static String t(String key, [Map<String, String>? vars]) => L10n.t(MockSession.language, key, vars);

  /// Translate a locked English sentence. English stays as written.
  static String e(String english) => ExtraL10n.map(MockSession.language)[english] ?? english;
}
