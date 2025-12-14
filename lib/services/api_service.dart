import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

class ApiService {
  // Production server URL
  static const String baseUrl = 'http://83.228.227.105:8000';
  
  static const String uploadEndpoint = '/api/v1/upload';
  static const String statusEndpoint = '/api/v1/status';
  static const String downloadEndpoint = '/api/v1/download';

  /// Upload APK file to server
  /// Returns job_id for tracking
  static Future<Map<String, dynamic>> uploadApk({
    required File apkFile,
    String? userId,
    Function(double)? onProgress,
  }) async {
    try {
      LoggerService.logApi('POST', '$baseUrl$uploadEndpoint');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadEndpoint'),
      );

      // Add file
      var fileStream = apkFile.openRead();
      var fileLength = await apkFile.length();
      
      var multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: apkFile.path.split('/').last,
      );
      
      request.files.add(multipartFile);
      
      // Add user_id if provided
      if (userId != null) {
        request.fields['user_id'] = userId;
      }

      // Send request with progress tracking
      var streamedResponse = await request.send();
      
      // Track upload progress
      int totalBytes = fileLength;
      int receivedBytes = 0;
      
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        LoggerService.i('ApiService', 'Upload successful: ${jsonResponse['job_id']}');
        return jsonResponse;
      } else {
        var errorBody = json.decode(response.body);
        LoggerService.e('ApiService', 'Upload failed: ${errorBody['detail']}');
        throw Exception(errorBody['detail'] ?? 'Upload failed');
      }
    } catch (e) {
      LoggerService.e('ApiService', 'Upload error', e);
      rethrow;
    }
  }

  /// Get job status
  static Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    try {
      LoggerService.logApi('GET', '$baseUrl$statusEndpoint/$jobId');
      
      final response = await http.get(
        Uri.parse('$baseUrl$statusEndpoint/$jobId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else if (response.statusCode == 404) {
        throw Exception('Job not found');
      } else {
        var errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to get status');
      }
    } catch (e) {
      LoggerService.e('ApiService', 'Get status error', e);
      rethrow;
    }
  }

  /// Get download URL
  static Future<String> getDownloadUrl(String jobId) async {
    try {
      LoggerService.logApi('GET', '$baseUrl$downloadEndpoint/$jobId');
      
      final response = await http.get(
        Uri.parse('$baseUrl$downloadEndpoint/$jobId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        // If redirect, get the location header
        if (response.headers.containsKey('location')) {
          return response.headers['location']!;
        }
        // Otherwise, parse JSON response
        var jsonResponse = json.decode(response.body);
        return jsonResponse['download_url'] ?? '';
      } else {
        var errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to get download URL');
      }
    } catch (e) {
      LoggerService.e('ApiService', 'Get download URL error', e);
      rethrow;
    }
  }

  /// Check server health
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.e('ApiService', 'Health check error', e);
      return false;
    }
  }
}

