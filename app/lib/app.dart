import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mock/session.dart';
import 'push/push_router.dart';
import 'screens/account_deleted_screen.dart';
import 'screens/account_suspended_screen.dart';
import 'screens/debug_must_test_gate_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_route_args.dart';
import 'screens/otp_screen.dart';
import 'screens/shell.dart';
import 'l10n/s.dart';
import 'theme/app_theme.dart';

class MintzerApp extends StatelessWidget {
  const MintzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MockSession.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Mintzer',
          navigatorKey: MintzerNav.key,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          builder: (context, child) => LangHost(child: child ?? const SizedBox.shrink()),
          initialRoute: MockSession.authToken.isNotEmpty ? '/main' : '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/login/otp': (c) {
              final args = ModalRoute.of(c)?.settings.arguments;
              if (args is OtpRouteArgs) {
                return OtpScreen(phone: args.phone, sendFuture: args.sendFuture);
              }
              final phone = args is String ? args : '';
              return OtpScreen(phone: phone);
            },
            '/intro': (_) => const IntroScreen(),
            '/suspended': (_) => const AccountSuspendedScreen(),
            '/account-deleted': (_) => const AccountDeletedScreen(),
            '/main': (_) => const AppShell(),
            if (kDebugMode) '/debug/must-test': (_) => const DebugMustTestGateScreen(),
          },
        );
      },
    );
  }
}
