import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Sudah include Uint8List
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
// HAPUS import 'dart:typed_data'; // Tidak diperlukan karena Uint8List sudah ada di services.dart
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

  @override
  void initState() {
    super.initState();
    
    // **PAKSA ATUR STATUS BAR DENGAN IKON PUTIH**
    _forceWhiteStatusBarIcons();
    
    requestPermissions();
  }

  // **FUNGSI UNTUK MEMAKSA IKON STATUS BAR PUTIH**
  void _forceWhiteStatusBarIcons() {
    // Method 1: Set di initState
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparan
      statusBarIconBrightness: Brightness.light, // IKON PUTIH
      statusBarBrightness: Brightness.dark, // Mode dark
      systemNavigationBarColor: Color(0xFF0F0A2A), // Nav bar gelap
      systemNavigationBarIconBrightness: Brightness.light, // Ikon nav putih
    ));
    
    // Method 2: Pakai edgeToEdge mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Method 3: Delay dan set ulang untuk pastikan
    Future.delayed(const Duration(milliseconds: 100), () {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // PUTIH
        systemNavigationBarColor: Color(0xFF0F0A2A),
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    // **SET ULANG SETIAP KALI BUILD UNTUK MEMASTIKAN**
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // PUTIH
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0F0A2A),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // **WRAP DENGAN ANNOTATED REGION UNTUK KONTROL PENUH**
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // PUTIH
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0F0A2A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        // **BACKGROUND UTAMA GELAP**
        backgroundColor: const Color(0xFF0F0A2A),
        body: Container(
          // **CONTAINER UNTUK MEMASTIKAN BACKGROUND GELAP**
          color: const Color(0xFF0F0A2A),
          child: SafeArea(
            // **top: false AGAR CONTENT BISA DI BAWAH STATUS BAR**
            top: false,
            bottom: false,
            child: Column(
              children: [
                // **APP BAR CUSTOM DENGAN BACKGROUND GELAP**
                Container(
                  height: MediaQuery.of(context).padding.top, // Tinggi status bar
                  color: const Color(0xFF0F0A2A), // Background gelap
                ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri("https://xd101-web-dracin.vercel.app/"),
                    ),
                    initialSettings: InAppWebViewSettings(
                      userAgent: "xdtools1010192020 (https://t.me/sniffer101)",
                      javaScriptEnabled: true,
                      allowsInlineMediaPlayback: true,
                      mediaPlaybackRequiresUserGesture: false,
                      useShouldOverrideUrlLoading: true,
                      preferredContentMode: UserPreferredContentMode.DESKTOP,
                      textZoom: 100,
                    ),
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                      setupJavaScriptHandlers();
                      setViewportDPI();
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> setViewportDPI() async {
    await webViewController?.evaluateJavascript(source: """
      document.querySelector('meta[name="viewport"]')?.remove();
      let meta = document.createElement('meta');
      meta.name = "viewport";
      meta.content = "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no";
      document.head.appendChild(meta);
    """);
  }

  // ✅ Hanya buka Telegram original
  Future<void> openTelegram(String url) async {
    const String telegramPackage = "org.telegram.messenger";

    try {
      bool launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception("Telegram tidak terbuka");
      }
    } catch (e) {
      // Jika Telegram tidak terinstal, buka Play Store
      await launchUrl(
        Uri.parse("https://play.google.com/store/apps/details?id=$telegramPackage"),
        mode: LaunchMode.externalApplication,
      );
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
// Utility Functions
// ===========================

Future<String?> pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
  return result?.files.single.path;
}

Future<void> requestPermissions() async {
  await [
    Permission.storage,
    Permission.notification,
    Permission.manageExternalStorage,
  ].request();
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

    if (decodedText.trim().startsWith('{')) {
      // Uint8List dari 'dart:convert' sudah cukup
      Uint8List bytes = utf8.encode(decodedText) as Uint8List;
      showFileNameDialog(bytes, fileName);
      return;
    }

    try {
      Uint8List bytes = base64Decode(encodedData);
      showFileNameDialog(bytes, fileName);
    } catch (e) {
      showSnackbar("Error", "Data format not recognized", false);
    }
  } catch (e) {
    showSnackbar("Error", "Failed to process file: $e", false);
  }
}

void showFileNameDialog(Uint8List data, String defaultName) {
  final controller = TextEditingController(text: defaultName);
  final error = ''.obs;

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF15171E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                const Text(
                  "Save Configuration",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "File Name",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E2029),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                ),
              ),
            ),
            Obx(() => error.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

  showSnackbar("Succeed", "Saved in: ${file.path}", true);
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

  if (name.endsWith(".")) {
    name = name.substring(0, name.length - 1);
  }

  if (!name.contains(".")) {
    return "$name.txt";
  }

  return name;
}

String checkDuplicateFileName(String fileName) {
  Directory dir = Directory("/storage/emulated/0/Download/XD-TOOLS");
  int counter = 1;
  String newName = fileName;
  while (File("${dir.path}/$newName").existsSync()) {
    newName = "${fileName.split('.').first}($counter).${fileName.split('.').last}";
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
    backgroundColor: Colors.white,
    colorText: Colors.black,
    icon: Animate(
      effects: [FadeEffect(duration: 300.ms), ScaleEffect(duration: 300.ms)],
      child: success
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.error, color: Colors.red),
    ),
    snackStyle: SnackStyle.FLOATING,
    animationDuration: const Duration(milliseconds: 500),
    forwardAnimationCurve: Curves.easeOutBack,
    reverseAnimationCurve: Curves.easeInBack,
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
