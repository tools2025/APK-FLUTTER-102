import 'package:flutter/material.dart';

class FileNameDialog extends StatefulWidget {
  final String initialName;
  final Function(String) onSave;

  const FileNameDialog({super.key, required this.initialName, required this.onSave});

  @override
  State<FileNameDialog> createState() => _FileNameDialogState();
}

class _FileNameDialogState extends State<FileNameDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialName);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dengan ikon dan teks
            Row(
              children: [
                const Icon(Icons.save, size: 40, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  "Save",
                  style: TextStyle(fontSize: 25, fontFamily: 'Poppins', color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Label
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Enter Filename",
                style: TextStyle(fontSize: 16, fontFamily: 'Poppins', color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),

            // Input field
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.greenAccent),
              decoration: InputDecoration(
                hintText: "config.txt",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol aksi
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(controller.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save", style: TextStyle(color: Colors.greenAccent)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
