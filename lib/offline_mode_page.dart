import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'dart:io';

import 'modules_page.dart';

class OfflineModePage extends StatefulWidget {
  const OfflineModePage({super.key});

  @override
  OfflineModePageState createState() => OfflineModePageState();
}

class OfflineModePageState extends State<OfflineModePage> {
  List<File> downloadedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    try {
      // Request storage permissions
      if (Platform.isAndroid) {
        var status =
            await permission_handler.Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required')),
          );
          return;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.pdf') ||
              file.path.endsWith('.mp4') ||
              file.path.endsWith('.mp3'))
          .toList();

      setState(() {
        downloadedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading files: $e')),
        );
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      await _loadDownloadedFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.path.split('/').last} deleted successfully'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  void _openFile(File file) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open file: $e')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String path) {
    if (path.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (path.endsWith('.mp4')) return Icons.video_library;
    if (path.endsWith('.mp3')) return Icons.music_note;
    return Icons.file_present;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Content'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDownloadedFiles,
            tooltip: 'Refresh Files',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            )
          : downloadedFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No offline content available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadDownloadedFiles,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: downloadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = downloadedFiles[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade50,
                          child: Icon(
                            _getFileIcon(file.path),
                            color: Colors.deepPurple,
                          ),
                        ),
                        title: Text(
                          file.path.split('/').last,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Size: ${_formatFileSize(file.lengthSync())}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteFile(file),
                        ),
                        onTap: () => _openFile(file),
                      ),
                    );
                  },
                ),
    );
  }
}

// Module Definition
List<Module> moduleList = [
  Module(
    title: 'Offline Mode',
    description: 'Access your saved content without internet',
    icon: Icons.offline_pin,
    color: Colors.green,
    page: const OfflineModePage(),
  ),
];
