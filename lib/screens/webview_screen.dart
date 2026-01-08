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

  @override
  void initState() {
    super.initState();

    // ANDROID: status bar hitam + ikon putih
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    // Jangan edgeToEdge/immersive biar aman & rapih
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // kita handle sendiri
      onPopInvokedWithResult: (didPop, result) async {
        // didPop true berarti sudah dipop oleh sistem (jarang karena canPop false)
        if (didPop) return;

        // 1) kalau web bisa back, back di web
        if (_controller != null && await _controller!.canGoBack()) {
          await _controller!.goBack();
          return;
        }

        // 2) kalau tidak bisa, tampilkan dialog exit
        final exit = await _showNeonExitSheet();
        if (exit == true) {
          // Aman dari "context across async gap"
          if (!mounted) return;
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: true,
          bottom: true, // ✅ tidak lewat navigation bar bawah
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri("https://xd101-web-dracin.vercel.app/"),
            ),
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

            // deprecated fix
            onReceivedError: (controller, request, error) {},

            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri == null) return NavigationActionPolicy.ALLOW;

              final s = uri.toString();

              // Telegram -> external
              if (s.startsWith("tg://") || s.startsWith("https://t.me/")) {
                await _launchExternal(s);
                return NavigationActionPolicy.CANCEL;
              }

              // contoh: binance external kalau perlu
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

    // fallback tg:// -> https://t.me/
    if (!ok && url.startsWith("tg://")) {
      final converted = url.replaceFirst("tg://", "https://t.me/");
      await launchUrl(Uri.parse(converted), mode: LaunchMode.externalApplication);
    }
  }

  // ===============================
  // NEON PINK EXIT BOTTOM SHEET
  // ===============================
  Future<bool?> _showNeonExitSheet() async {
    if (!mounted) return false;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0B16),
                  Color(0xFF2A0F22),
                ],
              ),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2FB3).withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // handle
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),

                // icon neon
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2FB3), Color(0xFFB026FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2FB3).withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.power_settings_new, color: Colors.white),
                ),

                const SizedBox(height: 14),
                const Text(
                  "Keluar Aplikasi?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Yakin ingin menutup XD-TOOLS?",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          backgroundColor: const Color(0xFFFF2FB3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
