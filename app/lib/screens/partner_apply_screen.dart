import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import '../util/shop_url.dart';
import '../widgets/mintzer_toast.dart';

/// Bank apply page inside Mintzer. https only. UPI and phone links leave the page.
class PartnerApplyScreen extends StatefulWidget {
  const PartnerApplyScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<PartnerApplyScreen> createState() => _PartnerApplyScreenState();
}

class _PartnerApplyScreenState extends State<PartnerApplyScreen> {
  late final WebViewController _controller;
  var _loading = true;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            switch (classifyShopNavigation(request.url)) {
              case ShopNavigation.allowPage:
                return NavigationDecision.navigate;
              case ShopNavigation.openOutside:
                final uri = Uri.tryParse(request.url);
                if (uri != null) {
                  unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
                }
                return NavigationDecision.prevent;
              case ShopNavigation.block:
                return NavigationDecision.prevent;
            }
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _loading = false;
              _failed = true;
            });
          },
        ),
      );
    if (classifyShopNavigation(widget.url) == ShopNavigation.allowPage) {
      _controller.loadRequest(Uri.parse(widget.url.trim()));
    } else {
      _loading = false;
      _failed = true;
    }
  }

  Future<void> _openOutside() async {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showMintzerToast(context, 'Couldn’t open apply link', kind: MintzerToastKind.warn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _openOutside,
            child: const Text(
              'Browser',
              style: TextStyle(fontWeight: FontWeight.w700, color: MintzerColors.primary),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _loading
              ? const LinearProgressIndicator(minHeight: 2, color: MintzerColors.primary, backgroundColor: Color(0xFFEDE7FF))
              : const SizedBox(height: 2),
        ),
      ),
      body: _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This bank page did not open inside the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _openOutside,
                      style: FilledButton.styleFrom(backgroundColor: MintzerColors.primary),
                      child: const Text('Open in browser'),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
