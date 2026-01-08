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

    // jangan edgeToEdge/immersive, biar layout aman
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: true,
        bottom: false,
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

          // FIX deprecated: pakai onReceivedError
          onReceivedError: (controller, request, error) {
            // kosongin aja (atau handle kalau mau)
          },

          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final uri = navigationAction.request.url;
            if (uri == null) return NavigationActionPolicy.ALLOW;

            final s = uri.toString();

            // Telegram -> buka external
            if (s.startsWith("tg://") || s.startsWith("https://t.me/")) {
              await _launchExternal(s);
              return NavigationActionPolicy.CANCEL;
            }

            // Binance -> external
            if (s.contains("binance.com") || s.contains("s.binance.com")) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationActionPolicy.CANCEL;
            }

            return NavigationActionPolicy.ALLOW;
          },
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
}
