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
  static const String registerEndpoint = '/api/v1/auth/register';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String meEndpoint = '/api/v1/auth/me';

  static Dio? _dio;
  static String? _accessToken;

  static Dio get dio {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(minutes: 15),
        sendTimeout: const Duration(minutes: 15),
        headers: {
          'Content-Type': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
      ));
    }
    return _dio!;
  }

  static void setAccessToken(String? token) {
    _accessToken = token;
    if (_dio != null) {
      _dio!.options.headers['Authorization'] = token != null ? 'Bearer $token' : null;
    }
  }

  static void clearAuth() {
    _accessToken = null;
    if (_dio != null) {
      _dio!.options.headers.remove('Authorization');
    }
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
      });

      var response = await dio.post(
        uploadEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: const Duration(minutes: 15),
          receiveTimeout: const Duration(minutes: 15),
        ),
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

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    try {
      LoggerService.logApi('POST', '$baseUrl$registerEndpoint');
      
      var response = await dio.post(
        registerEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
      );
      
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        if (jsonResponse is Map && jsonResponse['access_token'] != null) {
          setAccessToken(jsonResponse['access_token']);
        }
        return jsonResponse is Map ? jsonResponse : json.decode(jsonResponse.toString());
      } else {
        throw Exception('Registration failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      LoggerService.e('ApiService', 'Register error', e);
      if (e.response != null) {
        var errorBody = e.response!.data;
        String errorMsg = errorBody is Map 
            ? (errorBody['detail'] ?? errorBody['message'] ?? 'Registration failed')
            : errorBody.toString();
        throw Exception(errorMsg);
      }
      throw Exception(e.message ?? 'Network error during registration');
    } catch (e) {
      LoggerService.e('ApiService', 'Register error', e);
      rethrow;
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    try {
      LoggerService.logApi('POST', '$baseUrl$loginEndpoint');
      
      var response = await dio.post(
        loginEndpoint,
        data: {
          'email': email,
          'password': password,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
      );
      
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        if (jsonResponse is Map && jsonResponse['access_token'] != null) {
          setAccessToken(jsonResponse['access_token']);
        }
        return jsonResponse is Map ? jsonResponse : json.decode(jsonResponse.toString());
      } else {
        throw Exception('Login failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      LoggerService.e('ApiService', 'Login error', e);
      if (e.response != null) {
        var errorBody = e.response!.data;
        String errorMsg = errorBody is Map 
            ? (errorBody['detail'] ?? errorBody['message'] ?? 'Login failed')
            : errorBody.toString();
        throw Exception(errorMsg);
      }
      throw Exception(e.message ?? 'Network error during login');
    } catch (e) {
      LoggerService.e('ApiService', 'Login error', e);
      rethrow;
    }
  }

  /// Get current user info
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      LoggerService.logApi('GET', '$baseUrl$meEndpoint');
      
      var response = await dio.get(meEndpoint);
      
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        return jsonResponse is Map ? jsonResponse : json.decode(jsonResponse.toString());
      } else {
        throw Exception('Failed to get user info');
      }
    } on DioException catch (e) {
      LoggerService.e('ApiService', 'Get user error', e);
      if (e.response?.statusCode == 401) {
        clearAuth();
        throw Exception('Unauthorized - please login again');
      }
      throw Exception(e.message ?? 'Failed to get user info');
    } catch (e) {
      LoggerService.e('ApiService', 'Get user error', e);
      rethrow;
    }
  }
}
