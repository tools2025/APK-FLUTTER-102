import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

final AudioPlayer _audioPlayer = AudioPlayer();

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? webViewController;
  double _progress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    requestPermissions();

    // Status bar transparan + icon putih + edge-to-edge
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background hitam penuh sampai atas
          Container(color: Colors.black),

          // Konten utama: WebView dengan padding atas
          Column(
            children: [
              // Progress bar tipis di atas (hanya muncul saat loading)
              if (_progress < 1.0)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  minHeight: 2,
                ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: statusBarHeight),
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri("https://xd101-web-dracin.vercel.app/"),
                    ),
                    initialSettings: InAppWebViewSettings(
                      userAgent: "xdtools1010192020[](https://t.me/sniffer101)",
                      javaScriptEnabled: true,
                      allowsInlineMediaPlayback: true,
                      mediaPlaybackRequiresUserGesture: false,
                      useShouldOverrideUrlLoading: true,
                      preferredContentMode: UserPreferredContentMode.DESKTOP,
                      textZoom: 100,
                      transparentBackground: false,
                    ),
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                      setupJavaScriptHandlers();
                      setViewportDPI();
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _isLoading = true;
                        _progress = 0;
                      });
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                    onLoadStop: (controller, url) {
                      setState(() {
                        _isLoading = false;
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      setState(() {
                        _isLoading = false;
                      });
                      showSnackbar("Error", "Failed to load page", false);
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      final uri = navigationAction.request.url;
                      if (uri != null) {
                        String urlString = uri.toString();
                        if (urlString.startsWith("tg://") || urlString.startsWith("https://t.me/")) {
                          await openTelegram(urlString);
                          return NavigationActionPolicy.CANCEL;
                        }
                        if (urlString.contains("binance.com") || urlString.contains("s.binance.com")) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onDownloadStartRequest: (controller, request) async {
                      final url = request.url.toString();
                      if (url.startsWith("data:")) {
                        handleDataUrlDownload(
                          dataUrl: url,
                          mimeType: request.mimeType ?? "application/octet-stream",
                          contentDisposition: request.contentDisposition,
                        );
                      }
                    },
                    pullToRefreshController: PullToRefreshController(
                      settings: PullToRefreshSettings(color: const Color(0xFF8B5CF6)),
                      onRefresh: () async {
                        await webViewController?.reload();
                      },
                    ),
                    onEnterFullscreen: (controller) {
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                    },
                    onExitFullscreen: (controller) {
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                    },
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay (opsional, lebih elegan)
          if (_isLoading && _progress < 1.0)
            Container(
              color: Colors.black.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading XD-TOOLS...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> setViewportDPI() async {
    await webViewController?.evaluateJavascript(source: """
      var meta = document.querySelector('meta[name="viewport"]');
      if (!meta) {
        meta = document.createElement('meta');
        meta.name = "viewport";
        document.head.appendChild(meta);
      }
      meta.content = "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no";
    """);
  }

  Future<void> openTelegram(String url) async {
    try {
      final uri = Uri.parse(url);
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (url.startsWith("tg://")) {
          final convertedUrl = url.replaceFirst("tg://", "https://t.me/");
          await launchUrl(Uri.parse(convertedUrl), mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=org.telegram.messenger"),
              mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      await launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=org.telegram.messenger"),
          mode: LaunchMode.externalApplication);
    }
  }

  void setupJavaScriptHandlers() {
    webViewController?.addJavaScriptHandler(
      handlerName: "filePicker",
      callback: (args) async => await pickFile(),
    );

    webViewController?.evaluateJavascript(source: """
      document.addEventListener('click', function(event) {
        let target = event.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }
        if (target && target.hasAttribute('download')) {
          let fileName = target.getAttribute('download') || 'results';
          let fileUrl = target.href;
          window.flutter_inappwebview.callHandler('onDownloadFile', fileName, fileUrl);
        }
      });
    """);

    webViewController?.addJavaScriptHandler(
      handlerName: "onDownloadFile",
      callback: (args) {
        String fileName = args[0];
        String fileUrl = args[1];
        if (fileUrl.startsWith("data:")) {
          handleDataUrlDownload(
            dataUrl: fileUrl,
            mimeType: "application/octet-stream",
            contentDisposition: 'filename="$fileName"',
          );
        }
      },
    );
  }
}

// ===========================
// Semua Utility Functions (tetap sama, hanya sedikit rapih)
// ===========================

Future<String?> pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
  return result?.files.single.path;
}

Future<void> requestPermissions() async {
  await [Permission.storage, Permission.notification, Permission.manageExternalStorage].request();
}

Future<void> handleDataUrlDownload({
  required String dataUrl,
  required String mimeType,
  String? contentDisposition,
}) async {
  try {
    final parts = dataUrl.split(',');
    if (parts.length < 2) {
      showSnackbar("Error", "Invalid URL Data Format", false);
      return;
    }
    String encodedData = parts[1];
    String decodedText = Uri.decodeComponent(encodedData);
    String fileName = extractFileName(contentDisposition) ??
        extractFileNameFromDataUrl(dataUrl) ??
        "results";
    fileName = checkDuplicateFileName(ensureFileExtension(fileName, mimeType));

    Uint8List bytes;
    if (decodedText.trim().startsWith('{')) {
      bytes = utf8.encode(decodedText);
    } else {
      try {
        bytes = base64Decode(encodedData);
      } catch (e) {
        showSnackbar("Error", "Data format not recognized", false);
        return;
      }
    }
    showFileNameDialog(bytes, fileName);
  } catch (e) {
    showSnackbar("Error", "Failed to process file: $e", false);
  }
}

void showFileNameDialog(Uint8List data, String defaultName) {
  final controller = TextEditingController(text: defaultName);
  final error = ''.obs;

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF15171E),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.save_alt, color: Color(0xFF8B5CF6), size: 28),
                const SizedBox(width: 12),
                const Text(
                  "Save Configuration",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "File Name",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E2029),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                ),
              ),
            ),
            Obx(() => error.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error.value, style: const TextStyle(color: Colors.red)),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        error.value = "File name cannot be empty.";
                      } else {
                        error.value = "";
                        saveFile(data, checkDuplicateFileName(name));
                        Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

Future<void> saveFile(Uint8List data, String name) async {
  Directory dir = Directory("/storage/emulated/0/Download/XD-TOOLS");
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File file = File("${dir.path}/$name");
  await file.writeAsBytes(data);
  showSnackbar("Success", "Saved to: ${file.path}", true);
}

String? extractFileName(String? header) {
  if (header == null) return null;
  final idx = header.indexOf("filename=");
  if (idx == -1) return null;
  return Uri.decodeFull(header.substring(idx + 9).replaceAll('"', ''));
}

String? extractFileNameFromDataUrl(String dataUrl) {
  final regex = RegExp(r'filename=([^;]+)');
  final match = regex.firstMatch(dataUrl);
  return match != null ? Uri.decodeComponent(match.group(1)!.replaceAll('"', '')) : null;
}

String ensureFileExtension(String name, String mimeType) {
  name = name.trim();
  if (name.endsWith(".")) name = name.substring(0, name.length - 1);
  if (!name.contains(".")) return "$name.txt";
  return name;
}

String checkDuplicateFileName(String fileName) {
  Directory dir = Directory("/storage/emulated/0/Download/XD-TOOLS");
  int counter = 1;
  String newName = fileName;
  while (File("${dir.path}/$newName").existsSync()) {
    final parts = fileName.split('.');
    final ext = parts.length > 1 ? '.${parts.last}' : '';
    final base = parts.length > 1 ? fileName.substring(0, fileName.length - ext.length) : fileName;
    newName = "$base($counter)$ext";
    counter++;
  }
  return newName;
}

void showSnackbar(String title, String message, bool success) {
  success ? playSuccessSound() : playErrorSound();
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 12,
    icon: Animate(
      effects: const [FadeEffect(), ScaleEffect()],
      child: Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
    ).animate().scale(duration: 300.ms),
    duration: const Duration(seconds: 3),
  );
}

void playSuccessSound() async {
  try {
    await _audioPlayer.stop();
    await _audioPlayer.setSource(AssetSource("sounds/usb_connect.mp3"));
    await _audioPlayer.resume();
  } catch (_) {}
}

void playErrorSound() async {
  try {
    await _audioPlayer.stop();
    await _audioPlayer.setSource(AssetSource("sounds/usb_disconnect.mp3"));
    await _audioPlayer.resume();
  } catch (_) {}
}
