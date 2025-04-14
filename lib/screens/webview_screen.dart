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

  @override
  void initState() {
    super.initState();
    requestPermissions();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0F0A2A),
      statusBarIconBrightness: Brightness.light,

    ));
  }



@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri("https://v2rayjson-conver-production.up.railway.app/"),
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
      Uint8List bytes = utf8.encode(decodedText);
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
      backgroundColor: Color(0xFF15171E), // Warna latar belakang sesuai gambar
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, color: Color(0xFF8B5CF6)), // Warna ikon sesuai gambar
                SizedBox(width: 8),
                Text(
                  "Save Configuration",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Warna teks putih sesuai gambar
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close, color: Colors.white), // Warna ikon close putih
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: controller,
              style: TextStyle(color: Colors.white), // Warna teks input putih
              decoration: InputDecoration(
                labelText: "File Name",
                labelStyle: TextStyle(color: Colors.white70), // Warna label sedikit redup
                filled: true,
                fillColor: Color(0xFF1E2029), // Warna latar input sesuai gambar
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFF8B5CF6)), // Warna border ungu sesuai gambar
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFF8B5CF6), width: 2),
                ),
              ),
            ),
            Obx(() => error.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error.value,
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : SizedBox.shrink()),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF8B5CF6)), // Warna border ungu
                      foregroundColor: Colors.white, // Warna teks putih
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Cancel"),
                  ),
                ),
                SizedBox(width: 10),
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
                      backgroundColor: Color(0xFF8B5CF6), // Warna tombol sesuai gambar
                      foregroundColor: Colors.white, // Warna teks putih
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Save"),
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
  // Hapus spasi di awal dan akhir
  name = name.trim();

  // Jika nama diakhiri dengan titik ".", hapus titik tersebut
  if (name.endsWith(".")) {
    name = name.substring(0, name.length - 1);
  }

  // Jika tidak memiliki ekstensi (tidak ada titik di dalam nama)
  if (!name.contains(".")) {
    return "$name.txt"; // Tambahkan ekstensi default ".txt"
  }

  return name; // Jika sudah memiliki ekstensi, biarkan
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
          ? Icon(Icons.check_circle, color: Colors.green)
          : Icon(Icons.error, color: Colors.red),
    ),
    snackStyle: SnackStyle.FLOATING,
    animationDuration: Duration(milliseconds: 500),
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
