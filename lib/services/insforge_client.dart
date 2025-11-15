import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class InsforgeClient {
  static final InsforgeClient _instance = InsforgeClient._internal();
  factory InsforgeClient() => _instance;
  InsforgeClient._internal();

  static InsforgeClient get instance => _instance;

  final String _baseUrl = 'https://g3f74j3e.us-east.insforge.app';
  String? _accessToken;

  // Initialize token from storage
  Future<void> _initializeToken() async {
    if (_accessToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
    }
  }

  // Save token to storage
  Future<void> _saveToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Clear token from storage
  Future<void> _clearToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // Get headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  // Handle API responses
  dynamic _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    // Check if response is HTML (error page)
    if (response.body.trim().startsWith('<!DOCTYPE') ||
        response.body.trim().startsWith('<html')) {
      throw Exception(
          'Server returned HTML instead of JSON. Check API endpoint or authentication.');
    }

    // Handle empty responses
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String,
            dynamic>{}; // Return empty map for successful empty responses
      } else {
        throw Exception('API Error (${response.statusCode}): Empty response');
      }
    }

    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        // Handle different error response formats safely
        String errorMessage = 'API request failed';
        try {
          if (data is Map<String, dynamic>) {
            if (data.containsKey('error') && data['error'] is Map) {
              final errorMap = data['error'] as Map<String, dynamic>;
              if (errorMap.containsKey('message')) {
                errorMessage = errorMap['message'].toString();
              }
            } else if (data.containsKey('message')) {
              errorMessage = data['message'].toString();
            }
          }
        } catch (e) {
          print('Error parsing error message: $e');
        }
        throw Exception('API Error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      if (e is FormatException) {
        final bodyPreview = response.body.length > 100
            ? response.body.substring(0, 100)
            : response.body;
        throw Exception('Invalid JSON response from server: $bodyPreview...');
      }
      rethrow;
    }
  }

  // Authentication methods using proper Insforge SDK endpoints
  Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _initializeToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/users'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': email.split('@')[0], // Using email prefix as name
        }),
      );

      final data = _handleResponse(response);

      if (data is Map<String, dynamic> && data['accessToken'] != null) {
        await _saveToken(data['accessToken']);
      }

      return data;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _initializeToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/sessions'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = _handleResponse(response);

      if (data is Map<String, dynamic> && data['accessToken'] != null) {
        await _saveToken(data['accessToken']);
      }

      return data;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _initializeToken();

      // Sign out is handled by clearing the token locally
      // Insforge doesn't have a specific signout endpoint
    } catch (e) {
      print('Sign out error: $e');
    } finally {
      await _clearToken();
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      await _initializeToken();

      if (_accessToken == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/sessions/current'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      final data = _handleResponse(response);

      // Handle different response formats from Insforge API
      if (data is Map<String, dynamic>) {
        if (data.containsKey('user')) {
          // Already in correct format { user: {...} }
          return data;
        } else if (data.containsKey('id') && data.containsKey('email')) {
          // Wrap user data in user object to match expected format
          return {
            'user': data,
          };
        }
      }

      return data;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> setProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
    String? birthday,
  }) async {
    try {
      await _initializeToken();

      if (_accessToken == null) {
        throw Exception('No authenticated user found');
      }

      // Get current user ID first
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Extract user ID from the response
      String userId;
      if (currentUser['user'] != null && currentUser['user']['id'] != null) {
        userId = currentUser['user']['id'];
      } else if (currentUser['id'] != null) {
        userId = currentUser['id'];
      } else {
        throw Exception('User ID not found in response');
      }

      print('Updating profile for user: $userId');

      // For profile updates, we need to use the database records endpoint
      // First, let's check if the user profile exists
      final existingProfiles = await select(
        table: 'profiles',
        filters: {'user_id': userId},
      );

      if (existingProfiles.isEmpty) {
        // Create new profile
        final response = await insert(
          table: 'profiles',
          data: {
            'user_id': userId,
            if (nickname != null) 'nickname': nickname,
            if (bio != null) 'bio': bio,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            if (birthday != null) 'birthday': birthday,
          },
        );
        return response;
      } else {
        // Update existing profile
        final response = await update(
          table: 'profiles',
          data: {
            if (nickname != null) 'nickname': nickname,
            if (bio != null) 'bio': bio,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            if (birthday != null) 'birthday': birthday,
          },
          filters: {'user_id': userId},
        );
        return response;
      }
    } catch (e) {
      print('Set profile error: $e');
      return null;
    }
  }

  // Database operations using proper Insforge SDK endpoints
  Future<List<Map<String, dynamic>>> select({
    required String table,
    Map<String, dynamic>? filters,
    String? orderBy,
    int? limit,
  }) async {
    try {
      await _initializeToken();

      if (_accessToken == null) {
        throw Exception('No authenticated user found');
      }

      final uri = Uri.parse('$_baseUrl/api/database/records/$table');
      final queryParams = <String, String>{};

      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            // Handle different filter types
            if (value is DateTime) {
              queryParams[key] = value.toIso8601String();
            } else if (value is String && value.contains('.')) {
              // Handle PostgREST operators like 'eq.value', 'gt.value'
              queryParams[key] = value;
            } else {
              // Use proper PostgREST syntax for equality
              queryParams['$key'] = 'eq.$value';
            }
          }
        });
      }

      if (orderBy != null) {
        queryParams['order'] = orderBy;
      }

      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await http.get(
        uri.replace(queryParameters: queryParams),
        headers: _getHeaders(),
      );

      final data = _handleResponse(response);

      // Handle different response formats
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data['data'] != null && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Database select error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _initializeToken();

      if (_accessToken == null) {
        throw Exception('No authenticated user found');
      }

      // Convert data to proper format for Insforge API
      final insertData = <String, dynamic>{};
      data.forEach((key, value) {
        if (value is DateTime) {
          insertData[key] = value.toIso8601String();
        } else if (value is String && value.isNotEmpty) {
          insertData[key] = value;
        } else if (value is int || value is double || value is bool) {
          insertData[key] = value;
        } else if (value != null) {
          insertData[key] = value.toString();
        }
      });

      print('Inserting data: $insertData');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/database/records/$table'),
        headers: _getHeaders(),
        body: jsonEncode([insertData]), // PostgREST expects array
      );

      final responseData = _handleResponse(response);

      // Handle different response formats
      if (responseData is List && responseData.isNotEmpty) {
        return responseData.first;
      } else if (responseData is Map<String, dynamic> &&
          responseData['data'] != null &&
          responseData['data'] is List &&
          responseData['data'].isNotEmpty) {
        return responseData['data'].first;
      } else if (responseData is Map<String, dynamic> &&
          responseData.isNotEmpty) {
        return responseData;
      } else {
        // For successful inserts with empty response, return the processed data
        print('Insert successful, returning processed data');
        return insertData;
      }
    } catch (e) {
      print('Database insert error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    Map<String, dynamic>? filters,
  }) async {
    try {
      await _initializeToken();

      if (_accessToken == null) {
        throw Exception('No authenticated user found');
      }

      final uri = Uri.parse('$_baseUrl/api/database/records/$table');
      final queryParams = <String, String>{};

      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            if (value is DateTime) {
              queryParams[key] = value.toIso8601String();
            } else if (value is String && value.contains('.')) {
              queryParams[key] = value;
            } else {
              // Use proper PostgREST syntax for equality
              queryParams['$key'] = 'eq.$value';
            }
          }
        });
      }

      final response = await http.patch(
        uri.replace(queryParameters: queryParams),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      final responseData = _handleResponse(response);

      // Handle different response formats
      if (responseData is List && responseData.isNotEmpty) {
        return responseData.first;
      } else if (responseData is Map<String, dynamic> &&
          responseData['data'] != null &&
          responseData['data'] is List &&
          responseData['data'].isNotEmpty) {
        return responseData['data'].first;
      } else if (responseData is Map<String, dynamic> &&
          responseData.isNotEmpty) {
        return responseData;
      } else {
        return data;
      }
    } catch (e) {
      print('Database update error: $e');
      rethrow;
    }
  }

  Future<void> delete({
    required String table,
    Map<String, dynamic>? filters,
  }) async {
    try {
      await _initializeToken();

      if (_accessToken == null) {
        throw Exception('No authenticated user found');
      }

      final uri = Uri.parse('$_baseUrl/api/database/records/$table');
      final queryParams = <String, String>{};

      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            if (value is DateTime) {
              queryParams[key] = value.toIso8601String();
            } else if (value is String && value.contains('.')) {
              queryParams[key] = value;
            } else {
              // Use proper PostgREST syntax for equality
              queryParams['$key'] = 'eq.$value';
            }
          }
        });
      }

      await http.delete(
        uri.replace(queryParameters: queryParams),
        headers: _getHeaders(),
      );
    } catch (e) {
      print('Database delete error: $e');
      rethrow;
    }
  }

  // Storage operations using proper Insforge SDK endpoints
  Future<Map<String, dynamic>?> uploadFile({
    required String bucket,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      await _initializeToken();

      if (_accessToken == null) {
        throw Exception('No authenticated user found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/storage/buckets/$bucket/objects'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_accessToken';

      // Create multipart file from bytes - works on both web and mobile
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );

      request.files.add(multipartFile);

      print('Uploading file: $fileName to bucket: $bucket');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Return the full response which contains bucket, key, url, etc.
        return data as Map<String, dynamic>;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('File upload error: $e');
      return null;
    }
  }

  Future<String?> getFileUrl({
    required String bucket,
    required String fileName,
  }) async {
    try {
      return '$_baseUrl/api/storage/buckets/$bucket/objects/$fileName';
    } catch (e) {
      print('Get file URL error: $e');
      return null;
    }
  }

  // Edge function invocation
  Future<Map<String, dynamic>> invokeEdgeFunction(
    String functionSlug, {
    Map<String, dynamic>? body,
  }) async {
    try {
      await _initializeToken();

      if (_accessToken == null) {
        throw Exception('No authenticated user found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/functions/$functionSlug'),
        headers: _getHeaders(),
        body: jsonEncode(body ?? {}),
      );

      return _handleResponse(response);
    } catch (e) {
      print('Edge function invocation error: $e');
      rethrow;
    }
  }
}
