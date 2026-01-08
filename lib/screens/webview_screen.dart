import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;

  static const String _homeUrl = "https://xd101-web-dracin.vercel.app/";
  static const String _appName = "X-DRAMA";
  static const String _logoUrl = "https://i.postimg.cc/NYWwG4vy/20260108-142703.png";

  @override
  void initState() {
    super.initState();

    // ANDROID: status bar hitam + ikon putih
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    // Jangan edgeToEdge/immersive biar layout rapi
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Back di web kalau bisa
        if (_controller != null && await _controller!.canGoBack()) {
          await _controller!.goBack();
          return;
        }

        // Kalau tidak bisa, konfirmasi exit
        final exit = await _showSoftExitSheet();
        if (exit == true) {
          if (!mounted) return;
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: true,
          bottom: true, // ✅ tidak lewat navigation bar
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_homeUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
              allowsInlineMediaPlayback: true,
              mediaPlaybackRequiresUserGesture: false,
              preferredContentMode: UserPreferredContentMode.DESKTOP,
              textZoom: 100,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              _setViewport();
            },

            // FIX deprecated: onLoadError -> onReceivedError
            onReceivedError: (controller, request, error) {},

            shouldOverrideUrlLoading: (controller, action) async {
              final uri = action.request.url;
              if (uri == null) return NavigationActionPolicy.ALLOW;

              final s = uri.toString();

              // Telegram external
              if (s.startsWith("tg://") || s.startsWith("https://t.me/")) {
                await _launchExternal(s);
                return NavigationActionPolicy.CANCEL;
              }

              // Binance external (opsional)
              if (s.contains("binance.com") || s.contains("s.binance.com")) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationActionPolicy.CANCEL;
              }

              return NavigationActionPolicy.ALLOW;
            },
          ),
        ),
      ),
    );
  }

  Future<void> _setViewport() async {
    await _controller?.evaluateJavascript(source: """
      var meta = document.querySelector('meta[name="viewport"]');
      if (!meta) {
        meta = document.createElement('meta');
        meta.name = "viewport";
        document.head.appendChild(meta);
      }
      meta.content = "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no";
    """);
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && url.startsWith("tg://")) {
      final converted = url.replaceFirst("tg://", "https://t.me/");
      await launchUrl(Uri.parse(converted), mode: LaunchMode.externalApplication);
    }
  }

  // ===============================
  // EXIT BOTTOM SHEET (SOFT / SMOOTH)
  // ===============================
  Future<bool?> _showSoftExitSheet() async {
    if (!mounted) return false;

    // Soft colors (neon dikurangi)
    const bg1 = Color(0xFF0D0F14);
    const bg2 = Color(0xFF141826);
    const accent = Color(0xFFFF4FC3); // pink soft

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45), // hitam tapi tidak terlalu
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                // glow tipis, biar smooth
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 18,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // handle kecil
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _LogoBadge(url: _logoUrl, accent: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Keluar aplikasi?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Yakin ingin menutup $_appName?",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Batal"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent.withValues(alpha: 0.88),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Keluar"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.url, required this.accent});

  final String url;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.apps_rounded,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
