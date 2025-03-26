// This file is part of the Soma-Buddy application.
// It provides the OfflineModePage for managing offline content.
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'modules_page.dart';

class OfflineModePage extends StatefulWidget {
  const OfflineModePage({super.key});

  @override
  _OfflineModePageState createState() => _OfflineModePageState();
}

class _OfflineModePageState extends State<OfflineModePage> {
  List<File> downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().whereType<File>().toList();
    setState(() {
      downloadedFiles = files;
    });
  }

  Future<void> _deleteFile(File file) async {
    await file.delete();
    _loadDownloadedFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode'),
        backgroundColor: Colors.deepPurple,
      ),
      body: downloadedFiles.isEmpty
          ? const Center(
              child: Text(
                'No offline content available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: downloadedFiles.length,
              itemBuilder: (context, index) {
                final file = downloadedFiles[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(
                      file.path.endsWith('.pdf')
                          ? Icons.picture_as_pdf
                          : Icons.video_library,
                      color: Colors.deepPurple,
                    ),
                    title: Text(file.path.split('/').last),
                    subtitle: Text(
                        'Size: ${(file.lengthSync() / 1024).toStringAsFixed(2)} KB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFile(file),
                    ),
                    onTap: () {
                      // Add functionality to open the file
                    },
                  ),
                );
              },
            ),
    );
  }
}

List<Module> moduleList = [
  Module(
    title: 'Offline Mode',
    description: 'Access your saved content without internet',
    icon: Icons.offline_pin,
    color: Colors.green,
    page: const OfflineModePage(),
  ),
];
