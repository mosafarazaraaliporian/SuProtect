import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/firebase_service.dart';

class UploadApkScreen extends StatefulWidget {
  const UploadApkScreen({super.key});

  @override
  State<UploadApkScreen> createState() => _UploadApkScreenState();
}

class _UploadApkScreenState extends State<UploadApkScreen> {
  File? _selectedFile;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String? _uploadStatus;
  String? _errorMessage;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _uploadProgress = 0.0;
          _uploadStatus = null;
          _errorMessage = null;
        });

        // Log file selection to analytics
        await FirebaseService().logEvent('apk_file_selected', {
          'file_name': result.files.single.name,
          'file_size': result.files.single.size,
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file: ${e.toString()}';
      });
      FirebaseService().logError(e, null);
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an APK file first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
      _errorMessage = null;
    });

    try {
      // TODO: Replace with your actual server URL
      const String uploadUrl = 'https://your-server.com/api/upload-apk';
      
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'apk',
          _selectedFile!.path,
        ),
      );

      // Track upload progress
      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          throw Exception('Upload timeout');
        },
      );

      // Listen to upload progress
      streamedResponse.stream.listen(
        (List<int> chunk) {
          // Calculate progress (approximate)
          setState(() {
            _uploadProgress = (_uploadProgress + 0.1).clamp(0.0, 0.9);
            _uploadStatus = 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%';
          });
        },
        onDone: () async {
          var response = await http.Response.fromStream(streamedResponse);
          
          if (response.statusCode == 200) {
            setState(() {
              _uploadProgress = 1.0;
              _uploadStatus = 'Upload completed successfully!';
              _isUploading = false;
            });

            // Log successful upload
            await FirebaseService().logEvent('apk_upload_success', {
              'file_name': _selectedFile!.path.split('/').last,
            });

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('APK uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }

            // Reset after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _selectedFile = null;
                  _uploadProgress = 0.0;
                  _uploadStatus = null;
                });
              }
            });
          } else {
            throw Exception('Upload failed: ${response.statusCode}');
          }
        },
        onError: (error) {
          setState(() {
            _isUploading = false;
            _errorMessage = 'Upload error: ${error.toString()}';
            _uploadStatus = 'Upload failed';
          });
          FirebaseService().logError(error, null);
        },
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error: ${e.toString()}';
        _uploadStatus = 'Upload failed';
      });
      FirebaseService().logError(e, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFileSize() {
    if (_selectedFile == null) return '';
    final bytes = _selectedFile!.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload APK'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.upload_file,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            Text(
              'Upload APK File',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select an APK file from your device to upload',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // File selection card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_selectedFile == null) ...[
                      const Icon(
                        Icons.insert_drive_file,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No file selected',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.android,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFile!.path.split('/').last,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getFileSize(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Select file button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select APK File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upload button
            ElevatedButton.icon(
              onPressed: (_selectedFile == null || _isUploading)
                  ? null
                  : _uploadFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Uploading...' : 'Upload to Server'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            
            // Progress indicator
            if (_isUploading || _uploadProgress > 0) ...[
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      if (_uploadStatus != null) ...[
                        Text(
                          _uploadStatus!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

