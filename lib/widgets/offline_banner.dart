import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';

/// A banner that overlays the top of the screen when internet connectivity
/// is lost. Uses the browser's online/offline events (web-only).
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  late final StreamSubscription _onlineSub;
  late final StreamSubscription _offlineSub;

  @override
  void initState() {
    super.initState();
    _isOffline = !(html.window.navigator.onLine ?? true);
    _onlineSub = html.window.onOnline.listen((_) {
      if (!mounted) return;
      setState(() => _isOffline = false);
    });
    _offlineSub = html.window.onOffline.listen((_) {
      if (!mounted) return;
      setState(() => _isOffline = true);
    });
  }

  @override
  void dispose() {
    _onlineSub.cancel();
    _offlineSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: _isOffline ? 0 : -60,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No internet connection',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => html.window.location.reload(),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
