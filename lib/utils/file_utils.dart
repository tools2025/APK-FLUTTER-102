import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

final AudioPlayer _audioPlayer = AudioPlayer();


Future<String?> pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
  return result?.files.single.path;
}

Future<void> handleDataUrlDownload({
  required String dataUrl,
  required String mimeType,
  String? contentDisposition,
}) async {
  try {
    final parts = dataUrl.split(',');
    if (parts.length < 2) {
      showSnackbar("Error", "Format Data URL tidak valid", false);
      return;
    }

    final Uint8List bytes = base64Decode(parts[1]);
    String fileName = extractFileNameFromDisposition(contentDisposition) ?? "downloaded_file";
    fileName = ensureFileExtension(fileName, mimeType);
    showFileNameDialog(bytes, fileName);
  } catch (e) {
    showSnackbar("Error", "Gagal memproses file: $e", false);
  }
}


void showFileNameDialog(Uint8List data, String defaultName) {
  final controller = TextEditingController(text: defaultName);
  final error = ''.obs;

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("Save File", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "File name",
                border: OutlineInputBorder(),
              ),
            ),
            Obx(() => error.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error.value, style: TextStyle(color: Colors.red)),
                  )
                : SizedBox.shrink()),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text("Cancel"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        error.value = "Nama file tidak boleh kosong";
                      } else {
                        error.value = "";
                        saveFile(data, ensureFileExtension(name, "application/octet-stream"));
                        Get.back();
                      }
                    },
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
  Directory dir = Platform.isAndroid
      ? Directory("/storage/emulated/0/Download/XD-TOOLS")
      : await getApplicationDocumentsDirectory();

  if (!dir.existsSync()) dir.createSync(recursive: true);

  String baseName = name.contains(".") ? name.split(".").first : name;
  String ext = name.contains(".") ? name.split(".").last : "txt";
  String path = "${dir.path}/$name";
  int count = 1;

  while (File(path).existsSync()) {
    path = "${dir.path}/$baseName($count).$ext";
    count++;
  }

  File file = File(path);
  await file.writeAsBytes(data);

  showSnackbar("Berhasil", "Disimpan di: $path", true);
}

String? extractFileNameFromDisposition(String? header) {
  if (header == null) return null;
  final idx = header.indexOf("filename=");
  if (idx == -1) return null;
  return Uri.decodeFull(header.substring(idx + 9).replaceAll('"', ''));
}

String ensureFileExtension(String name, String mimeType) {
  if (!name.contains(".")) {
    return "$name.txt";
  }
  return name;
}

void showSnackbar(String title, String message, bool success) {
  success ? playSuccessSound() : playErrorSound();
  Get.snackbar(title, message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black);
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
