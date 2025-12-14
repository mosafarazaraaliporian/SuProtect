import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

class ApiService {
  // Production server URL
  static const String baseUrl = 'http://83.228.227.105:8000';
  
  static const String uploadEndpoint = '/api/v1/upload';
  static const String statusEndpoint = '/api/v1/status';
  static const String downloadEndpoint = '/api/v1/download';

  static Dio? _dio;

  static Dio get dio {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(minutes: 5), // برای فایل‌های بزرگ
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ));
    }
    return _dio!;
  }

  /// Upload APK file to server
  /// Returns job_id for tracking
  static Future<Map<String, dynamic>> uploadApk({
    required File apkFile,
    String? userId,
    Function(double)? onProgress,
  }) async {
    try {
      LoggerService.logApi('POST', '$baseUrl$uploadEndpoint');
      
      String fileName = apkFile.path.split('/').last;
      if (fileName.contains('\\')) {
        fileName = apkFile.path.split('\\').last;
      }
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          apkFile.path,
          filename: fileName,
        ),
        if (userId != null) 'user_id': userId,
      });

      var response = await dio.post(
        uploadEndpoint,
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );
      
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        LoggerService.i('ApiService', 'Upload successful: ${jsonResponse['job_id']}');
        return jsonResponse is Map ? jsonResponse : json.decode(jsonResponse.toString());
      } else {
        LoggerService.e('ApiService', 'Upload failed: ${response.statusCode}');
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      LoggerService.e('ApiService', 'Upload error', e);
      if (e.response != null) {
        var errorBody = e.response!.data;
        String errorMsg = errorBody is Map 
            ? (errorBody['detail'] ?? errorBody['message'] ?? 'Upload failed')
            : errorBody.toString();
        throw Exception(errorMsg);
      } else {
        throw Exception(e.message ?? 'Network error during upload');
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
      
      var response = await dio.get('$statusEndpoint/$jobId');

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        return jsonResponse is Map ? jsonResponse : json.decode(jsonResponse.toString());
      } else if (response.statusCode == 404) {
        throw Exception('Job not found');
      } else {
        throw Exception('Failed to get status');
      }
    } on DioException catch (e) {
      LoggerService.e('ApiService', 'Get status error', e);
      if (e.response?.statusCode == 404) {
        throw Exception('Job not found');
      }
      throw Exception(e.message ?? 'Failed to get status');
    } catch (e) {
      LoggerService.e('ApiService', 'Get status error', e);
      rethrow;
    }
  }

  /// Get download URL
  static Future<String> getDownloadUrl(String jobId) async {
    try {
      LoggerService.logApi('GET', '$baseUrl$downloadEndpoint/$jobId');
      
      var response = await dio.get(
        '$downloadEndpoint/$jobId',
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        // If redirect, get the location header
        if (response.headers.value('location') != null) {
          return response.headers.value('location')!;
        }
        // Otherwise, parse JSON response
        var jsonResponse = response.data;
        if (jsonResponse is Map) {
          return jsonResponse['download_url'] ?? '';
        }
        return '';
      } else {
        throw Exception('Failed to get download URL');
      }
    } on DioException catch (e) {
      LoggerService.e('ApiService', 'Get download URL error', e);
      throw Exception(e.message ?? 'Failed to get download URL');
    } catch (e) {
      LoggerService.e('ApiService', 'Get download URL error', e);
      rethrow;
    }
  }

  /// Check server health
  static Future<bool> checkHealth() async {
    try {
      var response = await dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.e('ApiService', 'Health check error', e);
      return false;
    }
  }
}
